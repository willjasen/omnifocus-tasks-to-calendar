-- ┌─────────────────────────────────────────────────────────────────────────────┐
-- │  OVERVIEW                                                                   │
-- ├─────────────────────────────────────────────────────────────────────────────┤
-- │  Syncs macOS Calendar events from OmniFocus tasks due today or later.       │
-- │  Events are matched to tasks via their OmniFocus task ID (stored in the     │
-- │  event URL), and only changed properties are updated. New tasks get new     │
-- │  events, completed/removed tasks have their events deleted, and unchanged   │
-- │  tasks are left alone.                                                      │
-- └─────────────────────────────────────────────────────────────────────────────┘

-- ┌─────────────────────────────────────────────────────────────────────────────┐
-- │  USAGE                                                                      │
-- ├─────────────────────────────────────────────────────────────────────────────┤
-- │  Run from the command line:                                                 │
-- │    osascript omnifocus_tasks_to_calendar.scpt                               │
-- │                                                                             │
-- │  Days to look ahead/back are configured in data.json                        │
-- │  via the daysAhead and daysBack properties.                                 │
-- └─────────────────────────────────────────────────────────────────────────────┘

-- ┌─────────────────────────────────────────────────────────────────────────────┐
-- │  SCRIPT                                                                     │
-- └─────────────────────────────────────────────────────────────────────────────┘

property default_event_duration : 30  --in minutes
property expected_data_version : "v2.0.0"

on run

	log("The OmniFocus Tasks to Calendar script has started.")
	log("Expected data.json version: " & expected_data_version)

	-- Load sync configuration from external JSON file using JavaScript for Automation (JXA)
	set scriptPath to do shell script "dirname " & quoted form of POSIX path of (path to me)
	set jsonPath to scriptPath & "/data.json"
	set jsonExists to do shell script "test -f " & quoted form of jsonPath & " && echo 'true' || echo 'false'"
	if jsonExists is "false" then
		log("data.json not found at " & jsonPath)
		display notification "data.json not found. Please create it from data.example.json." with title "Sync Error"
		return
	end if
	set jsonContent to do shell script "cat " & quoted form of jsonPath

	-- Validate data.json version matches this script's expected version
	set dataVersion to do shell script "echo " & quoted form of jsonContent & " | osascript -l JavaScript -e 'var j=JSON.parse($.NSString.alloc.initWithDataEncoding($.NSFileHandle.fileHandleWithStandardInput.readDataToEndOfFile, $.NSUTF8StringEncoding).js); j.version || \"\"'"
	if dataVersion is not expected_data_version then
		log("data.json version mismatch: expected " & expected_data_version & ", found " & dataVersion)
		display notification "data.json version mismatch: expected " & expected_data_version & ", found " & dataVersion & ". Please update data.json using data.example.json." with title "Sync Error"
		return
	end if

	set syncCount to (do shell script "echo " & quoted form of jsonContent & " | osascript -l JavaScript -e 'JSON.parse($.NSString.alloc.initWithDataEncoding($.NSFileHandle.fileHandleWithStandardInput.readDataToEndOfFile, $.NSUTF8StringEncoding).js).data.length'") as integer

	-- Read daysAhead and daysBack from data.json
	set daysAhead to (do shell script "echo " & quoted form of jsonContent & " | osascript -l JavaScript -e 'JSON.parse($.NSString.alloc.initWithDataEncoding($.NSFileHandle.fileHandleWithStandardInput.readDataToEndOfFile, $.NSUTF8StringEncoding).js).daysAhead || 1'") as integer
	set daysBack to (do shell script "echo " & quoted form of jsonContent & " | osascript -l JavaScript -e 'JSON.parse($.NSString.alloc.initWithDataEncoding($.NSFileHandle.fileHandleWithStandardInput.readDataToEndOfFile, $.NSUTF8StringEncoding).js).daysBack || 1'") as integer

	log("daysAhead: " & daysAhead & ", daysBack: " & daysBack)

	-- for the days to pull tasks from, set the start date to today's date at the prior midnight
	set theStartDate to current date - (days * daysBack)
	set hours of theStartDate to 0
	set minutes of theStartDate to 0
	set seconds of theStartDate to 0

	-- for the days to pull tasks from, set the end date to today's date plus how many days to look forward
	set theEndDate to current date + (days * (daysAhead - 1))
	set hours of theEndDate to 23
	set minutes of theEndDate to 59
	set seconds of theEndDate to 59

	-- Start a stopwatch
	set stopwatchStart to current date

	-- Prevent macOS from automatically terminating Calendar while the script runs.
	-- On Apple Silicon Macs, macOS aggressively kills apps with no visible windows.
	-- This is the root cause of error -600 ("Application isn't running").
	do shell script "defaults write com.apple.iCal NSDisableAutomaticTermination -bool true"
	-- Launch Calendar in background (hidden, no focus steal) and wait for it to be responsive
	ensureCalendarRunning()

	-- Let the user know that the script has started
	display notification "OmniFocus is now syncing to Calendar" with title "Syncing..."

	-- ********************************* --
	-- CALL THE HANDLERS WITH PARAMETERS --
	-- ********************************* --

	-- Loop through each sync configuration in the JSON and call the handler
	repeat with i from 0 to syncCount - 1
		set syncTags to paragraphs of (do shell script "echo " & quoted form of jsonContent & " | osascript -l JavaScript -e 'var d=JSON.parse($.NSString.alloc.initWithDataEncoding($.NSFileHandle.fileHandleWithStandardInput.readDataToEndOfFile, $.NSUTF8StringEncoding).js).data[" & i & "]; d.tags.join(\"\\n\")'")
		set syncMode to do shell script "echo " & quoted form of jsonContent & " | osascript -l JavaScript -e 'JSON.parse($.NSString.alloc.initWithDataEncoding($.NSFileHandle.fileHandleWithStandardInput.readDataToEndOfFile, $.NSUTF8StringEncoding).js).data[" & i & "].mode'"
		set syncCalendar to do shell script "echo " & quoted form of jsonContent & " | osascript -l JavaScript -e 'JSON.parse($.NSString.alloc.initWithDataEncoding($.NSFileHandle.fileHandleWithStandardInput.readDataToEndOfFile, $.NSUTF8StringEncoding).js).data[" & i & "].calendar'"
		processOmniFocusTasks(syncTags, syncMode, syncCalendar)
	end repeat

	-- Stop the stopwatch
	set stopwatchStop to current date
	-- Subtract the two dates
	set runtimeSeconds to (stopwatchStop - stopwatchStart)
	-- Let the user know that the script has finished
	display notification "OmniFocus is finished syncing to Calendar, took " & runtimeSeconds & " seconds" with title "Syncing Complete!"
	log("The script has finished. Runtime: " & runtimeSeconds & " seconds.")

end run

--
-- HANDLER :: SMART SYNC OMNIFOCUS TASKS TO CALENDAR EVENTS --
-- Matches existing events by task URL, updates changed events, creates new ones, removes orphaned ones
--
on processOmniFocusTasks(tags_considered,include_or_exclude,calendar_name)

	log("Processing tags to " & include_or_exclude & ": " & tags_considered)

	global theStartDate, theEndDate

	-- Get existing calendar events for smart sync
	set matched_urls to {}
	ensureCalendarRunning()
	tell application "Calendar"
		set calendar_element to calendar calendar_name
		set existing_events to every event of calendar_element
	end tell

	tell application "OmniFocus"
		tell default document

			set task_elements to flattened tasks whose ¬
				(completed is false) and ¬
				(dropped is false) and ¬
				((due date ≠ missing value) or (planned date ≠ missing value)) and ¬
				((due date is greater than or equal to theStartDate) or (planned date is greater than or equal to theStartDate)) and ¬
				((due date is less than or equal to theEndDate) or (planned date is less than or equal to theEndDate))

			repeat with item_ref in task_elements

				-- GET OMNIFOCUS TASKS
				set the_task to contents of item_ref
				set task_tags to tags of the_task
				set task_should_sync to false

				-- Check if the task should be made into a calendar event
				if include_or_exclude is "include" then
					repeat with aTag in task_tags
						if name of aTag is in tags_considered then
							set task_should_sync to true
							exit repeat
						end if
					end repeat
				else
					repeat with aTag in task_tags
						if name of aTag is in tags_considered then
							set task_should_sync to false
							exit repeat
						else
							set task_should_sync to true
						end if
					end repeat
				end if

				-- If the task should be synced, then sync it to the calendar
				if task_should_sync then

					set task_due to due date of the_task
					set task_planned to planned date of the_task
					set task_name to name of the_task
					set task_note to note of the_task
					-- Check if the task has a project assigned
					try
						set task_project to name of containing project of the_task
						set has_project to true
					on error
						set has_project to false
					end try
					if task_note is missing value or task_note is "" then
						if has_project then
							set full_task_note to "Project: " & task_project
						else
							set full_task_note to ""
						end if
					else
						if has_project then
							set full_task_note to "Project: " & task_project & return & "----------------------------------------" & return & task_note
						else
							set full_task_note to task_note
						end if
					end if
					set task_estimate to estimated minutes of the_task
					set task_url to "omnifocus:///task/" & id of the_task
					set is_flagged to flagged of the_task
					if task_estimate is missing value then
						set task_estimate to default_event_duration
					end if

					-- Determine the event's task_end_date and task_start_date
					if task_due is not missing value then
						set task_end_date to task_due
					else if task_planned is not missing value then
						set task_end_date to task_planned
					else
						-- Skip the task if neither due nor planned date is available
						log("Skipping task '" & task_name & "' as it has no due or planned date.")
						exit repeat
					end if

					set task_start_date to task_end_date - (task_estimate * minutes)
					
					-- Safety check: ensure task_start_date is before task_end_date
					-- (handles edge cases like tasks at 11:50 PM where arithmetic might cause issues)
					if task_start_date is greater than or equal to task_end_date then
						log("WARNING: Date calculation error for task '" & task_name & "' | Estimate: " & task_estimate & "m | Using fallback of 1 minute duration")
						set task_start_date to task_end_date - (1 * minutes)
					end if

					-- SMART SYNC: Find existing calendar event by task URL
					set found_event to missing value
					my ensureCalendarRunning()
					tell application "Calendar"
						repeat with evt in existing_events
							try
								if url of evt is task_url then
									set found_event to contents of evt
									exit repeat
								end if
							end try
						end repeat
					end tell

					set end of matched_urls to task_url

					if found_event is not missing value then
						-- UPDATE existing event only if properties have changed
						my ensureCalendarRunning()
						tell application "Calendar"
							set needs_update to false
							set needs_alarm_recreate to false

							-- Compare core properties (tolerant of iCloud/CalDAV sync artifacts)
							if summary of found_event is not task_name then set needs_update to true
							if not (my normalizeText(description of found_event) is my normalizeText(full_task_note)) then set needs_update to true
							if not my datesEqualToMinute(start date of found_event, task_start_date) then set needs_update to true
							if not my datesEqualToMinute(end date of found_event, task_end_date) then set needs_update to true

							-- Compare alarm state
							set has_alarm to (count of display alarms of found_event) > 0
							if is_flagged and not has_alarm then
								set needs_update to true
							end if
							if (not is_flagged) and has_alarm then
								-- Alarm needs to be removed; Calendar.app cannot reliably delete alarms,
								-- so we delete the event and recreate it without an alarm
								set needs_alarm_recreate to true
							end if

							if needs_alarm_recreate then
								-- Delete and recreate: most reliable way to remove alarms
								log("Recreating event (alarm removal) for task: " & task_name)
								delete found_event
								tell calendar_element
									make new event with properties {summary:task_name, description:full_task_note, start date:task_start_date, end date:task_end_date, url:task_url} at calendar_element
								end tell
							else if needs_update then
								-- Delete and recreate: Calendar.app has no batch/transaction API,
								-- so updating properties one-by-one causes visible intermediate
								-- states (e.g. a briefly huge event span). Recreating the event
								-- ensures the calendar only ever shows the final correct state.
								log("Updating event for task: " & task_name)
								delete found_event
								tell calendar_element
									set newEvent to make new event with properties {summary:task_name, description:full_task_note, start date:task_start_date, end date:task_end_date, url:task_url} at calendar_element
								end tell
								-- Add alarm if flagged
								if is_flagged then
									tell newEvent
										make new display alarm at end with properties {trigger interval:task_estimate}
									end tell
								end if
							end if
						end tell
					else
						-- CREATE new calendar event
						log("Creating event for task: " & task_name)
						my ensureCalendarRunning()
						tell application "Calendar"
							tell calendar_element
								set newEvent to make new event with properties {summary:task_name, description:full_task_note, start date:task_start_date, end date:task_end_date, url:task_url} at calendar_element
							end tell
							if is_flagged then
								tell newEvent
									make new display alarm at end with properties {trigger interval:task_estimate}
								end tell
							end if
						end tell
					end if

				end if

			end repeat

		end tell
	end tell

	-- CLEANUP: Delete orphaned events whose OmniFocus tasks are no longer active
	ensureCalendarRunning()
	tell application "Calendar"
		set events_to_delete to {}
		repeat with evt in existing_events
			try
				set evt_url to url of evt
				if evt_url is not missing value and evt_url starts with "omnifocus:///task/" and evt_url is not in matched_urls then
					set end of events_to_delete to contents of evt
				end if
			end try
		end repeat
		repeat with evt in events_to_delete
			log("Deleting orphaned event: " & summary of evt)
			delete evt
		end repeat
	end tell

end processOmniFocusTasks

--
-- HANDLER :: ENSURE CALENDAR IS RUNNING --
-- On Apple Silicon Macs, macOS aggressively terminates apps with no visible windows.
-- Using 'run' alone is insufficient — the process starts but is killed almost immediately.
-- This handler uses 'open -a' via shell (which fully launches with a window) and polls
-- to verify Calendar is actually running before returning.
--
on ensureCalendarRunning()
	-- First, try a quick Apple Event ping to see if Calendar is truly responsive
	try
		tell application "Calendar" to get name
		return -- Calendar responded, it's alive
	on error
		log("Calendar is not responsive, launching...")
	end try
	-- 'open -a' is the most reliable way to fully launch an app on Apple Silicon
	do shell script "open -a Calendar"
	-- Poll up to 10 seconds for Calendar to become responsive
	set maxAttempts to 10
	repeat maxAttempts times
		try
			tell application "Calendar" to get name
			log("Calendar is now running.")
			-- Minimize the Calendar window to keep it out of the way
			try
				tell application "Calendar" to set miniaturized of every window to true
			end try
			return
		end try
		delay 1
	end repeat
	error "Failed to launch Calendar after " & maxAttempts & " seconds"
end ensureCalendarRunning

--
-- HANDLER :: NORMALIZE TEXT --
-- Normalizes line endings and trims trailing whitespace for reliable cross-machine comparison.
-- iCloud/CalDAV sync may convert \r to \n, add/remove trailing whitespace, etc.
--
on normalizeText(txt)
	if txt is missing value then return ""
	-- Replace \r\n with \n, then remaining \r with \n
	set normalized to do shell script "printf %s " & quoted form of txt & " | tr '\r' '\n' | sed 's/[[:space:]]*$//'"
	return normalized
end normalizeText

--
-- HANDLER :: DATES EQUAL TO MINUTE --
-- Compares two dates ignoring seconds, since CalDAV/iCloud may strip or round seconds.
--
on datesEqualToMinute(d1, d2)
	if d1 is missing value or d2 is missing value then return false
	-- Compare year, month, day, hours, minutes (ignore seconds)
	set d1m to d1 - (time of d1 mod 60)
	set d2m to d2 - (time of d2 mod 60)
	return d1m is equal to d2m
end datesEqualToMinute


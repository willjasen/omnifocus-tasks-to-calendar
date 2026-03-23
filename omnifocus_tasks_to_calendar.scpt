-- ** OVERVIEW ** --
-- This code syncs macOS Calendar events from OmniFocus tasks that are due today or in the future
-- Events are matched to tasks via their OmniFocus task ID (stored in the event URL), and only changed properties are updated
-- New tasks get new events, completed/removed tasks have their events deleted, and unchanged tasks are left alone


-- ** HISTORY ** --
-- -- Rosemary Orchard
-- -- -- Modified from a script by unlocked2412
-- -- -- If an estimated time is not set then the task defaults to 30 minutes in length
-- -- willjasen
-- -- -- changed "set start_date to start_date - (task_estimate * minutes)" to "set start_date to end_date - (task_estimate * minutes)"
-- -- -- changed so that only events from today forward are added to the calendar (decreases runtime)
-- -- -- task notes are added into calendar event notes
-- -- -- shared tags no longer need to be the primary tag in the task (2024-08-19)
-- -- -- refactored script to use handlers (2024-08-19)
-- -- -- make the calendar alert align with task's due date
-- -- -- refactor the script for only one processing tasks handler (2025-02-20)
-- -- -- add back to make the calendar app minimized when the script runs (2025-05-30)
-- -- -- added how to run the script via Usage comments (2025-05-30)
-- -- -- work with the "planned date" attribute (2026-01-26)
-- -- -- filter tasks to exclude dropped tasks (2026-01-26)
-- -- -- smart sync: match events by task ID instead of delete-all/recreate-all (2026-03-19)


-- ** USAGE ** --
-- This script can be run from the command line with two optional parameters:
-- 1. The number of days to look ahead (default is 1)
-- 2. The number of days to look back (default is 1)
-- Example: `osascript omnifocus_tasks_to_calendar.scpt 30 7`


-- ******** --
--  SCRIPT  --
-- ******** --

property default_event_duration : 30  --in minutes

on run argv

	log("The script has started.")

	-- Set daysAhead to 1 if not passed in
	-- Set daysBack to 1 if not passed in
	if (count of argv) > 0 then
		set daysAhead to item 1 of argv as integer
		set daysBack to item 2 of argv as integer
	else
		set daysAhead to 1
		set daysBack to 1
	end if

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

	-- Restart the Calendar app minimized
	tell application "Calendar" to quit
	delay 3
	tell application "Calendar"
		run  -- this starts the Calendar app but doesn't load its window
	end tell

	-- Let the user know that the script has started
	display notification "OmniFocus is now syncing to Calendar" with title "Syncing..."

	-- ********************************* --
	-- CALL THE HANDLERS WITH PARAMETERS --
	-- ********************************* --

	-- Sync all of the calendars
	set tagsToSync to {"👦🏻 Tyler"}
	processOmniFocusTasks(tagsToSync,"include","OmniFocus - 👦🏻 Tyler")

	set tagsToSync to {"👩🏻 Mom","👦🏼 Isaac","🧑🏻‍🦰 Carter"}
	processOmniFocusTasks(tagsToSync,"include","OmniFocus - 👩🏻 Mom")

	set tagsToSync to {"👨🏼 Nathaniel","👦🏼 Isaac","🧑🏻‍🦰 Carter"}
	processOmniFocusTasks(tagsToSync,"include","OmniFocus - 👨🏼 Nathaniel")

	set tagsToIgnore to {"👦🏻 Tyler","👩🏻 Mom","👨🏼 Nathaniel","👦🏼 Isaac","🧑🏻‍🦰 Carter"}
	processOmniFocusTasks(tagsToIgnore,"exclude","OmniFocus")

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

					-- Determine the event's end_date and start_date
					if task_due is not missing value then
						set end_date to task_due
					else if task_planned is not missing value then
						set end_date to task_planned
					else
						-- Skip the task if neither due nor planned date is available
						log("Skipping task '" & task_name & "' as it has no due or planned date.")
						exit repeat
					end if

					set start_date to end_date - (task_estimate * minutes)

					-- SMART SYNC: Find existing calendar event by task URL
					set found_event to missing value
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
						tell application "Calendar"
							set needs_update to false

							-- Compare core properties
							if summary of found_event is not task_name then set needs_update to true
							set evt_desc to description of found_event
							if evt_desc is missing value then set evt_desc to ""
							if evt_desc is not full_task_note then set needs_update to true
							if start date of found_event is not start_date then set needs_update to true
							if end date of found_event is not end_date then set needs_update to true

							-- Compare alarm state
							set has_alarm to (count of display alarms of found_event) > 0
							if is_flagged and not has_alarm then set needs_update to true
							if (not is_flagged) and has_alarm then set needs_update to true

							if needs_update then
								log("Updating event for task: " & task_name)
								set summary of found_event to task_name
								set description of found_event to full_task_note
								set start date of found_event to start_date
								set end date of found_event to end_date

								-- Reset alarms
								delete (every display alarm of found_event)
								if is_flagged then
									tell found_event
										make new display alarm at end with properties {trigger interval:task_estimate}
									end tell
								end if
							end if
						end tell
					else
						-- CREATE new calendar event
						log("Creating event for task: " & task_name)
						tell application "Calendar"
							tell calendar_element
								set newEvent to make new event with properties {summary:task_name, description:full_task_note, start date:start_date, end date:end_date, url:task_url} at calendar_element
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


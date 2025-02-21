-- ** OVERVIEW ** --
-- This code creates macOS Calendar events from OmniFocus tasks that are due today or in the future
-- In regards to runtime, all events on the specified calendars are deleted en masse and then recreated


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


-- ******** --
--  SCRIPT  --
-- ******** --

property default_event_duration : 30  --in minutes

on run argv

	-- Set numOfDaysToInclude to 1 if not passed in
	if (count of argv) > 0 then
		set numOfDaysToInclude to item 1 of argv as integer
	else
		set numOfDaysToInclude to 1
	end if

	-- Create global variables
	set calendar_element to missing value  --initialize to null

	-- Start a stopwatch
	set stopwatchStart to current date

	-- Let the user know that the script has started
	display notification "OmniFocus is now syncing to Calendar" with title "Syncing..."

	-- Check if the current time is 4 am
	set currentHour to hours of (current date)
	if currentHour is not 4 then
		-- do nothing --
	else
		-- Restart the Calendar app minimized
		tell application "Calendar" to quit
		delay 1
		tell application "Calendar"
			activate
			set miniaturized of every window to true
		end tell
	end if

	-- for the days to pull tasks from, set the start date to today's date at the prior midnight
	set theStartDate to current date
	set hours of theStartDate to 0
	set minutes of theStartDate to 0
	set seconds of theStartDate to 0

	-- for the days to pull tasks from, set the end date to today's date plus how many days to look forward
	set theEndDate to current date + (days * (numOfDaysToInclude - 1))
	set hours of theEndDate to 23
	set minutes of theEndDate to 59
	set seconds of theEndDate to 59

	-- ********************************* --
	-- CALL THE HANDLERS WITH PARAMETERS --
	-- ********************************* --


	-- Delete all events from the affected calendars
	deleteCalendarEvents("OmniFocus")
	deleteCalendarEvents("OmniFocus - 👦🏻 Tyler")
	deleteCalendarEvents("OmniFocus - 👩🏻 Mom")
	deleteCalendarEvents("OmniFocus - 👨🏼 Nathaniel")


	-- Sync all of the calendars
	set tagsToSync to {"👦🏻 Tyler"}
	processOmniFocusSharedTasks(tagsToSync,"OmniFocus - 👦🏻 Tyler")

	set tagsToSync to {"👩🏻 Mom","👦🏼 Isaac","🧑🏻‍🦰 Carter"}
	processOmniFocusSharedTasks(tagsToSync,"OmniFocus - 👩🏻 Mom")

	set tagsToSync to {"👨🏼 Nathaniel","👦🏼 Isaac","🧑🏻‍🦰 Carter"}
	processOmniFocusSharedTasks(tagsToSync,"OmniFocus - 👨🏼 Nathaniel")

	set tagsToIgnore to {"👦🏻 Tyler","👩🏻 Mom","👨🏼 Nathaniel","👦🏼 Isaac","🧑🏻‍🦰 Carter"}
	processOmniFocusMyTasks(tagsToIgnore,"OmniFocus")


	-- Stop the stopwatch
	set stopwatchStop to current date
	-- Subtract the two dates
	set runtimeSeconds to (stopwatchStop - stopwatchStart)
	-- Let the user know that the script has finished
	display notification "OmniFocus is finished syncing to Calendar, took " & runtimeSeconds & " seconds" with title "Syncing Complete!"

end run

--
-- HANDLER :: CREATE A CALENDAR EVENT FROM A TASK --
-- ** IN PROGRESS **
--
createCalendarEvent()

end createCalendarEvent

--
-- HANDLER :: DELETE ALL CALENDAR EVENTS ON A GIVEN CALENDAR --
--
on deleteCalendarEvents(calendar_name)

	global calendar_element
  
	tell application "Calendar"

		set calendar_element to calendar calendar_name
		delete (every event of calendar_element)

	end tell

end deleteCalendarEvents

--
-- HANDLER :: PROCESS OMNIFOCUS SHARED TASKS --
--
on processOmniFocusSharedTasks(tags_to_sync,calendar_name)

	log("Processing tags: " & tags_to_sync)

	global theStartDate, theEndDate, calendar_element
	
	tell application "OmniFocus"
		tell default document

			set task_elements to flattened tasks whose ¬
				(completed is false) and ¬
				(due date ≠ missing value) and ¬
				(due date is greater than or equal to theStartDate) and ¬
				(due date is less than or equal to theEndDate)

			repeat with item_ref in task_elements

				-- GET OMNIFOCUS TASKS
				set the_task to contents of item_ref
				set task_tags to tags of the_task
				set tagExists to false

				-- Check if the tag exists in the task's tags
				repeat with aTag in task_tags
					if name of aTag is in tags_to_sync then
						set tagExists to true
						exit repeat
					end if
				end repeat

				-- If the tag is found, then continue
				if tagExists then

					set task_due to due date of the_task
					set task_name to name of the_task
					set task_note to note of the_task
					set task_project to name of containing project of the_task
					if task_note is missing value or task_note is "" then
						set full_task_note to "Project: " & task_project
					else
						set full_task_note to "Project: " & task_project & return & task_note
					end if
					set task_estimate to estimated minutes of the_task
					set task_url to "omnifocus:///task/" & id of the_task
					set is_flagged to flagged of the_task
					if task_estimate is missing value then
						set task_estimate to default_event_duration
					end if

					-- BUILD CALENDAR DATE
					set end_date to task_due
					set start_date to end_date - (task_estimate * minutes)

					-- CREATE CALENDAR EVENT
					tell application "Calendar"
						set calendar_element to calendar calendar_name
						tell calendar_element							
							set newEvent to make new event with properties {summary:task_name, description:full_task_note, start date:start_date, end date:end_date, url:task_url} at calendar_element
						end tell
						if is_flagged then
							tell newEvent
								-- Set the alert to trigger at the due date (end_date)
								make new display alarm at end with properties {trigger interval:task_estimate}
							end tell
						end if
					end tell

				end if				

			end repeat

		end tell
	end tell

end processOmniFocusSharedTasks

--
-- HANDLER :: PROCESS OMNIFOCUS MY TASKS --
--
on processOmniFocusMyTasks(tags_to_ignore,calendar_name)

	log("Processing: My Tasks")

	global theStartDate, theEndDate, calendar_element
	
	tell application "OmniFocus"
		tell default document

			set task_elements to flattened tasks whose ¬
				(completed is false) and ¬
				(due date ≠ missing value) and ¬
				(due date is greater than or equal to theStartDate) and ¬
				(due date is less than or equal to theEndDate)

			repeat with item_ref in task_elements

				-- GET OMNIFOCUS TASKS
				set the_task to contents of item_ref
				set task_tags to tags of the_task

				set excludeTask to false

				-- If there in an excluded tag, skip the task
				if excludeTask is false then
					-- Check if the task has any of the excluded tags
					repeat with aTag in task_tags
						set tagName to name of aTag
						if tagName is in tags_to_ignore then
							set excludeTask to true
							exit repeat
						end if
					end repeat
				end if

				-- If the tag is found, then continue
				if excludeTask is false then

					set task_due to due date of the_task
					set task_name to name of the_task
					set task_note to note of the_task
					set task_project to name of containing project of the_task
					if task_note is missing value or task_note is "" then
						set full_task_note to "Project: " & task_project
					else
						set full_task_note to "Project: " & task_project & return & task_note
					end if
					set task_estimate to estimated minutes of the_task
					set task_url to "omnifocus:///task/" & id of the_task
					set is_flagged to flagged of the_task
					if task_estimate is missing value then
						set task_estimate to default_event_duration
					end if

					-- BUILD CALENDAR DATE
					set end_date to task_due
					set start_date to end_date - (task_estimate * minutes)

					-- CREATE CALENDAR EVENT
					tell application "Calendar"
						set calendar_element to calendar calendar_name
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

			end repeat

		end tell
	end tell

end processOmniFocusMyTasks

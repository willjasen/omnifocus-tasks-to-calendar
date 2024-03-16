-- ** OVERVIEW ** --
-- This code creates macOS Calendar events from OmniFocus tasks that are due today or in the future
-- In regards to runtime, all events on the specified calendar are deleted and then recreated


-- ** HISTORY ** --
-- -- Rosemary Orchard
-- -- -- Modified from a script by unlocked2412
-- -- -- If an estimated time is not set then the task defaults to 30 minutes in length
-- -- willjasen
-- -- -- changed "set start_date to start_date - (task_estimate * minutes)" to "set start_date to end_date - (task_estimate * minutes)"
-- -- -- changed so that only events from today forward are added to the calendar (decreases runtime)


--  SCRIPT  --
-- ******** --

property calendar_name : "OmniFocus" -- This is the name of your calendar
property default_duration : 30 --minutes

tell application "Calendar"
	set calendar_element to calendar calendar_name
	tell calendar calendar_name
		set theEvents to every event
		repeat with current_event in theEvents
			delete current_event
		end repeat

		set theStartDate to current date
		set hours of theStartDate to 0
		set minutes of theStartDate to 0
		set seconds of theStartDate to 0

		-- set numOfDaysToInclude to 4
		-- set theEndDate to current date + numOfDaysToInclude
		-- set hours of theEndDate to 0
		-- set minutes of theEndDate to 0
		-- set seconds of theEndDate to 0

	end tell
end tell

tell application "OmniFocus"
	tell default document
		set task_elements to flattened tasks whose ¬
			(completed is false) and (due date ≠ missing value)
		repeat with item_ref in task_elements
			-- GET OMNIFOCUS TASKS
			set the_task to contents of item_ref
			set task_due to due date of the_task

			-- IF THE TASK IS DUE TODAY AND IS WITHIN THE INCLUDED RANGE, THEN PROCESS IT; SKIP THE PAST
			if task_due is greater than or equal to theStartDate then

				set task_name to name of the_task
				set task_note to note of the_task
				set task_estimate to estimated minutes of the_task
				set task_url to "omnifocus:///task/" & id of the_task
				if task_estimate is missing value then
					set task_estimate to default_duration
				end if
				-- BUILD CALENDAR DATE
				set end_date to task_due
				set start_date to end_date - (task_estimate * minutes)
				-- CREATE CALENDAR EVENT
				tell application "Calendar"
					tell calendar_element
						if not (exists (first event whose (start date = start_date) and (summary = task_name))) then
							make new event with properties ¬
								{summary:task_name, start date:start_date, end date:end_date, url:task_url} at calendar_element
						end if
					end tell
				end tell
			end if
		end repeat
	end tell
end tell

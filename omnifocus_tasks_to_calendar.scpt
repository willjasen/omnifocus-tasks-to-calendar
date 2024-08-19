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
-- -- -- task notes are added into calendar event notes
-- -- -- calendar events are only recreated if needed


--  SCRIPT  --
-- ******** --

set numOfDaysToInclude to 3 --includes today
--set tags to {"👦🏻 Tyler","👩🏻 Mom","👨🏼 Nathaniel"}
-- set calendar_elements to {"OmniFocus", "OmniFocus - 👦🏻 Tyler", "OmniFocus - 👩🏻 Mom", "OmniFocus - 👨🏼 Nathaniel"} as calendar

--property calendar_name : "OmniFocus"
--property calendar_name_2 : "OmniFocus - 👦🏻 Tyler"
--property calendar_name_3 : "OmniFocus - 👩🏻 Mom"
--property calendar_name_4 : "OmniFocus - 👨🏼 Nathaniel"
property default_duration : 30 --in minutes

set theStartDate to current date
set hours of theStartDate to 0
set minutes of theStartDate to 0
set seconds of theStartDate to 0

set theEndDate to current date + (days * (numOfDaysToInclude - 1))
set hours of theEndDate to 23
set minutes of theEndDate to 59
set seconds of theEndDate to 59

set calendar_element to missing value


-- DELETE CALENDAR EVENTS ON A GIVEN CALENDAR --
on deleteCalendarEvents(calendar_name)

	global calendar_element

	tell application "Calendar"

		set calendar_element to calendar calendar_name
		delete (every event of calendar_element)

	end tell

end deleteCalendarEvents


-- PROCESS OMNIFOCUS TASKS --
on processOmniFocusTasks(sharedTag,calendar_name)

	log("Processing: " & sharedTag)

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
				set task_due to due date of the_task

				set tagExists to false

				-- Check if the tag exists in the task's tags
				repeat with aTag in task_tags
					if name of aTag is sharedTag then
						set tagExists to true
						exit repeat
					end if
				end repeat

				-- If the tag is found, then continue
				if tagExists then

					set task_name to name of the_task
					set task_note to note of the_task
					set task_estimate to estimated minutes of the_task
					set task_url to "omnifocus:///task/" & id of the_task
					set task_tag to primary tag of the_task
					set task_tag_name to name of task_tag
					if task_estimate is missing value then
						set task_estimate to default_duration
					end if

					-- BUILD CALENDAR DATE
					set end_date to task_due
					set start_date to end_date - (task_estimate * minutes)

					-- CREATE CALENDAR EVENT
					tell application "Calendar"
						set calendar_element to calendar calendar_name
						tell calendar_element
							if not (exists (first event whose (url = task_url))) then
								make new event with properties {summary:task_name, description:task_note, start date:start_date, end date:end_date, url:task_url} at calendar_element
							else if (exists (first event whose (url = task_url) and ((summary is not equal to task_name) or (start date is not equal to start_date))))
								delete (events whose (url is task_url))
								make new event with properties {summary:task_name, description:task_note, start date:start_date, end date:end_date, url:task_url} at calendar_element
							end if
						end tell
					end tell

				end if				

			end repeat

		end tell
	end tell

end processOmniFocusTasks


-- CALL THE HANDLERS WITH PARAMETERS --
deleteCalendarEvents("OmniFocus - 👦🏻 Tyler")
deleteCalendarEvents("OmniFocus - 👩🏻 Mom")
deleteCalendarEvents("OmniFocus - 👨🏼 Nathaniel")
processOmniFocusTasks("👦🏻 Tyler","OmniFocus - 👦🏻 Tyler")
processOmniFocusTasks("👩🏻 Mom","OmniFocus - 👩🏻 Mom")
processOmniFocusTasks("👨🏼 Nathaniel","OmniFocus - 👨🏼 Nathaniel")
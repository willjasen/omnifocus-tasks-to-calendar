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

display notification "OmniFocus is now syncing to Calendar" with title "Syncing..."

set numOfDaysToInclude to 7 --includes today
set tags to {"👦🏻 Tyler","👩🏻 Mom","👨🏼 Nathaniel"}
-- set calendar_elements to {"OmniFocus", "OmniFocus - 👦🏻 Tyler", "OmniFocus - 👩🏻 Mom", "OmniFocus - 👨🏼 Nathaniel"} as calendar

property calendar_name : "OmniFocus"
property calendar_name_2 : "OmniFocus - 👦🏻 Tyler"
property calendar_name_3 : "OmniFocus - 👩🏻 Mom"
property calendar_name_4 : "OmniFocus - 👨🏼 Nathaniel"
property default_duration : 30 --in minutes

set theStartDate to current date
set hours of theStartDate to 0
set minutes of theStartDate to 0
set seconds of theStartDate to 0

set theEndDate to current date + (days * (numOfDaysToInclude - 1))
set hours of theEndDate to 23
set minutes of theEndDate to 59
set seconds of theEndDate to 59

-- SET CALENDAR ELEMENTS
tell application "Calendar"

	--repeat with calendar_elemental in calendar_elements
	--	set calendar_elemental to calendar calendar
	--end repeat

  set calendar_element to calendar calendar_name
	set calendar_element_2 to calendar calendar_name_2
	set calendar_element_3 to calendar calendar_name_3
	set calendar_element_4 to calendar calendar_name_4

  -- THIS ISN'T NEEDED AT THE MOMENT (YES IT IS)
	tell calendar calendar_name
		set theEvents to every event
		repeat with current_event in theEvents
			delete current_event
		end repeat
	end tell

	tell calendar calendar_name_2
		set theEvents to every event
		repeat with current_event in theEvents
			delete current_event
		end repeat
	end tell

	tell calendar calendar_name_3
		set theEvents to every event
		repeat with current_event in theEvents
			delete current_event
		end repeat
	end tell

	tell calendar calendar_name_4
		set theEvents to every event
		repeat with current_event in theEvents
			delete current_event
		end repeat
	end tell

end tell


on processOmniFocusTasks(tasks)
	repeat with item_ref in tasks

		--set the_task to contents of item_ref
		--set task_due to due date of the_task
		--display dialog task_due
	--	set task_name to name of the_task
	--	set task_note to note of the_task
	--	set task_estimate to estimated minutes of the_task
	--	set task_url to "omnifocus:///task/" & id of the_task
	--	set task_tag to primary tag of the_task
	--	set task_tag_name to name of task_tag
	--	if task_estimate is missing value then
	--		set task_estimate to default_duration
	--	end if
	--	set end_date to task_due
	--	set start_date to end_date - (task_estimate * minutes)

		-- CREATE CALENDAR EVENT
	--	tell application "Calendar"
	--		tell calendar_element_2
	--			if not (exists (first event whose (url = task_url))) then
	--				make new event with properties {summary:task_name, description:task_note, start date:start_date, end date:end_date, url:task_url} at calendar_element_2
	--			else if (exists (first event whose (url = task_url) and ((summary is not equal to task_name) or (start date is not equal to start_date))))
	--				delete (events whose (url is task_url))
	--				make new event with properties {summary:task_name, description:task_note, start date:start_date, end date:end_date, url:task_url} at calendar_element_2
	--			end if
	--		end tell
	--	end tell

	end repeat
end processOmniFocusTasks


-- PROCESS OMNIFOCUS --
tell application "OmniFocus"
	tell default document

		set task_elements to flattened tasks whose ¬
			(completed is false) and (due date ≠ missing value) and (due date is greater than or equal to theStartDate) and (due date is less than or equal to theEndDate) and (name of primary tag contains "👦🏻 Tyler")
		-- processOmniFocusTasks(task_elements)

		repeat with item_ref in task_elements

			set the_task to contents of item_ref
			set task_due to due date of the_task
			set task_name to name of the_task
			set task_note to note of the_task
			set task_estimate to estimated minutes of the_task
			set task_url to "omnifocus:///task/" & id of the_task
			set task_tag to primary tag of the_task
			set task_tag_name to name of task_tag
			set newNotes to "These are my event notes."
			if task_estimate is missing value then
				set task_estimate to default_duration
			end if

			-- BUILD CALENDAR DATE
			set end_date to task_due
			set start_date to end_date - (task_estimate * minutes)
			-- CREATE CALENDAR EVENT
			tell application "Calendar"
				tell calendar_element_2
					if not (exists (first event whose (url = task_url))) then
						make new event with properties {summary:task_name, description:task_note, start date:start_date, end date:end_date, url:task_url} at calendar_element_2
					else if (exists (first event whose (url = task_url) and ((summary is not equal to task_name) or (start date is not equal to start_date))))
						delete (events whose (url is task_url))
						make new event with properties {summary:task_name, description:task_note, start date:start_date, end date:end_date, url:task_url} at calendar_element_2
					end if
				end tell
			end tell

		end repeat


		set task_elements to flattened tasks whose ¬
			(completed is false) and (due date ≠ missing value) and (due date is greater than or equal to theStartDate) and (due date is less than or equal to theEndDate) and ((name of primary tag contains "👩🏻 Mom") or (name of primary tag contains "👦🏼 Isaac"))
		repeat with item_ref in task_elements

				-- GET OMNIFOCUS TASKS
				set the_task to contents of item_ref
				set task_due to due date of the_task

				-- IF THE TASK IS DUE TODAY AND IS WITHIN THE INCLUDED RANGE, THEN PROCESS IT; SKIP THE PAST
				if task_due is greater than or equal to theStartDate then
					if task_due is less than or equal to theEndDate then

					set task_name to name of the_task
					set task_note to note of the_task
					set task_estimate to estimated minutes of the_task
					set task_url to "omnifocus:///task/" & id of the_task
					set task_tag to primary tag of the_task
					set task_tag_name to name of task_tag
					set newNotes to "These are my event notes."
					if task_estimate is missing value then
						set task_estimate to default_duration
					end if

					-- BUILD CALENDAR DATE
					-- copy "Creating event: " & task_name to stdout
					set end_date to task_due
					set start_date to end_date - (task_estimate * minutes)
					-- CREATE CALENDAR EVENT
					tell application "Calendar"
							tell calendar_element_3
								if not (exists (first event whose (url = task_url))) then
									make new event with properties {summary:task_name, description:task_note, start date:start_date, end date:end_date, url:task_url} at calendar_element_3
								else if (exists (first event whose (url = task_url) and ((summary is not equal to task_name) or (start date is not equal to start_date))))
									delete (events whose (url is task_url))
									make new event with properties {summary:task_name, description:task_note, start date:start_date, end date:end_date, url:task_url} at calendar_element_3
								end if
							end tell
						end tell
					end if
				end if
		end repeat

		set task_elements to flattened tasks whose ¬
			(completed is false) and (due date ≠ missing value) and ((name of primary tag contains "👨🏼 Nathaniel") or (name of primary tag contains "👦🏼 Isaac"))
		repeat with item_ref in task_elements

				-- GET OMNIFOCUS TASKS
				set the_task to contents of item_ref
				set task_due to due date of the_task

				-- IF THE TASK IS DUE TODAY AND IS WITHIN THE INCLUDED RANGE, THEN PROCESS IT; SKIP THE PAST
				if task_due is greater than or equal to theStartDate then
					if task_due is less than or equal to theEndDate then

					set task_name to name of the_task
					set task_note to note of the_task
					set task_estimate to estimated minutes of the_task
					set task_url to "omnifocus:///task/" & id of the_task
					set task_tag to primary tag of the_task
					set task_tag_name to name of task_tag
					set newNotes to "These are my event notes."
					if task_estimate is missing value then
						set task_estimate to default_duration
					end if

					-- BUILD CALENDAR DATE
					-- copy "Creating event: " & task_name to stdout
					set end_date to task_due
					set start_date to end_date - (task_estimate * minutes)
					-- CREATE CALENDAR EVENT
					tell application "Calendar"
							tell calendar_element_4
								if not (exists (first event whose (url = task_url))) then
									make new event with properties {summary:task_name, description:task_note, start date:start_date, end date:end_date, url:task_url} at calendar_element_4
								else if (exists (first event whose (url = task_url) and ((summary is not equal to task_name) or (start date is not equal to start_date))))
									delete (events whose (url is task_url))
									make new event with properties {summary:task_name, description:task_note, start date:start_date, end date:end_date, url:task_url} at calendar_element_4
								end if
							end tell
						end tell
					end if
				end if
		end repeat

		set task_elements to flattened tasks whose ¬
			(completed is false) and (due date ≠ missing value) and ((not name of primary tag contains "👦🏻 Tyler") and (not name of primary tag contains "👩🏻 Mom") and (not name of primary tag contains "👨🏼 Nathaniel") and (not name of primary tag contains "👦🏼 Isaac"))
		repeat with item_ref in task_elements

			-- GET OMNIFOCUS TASKS
			set the_task to contents of item_ref
			set task_due to due date of the_task

			-- IF THE TASK IS DUE TODAY AND IS WITHIN THE INCLUDED RANGE, THEN PROCESS IT; SKIP THE PAST
			if task_due is greater than or equal to theStartDate then
				if task_due is less than or equal to theEndDate then

				set task_name to name of the_task
				set task_note to note of the_task
				set task_estimate to estimated minutes of the_task
				set task_url to "omnifocus:///task/" & id of the_task
				set task_tag to primary tag of the_task
				set task_tag_name to name of task_tag
				set newNotes to "These are my event notes."
				if task_estimate is missing value then
					set task_estimate to default_duration
				end if

				-- BUILD CALENDAR DATE
				-- copy "Creating event: " & task_name to stdout
				set end_date to task_due
				set start_date to end_date - (task_estimate * minutes)
				-- CREATE CALENDAR EVENT
				tell application "Calendar"
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
			end if
		end repeat

	end tell
end tell

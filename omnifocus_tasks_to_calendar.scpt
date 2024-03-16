property calendar_name : "OmniFocus" -- This is the name of your calendar
property default_duration : 30 --minutes

-- Rosemary Orchard
-- Modified from a script by unlocked2412
-- This creates calendar events for tasks which have a due date, if an estimated time is not set then the task defaults to 30 minutes in length

-- willjasen
-- changed "set start_date to start_date - (task_estimate * minutes)" to "set start_date to end_date - (task_estimate * minutes)"
-- changed so that only events from today forward are added to the calendar (decreases runtime)

tell application "Calendar"
	set calendar_element to calendar calendar_name
	tell calendar calendar_name
		-- set theEvents to every event
		-- repeat with current_event in theEvents
		--	delete current_event
		-- end repeat

		set theStartDate to current date
		set hours of theStartDate to 0
		set minutes of theStartDate to 0
		set seconds of theStartDate to 0

		-- set theEvents to every event where its start date is greater than or equal to theStartDate

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
			if task_due is greater than or equal to theStartDate then

				set task_name to name of the_task
				set task_note to note of the_task
				set task_estimate to estimated minutes of the_task
				set task_url to "omnifocus:///task/" & id of the_task
				if task_estimate is missing value then
					set task_estimate to default_duration
				end if

				-- BUILD CALENDAR DATES
				set end_date to task_due
				set start_date to end_date - (task_estimate * minutes)

				-- CREATE CALENDAR EVENT
				tell application "Calendar"
					-- tell calendar calendar_name
					tell calendar_element
						set theEvents to every event

						set found to false
						-- THIS LOOPS
						repeat with current_event in theEvents

							-- IF THE EVENT EXISTS ALREADY, RECREATE IT
							if (exists (current_event whose (url = task_url))) then
								set found to true
								exit repeat

								-- if not (exists (first event whose (start date = start_date) and (summary = task_name))) then
								-- make new event with properties ¬
								--	{summary:task_name, start date:start_date, end date:end_date, url:task_url} at calendar_element

								-- ELSE, DELETE THE EXISTING EVENT AND MAKE A NEW ONE
								-- else
								-- delete current_event
								-- make new event with properties ¬
								--	{summary:task_name, start date:start_date, end date:end_date, url:task_url} at calendar_element
							end if
						end repeat

						if found is true then
							delete current_event
						end if

						make new event with properties ¬
							{summary:task_name, start date:start_date, end date:end_date, url:task_url} at calendar_element

					end tell
					-- end tell
				end tell
			end if
		end repeat
	end tell
end tell

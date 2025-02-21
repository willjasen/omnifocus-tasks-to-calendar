# omnifocus-tasks-to-calendar
Create events in macOS calendar from OmniFocus tasks

---

### Key Points

- Create macOS Calendar events from OmniFocus tasks that are due today/soon
- Multiple calendars can be used and tasks added to a particular calendar depends on a task's tag
- Events that are tagged/shared aren't duplicated onto my own OmniFocus calendar via include/exclude parameter
- Flagged tasks will have its calendar event have an alert occur on the task's due date
- A notification is displayed when the script starts and when the script ends, including info about runtime
- Using the .plist, a launchd user agent can be created to run the script in the background every so often

---

### Overview

For the sake of making things more complicated than it has to be, the calendars that are synced to are deleted each time the script runs, thus requiring an individual calendar(s) specifically for it. DO NOT USE A PRIMARY CALENDAR! It was a lot easier to tell a calendar to delete all of its events than compare existing events and update them when needed. In accordance with the runtime of the script, my Mac mini M4 does a week's worth of tasks to calendar events in about 30 seconds, while my 2019 Intel MacBook Pro can take 3 to 4 times longer (but I don't sync from it anymore).

Task details that are synced to the calendar:

 - the task's name is made the calendar event's title
 - the note of the calendar event will include at the top "Project:" and the task's project name (if there is one) and then task's note below that
 - the task's duration is applied to the event, so a task with a due date of 4pm with its duration of 2 hours would make a calendar event from 2pm to 4pm, and if the task doesn't have a duration, the calendar event is made for 30 minutes
 - for calendar alerts, any task that would be added to the calendar and is also flagged will have a calendar alert at the time of the task's due date/time
 - the URL of the calendar event includes the OmniFocus task's URL so that you can click into the task from the calendar

The only thing I'm positive it can't do is to take a task's attachments and attach them to the calendar event's attachment section, as AppleScript doesn't provide a way to do that. In the event that an attachment is in a note (like for a picture, where it's included inline), it is ignored.

Tasks get synced based on the tags it has, which can either be included or excluded. The distinction that I generally use is that tasks as related to family that should sync to their shared calendar use the "include" parameter so that only tasks with their tag(s) are synced, whereas with my own calendar, I use the "exclude" parameter along with all of their tags so that any task related to them does not get duplicated onto my own calendar.

---

### Logic

The handler structure for processOmniFocusTasks is:

- 1st parameter: tags to either include or exclude
- 2nd parameter: the word "include" or "exclude"
- 3rd parameter: the name of the calendar that tasks matching the first two parameters should be added to

An example call to this handler for myself looks like:

```
set tagsToIgnore to {"Mom","Brother","Nephew"}
processOmniFocusTasks(tagsToIgnore,"exclude","OmniFocus")
````

An example call to this handler for a family member looks like:

```
set tagsToSync to {"Mom","Nephew"}
processOmniFocusTasks(tagsToSync,"include","OmniFocus - Mom")
````

---

### Screenshots

Calendar week view\
![Calendar week view](/assets/img/calendar-week-view.png)

Calendar event\
![Calendar event](/assets/img/calendar-event.png)

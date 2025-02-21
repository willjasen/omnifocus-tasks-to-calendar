# omnifocus-tasks-to-calendar
Create events in macOS calendar from OmniFocus tasks

- This code creates macOS Calendar events from OmniFocus tasks that are due today/soon
- The number of days ahead to show in Calendar can be passed in as an argument
- Four different calendars are used and tasks added to a particular calendar depends on the tag
- Events that are tagged/shared aren't duplicated onto my own OmniFocus calendar via include/exclude parameter
- Flagged tasks will have its own calendar event have a calendar alert (for the task's due date)
- Handlers are used so that the script is more succinct
- A notification is displayed when the script starts and when the script ends, including info about runtime

Using the .plist, a launchd user agent can be created to run the script in the background every so often

---

### Screenshots

Calendar week view\
![Calendar week view](/assets/img/calendar-week-view.png)

Calendar event\
![Calendar event](/assets/img/calendar-event.png)

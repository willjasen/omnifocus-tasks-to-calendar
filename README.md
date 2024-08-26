# omnifocus-tasks-to-calendar
create events in macOS calendar from OmniFocus tasks

- This code creates macOS Calendar events from OmniFocus tasks that are due today/soon
- Four different calendars are used and tasks added to a particular calendar depends on the tag
- Events that are tagged/shared aren't duplicated on my own OmniFocus calendar
- Flagged tasks will have its own calendar event have a calendar alert
- Handlers are used so that the script is more succinct

using the .plist, a launchd user agent can be created to run the script in the background every so often

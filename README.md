# omnifocus-tasks-to-calendar
create events in macOS calendar from OmniFocus tasks

- This code creates macOS Calendar events from OmniFocus tasks that are due today/soon
- Four different calendars are used and tasks added as an event depends on primary tag name
- Events are only recreated when their url, summary, or start date changes
- Events that are tagged/shared aren't duplicated on the first calendar

using the .plist, a launchd user agent can be created to run the script in the background every so often

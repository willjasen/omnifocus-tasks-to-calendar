# omnifocus-tasks-to-calendar
create events in macOS calendar from OmniFocus tasks

- This code creates macOS Calendar events from OmniFocus tasks that are due today
- In regards to runtime, all events on the specified calendar are deleted and then recreated
- Four different calendars are used and tasks added as an event depends on primary tag name

using the .plist, a launchd user agent can be created to run the script in the background every so often

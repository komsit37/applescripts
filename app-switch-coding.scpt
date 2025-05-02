#!/usr/bin/osascript

-- List of apps to cycle through
set appList to {"Cursor", "IntelliJ IDEA"}

-- Get the currently active application
tell application "System Events"
    set frontAppName to name of first application process whose frontmost is true
end tell

log "Currently active app: " & frontAppName

-- Determine which app to activate next
set nextAppIndex to 1
repeat with i from 1 to (count of appList)
    if item i of appList is frontAppName then
        -- If current app is last in list, cycle to first, otherwise go to next
        set nextAppIndex to (i mod (count of appList)) + 1
        exit repeat
    end if
end repeat

-- Get the name of the app to activate
set nextAppName to item nextAppIndex of appList
log "Switching to: " & nextAppName

-- Activate the next app
tell application nextAppName
    activate
end tell

-- Show notification
display notification "Switched to " & nextAppName with title "App Switcher"

-- Get the app name from the first argument
on run argv
	set appName to item 1 of argv

	tell application "System Events"
		set frontApp to name of first application process whose frontmost is true
	end tell

	if frontApp is not appName then
		tell application appName to activate
	end if
end run


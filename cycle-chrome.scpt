-- Set persistent file path
set tmpFile to (POSIX path of (path to home folder)) & "code/apple/.cycle-app"
log "Temporary file path: " & tmpFile

-- Read last window index
try
    set fileRef to open for access POSIX file tmpFile
    set lastIndex to (read fileRef as integer)
    log "Last window index read from file: " & lastIndex -- Log the value of lastIndex
    close access fileRef
on error errMsg number errNum
    log "Error occurred: " & errMsg & " (Error number: " & errNum & ")" -- Log the error details
    set lastIndex to 0
    try
        close access POSIX file tmpFile
    end try
end try

tell application "Google Chrome"
	set winCount to count of windows
	log "Number of Chrome windows: " & winCount -- Log the value of winCount
	if winCount is 0 then return
	
	set nextIndex to (lastIndex mod winCount) + 1
	set index of window nextIndex to 1
	activate
	
	log "Activated Chrome window index: " & nextIndex
	display notification "Activated Chrome window " & nextIndex with title "Chrome Window Switcher"
end tell

-- Save updated index
try
    log "Saving next index: " & nextIndex
	set fileRef to open for access POSIX file tmpFile with write permission
	set eof of fileRef to 0
	write nextIndex as integer to fileRef
	close access fileRef
end try
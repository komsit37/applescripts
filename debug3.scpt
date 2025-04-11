tell application "System Events"
	set d to desktop 2
    log d
	
	set desktopName to name of d

	
	log "Desktop name: " & desktopName
    get properties of d
end tell
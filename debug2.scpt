tell application "System Events"
	tell (first process whose frontmost is true)
		set win to first window
		set winName to name of win
		set winPos to position of win
		set winSize to size of win
		-- visible does not work
		--set winVisible to visible of win
		set isMinimized to value of attribute "AXMinimized" of win
		set isFullScreen to value of attribute "AXFullScreen" of win
		
		log "Name: " & winName
		log "Position: " & (item 1 of winPos) & ", " & (item 2 of winPos)
		log "Size: " & (item 1 of winSize) & ", " & (item 2 of winSize)
		--log "Visible: " & winVisible
		log "Minimized: " & isMinimized
		log "FullScreen: " & isFullScreen

		get properties of win
	end tell
end tell

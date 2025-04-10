(*
Window Manager Script
--------------------
This script manages window sizes and positions on macOS. It cycles through predefined
window widths (50%, 67%, 75%, 100%) while maintaining full height.

Arguments:
- align: Optional window alignment [string]
    "l" - Left align (default)
    "r" - Right align
    "c" - Center align
    "t" - Top align
    "b" - Bottom align

Behavior:
- Cycles through window sizes on each execution
- Resets to smallest size after 5 seconds of inactivity
- Resets when alignment changes
- Stores state in temporary file for persistence between runs

Example usage:
    osascript window.scpt       # Left alignment (default)
    osascript window.scpt r     # Right alignment
    osascript window.scpt c     # Center alignment
    osascript window.scpt t     # Top alignment
    osascript window.scpt b     # Bottom alignment
*)

on run argv
    try
        -- Get alignment from argument or use default
        set align to "l" -- default
        set repeatTimeLimit to 5 -- seconds
        if (count of argv) > 0 then
            set align to item 1 of argv
            if align is not in {"l", "r", "c", "t", "b"} then
                log "Invalid alignment. Using default (l). Options: [l]eft, [r]ight, [c]enter, [t]op, [b]ottom"
            end if
        end if
        
        -- Log current time in seconds
        set currentTime to ((current date) - (date "Thursday, January 1, 1970 at 00:00:00")) as number
        log "Start time (seconds since epoch): " & currentTime
        
        set wRatio to {0.5, 0.67, 0.75, 1, 0.25, 0.33}
        set screenWidth to 2560
        set screenHeight to 1440
        set tmpFile to (POSIX path of (path to home folder)) & ".window_index"
        
        -- Read index and timestamp from temp file or initialize
        try
            set fileRef to open for access tmpFile
            set csvData to read fileRef
            close access fileRef
            
            -- Parse CSV data
            set AppleScript's text item delimiters to ","
            set csvItems to text items of csvData

            -- 1. index
            set i to (item 1 of csvItems) as integer
            set previousTime to (item 2 of csvItems) as number
            
            -- 2. Reset index if more than 5 seconds elapsed
            set elapsedTime to currentTime - previousTime
            -- log "Elapsed time since last execution: " & elapsedTime & " seconds"
            if elapsedTime > repeatTimeLimit then
                -- Reset index if more than repeatTimeLimit seconds elapsed
                set i to 1
                log "More than " & repeatTimeLimit & " seconds elapsed, resetting window size index to 1"
            end if

            -- 3. Reset index if alignment changed
            set previousAlign to item 3 of csvItems
            if previousAlign ≠ align then
                set i to 1
                log "Alignment changed from " & previousAlign & " to " & align & ", resetting window size index to 1"
            end if
        on error
            set i to 1
        end try
        
        -- Set window size and position
        tell application "System Events"
            -- Get frontmost process and resize its window
            tell (first process whose frontmost is true)
                set frontWindow to first window
                tell frontWindow
                    set windowWidth to screenWidth * item i of wRatio
                    set windowHeight to screenHeight * item i of wRatio
                    
                    -- Set position based on alignment
                    if align is "l" then
                        set position to {0, 0}
                        set size to {windowWidth, screenHeight}
                    else if align is "r" then
                        set position to {screenWidth - windowWidth, 0}
                        set size to {windowWidth, screenHeight}
                    else if align is "c" then
                        set position to {(screenWidth - windowWidth) / 2, 0}
                        set size to {windowWidth, screenHeight}
                    else if align is "t" then
                        -- Get current position and size
                        set {currentX, currentY} to position
                        set {currentWidth, currentHeight} to size
                        set position to {currentX, 0}
                        set size to {currentWidth, windowHeight}
                    else if align is "b" then
                        -- Get current position and size
                        set {currentX, currentY} to position
                        set {currentWidth, currentHeight} to size
                        set position to {currentX, screenHeight - windowHeight}
                        set size to {currentWidth, windowHeight}
                    end if
                end tell
            end tell
        end tell
        
        -- Calculate next index and save to file with timestamp
        set nextI to (i mod (count of wRatio)) + 1
        set fileRef to open for access tmpFile with write permission
        set eof of fileRef to 0
        -- Convert numbers to text and add align to CSV
        write ((nextI as text) & "," & (currentTime as text) & "," & align) as text to fileRef
        close access fileRef
        
    on error errMsg
        log "Error: " & errMsg
    end try
end run
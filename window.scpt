(*
Window Manager Script
--------------------
This script manages window sizes and positions on macOS. It cycles through predefined
window widths and heights.

Monitor Setup:
- Monitor 1 (Primary): 2560x1440
- Monitor 2 (Secondary, Portrait): 1080x1920
- Coordinates span across both monitors: (0 to 3640) x (-480 to 1440)

Arguments:
- align: Optional window alignment [string]
    "l" - Left align (default)
    "r" - Right align
    "c" - Center align
    "t" - Top align
    "b" - Bottom align

Behavior:
- Automatically detects which monitor the window is on
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
                    -- for 't' and 'b' to keep current width and x
                    -- Get current position and size
                    set {current_x, current_y} to position
                    set {current_w, current_h} to size
                    log "Current position: " & current_x & ", " & current_y
                    log "Current size: " & current_w & ", " & current_h

                    set wRatio to {0.5, 0.67, 0.75, 1, 0.25, 0.33}
                    set MONITOR1_W to 2560
                    set MONITOR1_H to 1440

                    set MONITOR2_W to 1080
                    set MONITOR2_H to 1920

                    -- Set screen size based on monitor
                    -- x, y coordinates are absolute of the combination of both monitors: (0 to 3640) x (-480 to 1440)
                    -- add some slack to assume it's on Monitor 2 when the edge is close to the right
                    if current_x < (MONITOR1_W - 200) then
                        log "On Monitor 1!"
                        if align is in {"r", "l", "c"} then
                            set wRatio to {0.5, 0.67, 0.75, 1, 0.25, 0.33}
                        else if align is in {"t", "b"} then
                            set wRatio to {0.5, 0.67, 1, 0.33}
                        end if
                        set screen_w to MONITOR1_W
                        set screen_h to MONITOR1_H
                        set start_pos_x to 0
                        set start_pos_y to 0
                    else
                        log "On Monitor 2!"
                        if align is in {"r", "l", "c"} then
                            set wRatio to {1, 0.5}
                        else if align is in {"t", "b"} then
                            set wRatio to {0.5, 0.67, 1, 0.33}
                        end if
                        set screen_w to MONITOR2_W
                        set screen_h to MONITOR2_H
                        set start_pos_x to MONITOR1_W
                        set start_pos_y to -133
                    end if
                    log "Screen size: " & screen_w & ", " & screen_h

                    set window_w to screen_w * item i of wRatio
                    set window_h to screen_h * item i of wRatio
                    
                    -- Set position based on alignment
                    if align is "l" then
                        set position to {start_pos_x, start_pos_y}
                        set size to {window_w, screen_h}
                    else if align is "r" then
                        set position to {start_pos_x + screen_w - window_w, start_pos_y}
                        set size to {window_w, screen_h}
                    else if align is "c" then
                        set position to {start_pos_x +(screen_w - window_w) / 2, start_pos_y}
                        set size to {window_w, screen_h}
                    else if align is "t" then
                        set position to {current_x, start_pos_y}
                        set size to {current_w, window_h}
                    else if align is "b" then
                        set position to {current_x, screen_h - window_h + start_pos_y}
                        set size to {current_w, window_h}
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
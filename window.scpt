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
        -- Get alignment from argument or use default (optimized validation)
        set align to "l"
        set repeatTimeLimit to 5
        if (count of argv) > 0 then
            set testAlign to item 1 of argv
            if testAlign is in {"l", "r", "c", "t", "b"} then
                set align to testAlign
            end if
        end if
        
        -- Pre-compute monitor constants
        set MONITOR1_W to 2560
        set MONITOR1_H to 1440
        set MONITOR2_W to 1080
        set MONITOR2_H to 1920
        set MONITOR1_THRESHOLD to MONITOR1_W - 200
        
        -- Pre-compute ratios for each monitor/alignment combination
        set monitor1_ratios_horizontal to {0.5, 0.67, 0.75, 1, 0.25, 0.33}
        set monitor1_ratios_vertical to {0.5, 0.67, 1, 0.33}
        set monitor2_ratios_horizontal to {1, 0.5}
        set monitor2_ratios_vertical to {0.5, 0.67, 1, 0.33}
        
        set currentTime to ((current date) - (date "Thursday, January 1, 1970 at 00:00:00")) as number
        set tmpFilePath to (POSIX path of (path to home folder)) & ".window_index"
        set tmpFile to POSIX file tmpFilePath
        
        -- Handle state management (optimized file I/O)
        set i to 1
        try
            set fileContent to (read tmpFile)
            -- log "File content: " & fileContent
            set AppleScript's text item delimiters to ","
            set csvItems to text items of fileContent
            
            if (count of csvItems) ≥ 3 then
                set prevIndex to (item 1 of csvItems) as integer
                set prevTime to (item 2 of csvItems) as number
                set prevAlign to item 3 of csvItems
                
                -- Check if we should reset (time or alignment change)
                if (currentTime - prevTime ≤ repeatTimeLimit) and (prevAlign = align) then
                    set i to prevIndex
                end if
            end if
        on error errMsg
            -- File doesn't exist or is corrupted, use default
            log "File doesn't exist or is corrupted, using default: " & errMsg
        end try
        
        -- Get window properties in one batch operation
        tell application "System Events"
            tell (first process whose frontmost is true)
                tell first window
                    set {current_x, current_y} to position
                    set {current_w, current_h} to size
                    
                    -- Determine monitor and get appropriate ratios
                    if current_x < MONITOR1_THRESHOLD then
                        -- Monitor 1
                        if align is in {"t", "b"} then
                            set wRatio to monitor1_ratios_vertical
                        else
                            set wRatio to monitor1_ratios_horizontal
                        end if
                        set screen_w to MONITOR1_W
                        set screen_h to MONITOR1_H
                        set start_pos_x to 0
                        set start_pos_y to 0
                    else
                        -- Monitor 2
                        if align is in {"t", "b"} then
                            set wRatio to monitor2_ratios_vertical
                        else
                            set wRatio to monitor2_ratios_horizontal
                        end if
                        set screen_w to MONITOR2_W
                        set screen_h to MONITOR2_H
                        set start_pos_x to MONITOR1_W
                        set start_pos_y to -133
                    end if
                    
                    -- Calculate new dimensions
                    set window_ratio to item i of wRatio
                    set window_w to screen_w * window_ratio
                    set window_h to screen_h * window_ratio
                    
                    -- Calculate position and size based on alignment (optimized with single property set)
                    if align is "l" then
                        set new_pos to {start_pos_x, start_pos_y}
                        set new_size to {window_w, screen_h}
                    else if align is "r" then
                        set new_pos to {start_pos_x + screen_w - window_w, start_pos_y}
                        set new_size to {window_w, screen_h}
                    else if align is "c" then
                        set new_pos to {start_pos_x + (screen_w - window_w) / 2, start_pos_y}
                        set new_size to {window_w, screen_h}
                    else if align is "t" then
                        set new_pos to {current_x, start_pos_y}
                        set new_size to {current_w, window_h}
                    else -- align is "b"
                        set new_pos to {current_x, screen_h - window_h + start_pos_y}
                        set new_size to {current_w, window_h}
                    end if
                    
                    -- Set both properties at once for better performance
                    set position to new_pos
                    set size to new_size
                end tell
            end tell
        end tell
        
        -- Update state file (optimized write)
        set nextI to (i mod (count of wRatio)) + 1
        set stateData to (nextI as text) & "," & (currentTime as text) & "," & align
        
        try
            set fileRef to open for access tmpFile with write permission
            set eof of fileRef to 0
            write stateData to fileRef
            close access fileRef
        on error
            -- Ignore file write errors to avoid slowing down the script
        end try
        
    on error errMsg
        -- Minimal error logging for performance
        display notification "Window script error" with title "Error"
    end try
end run
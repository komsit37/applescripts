(*
Window Resize Script
-------------------
This script moves and resizes the frontmost window by relative amounts.

Arguments (all required):
- arg1: Relative X position change (±pixels)
- arg2: Relative Y position change (±pixels) 
- arg3: Relative width change (±pixels)
- arg4: Relative height change (±pixels)

Example usage:
    osascript window_resize.scpt 100 -50 200 -100
    # Moves window right 100px, up 50px, makes it 200px wider, 100px shorter

    osascript window_resize.scpt -100 0 0 50
    # Moves window left 100px, increases height by 50px

    osascript window_resize.scpt 0 0 -200 0
    # Makes window 200px narrower, no position change

Performance Optimizations:
The script implements intelligent caching to minimize expensive system operations:

1. Process Caching:
   - Caches the frontmost process name to avoid expensive process enumeration
   - Falls back to full process search only when the cached process is no longer frontmost

2. Window Property Caching:
   - Caches window position and size from the previous run
   - Avoids expensive window property reads when operating on the same window
   - Cache expires after 5 seconds to allow for manual window repositioning

3. State Persistence:
   - Stores: processName,x,y,width,height,timestamp
   - Backwards compatible with missing or corrupted cache files
*)

on run argv
    try
        -- Validate arguments
        if (count of argv) < 4 then
            display notification "Usage: window_resize.scpt ±x ±y ±w ±h" with title "Window Resize"
            return
        end if
        
        -- Parse arguments
        set deltaX to (item 1 of argv) as number
        set deltaY to (item 2 of argv) as number
        set deltaW to (item 3 of argv) as number
        set deltaH to (item 4 of argv) as number
        
        -- Cache management setup
        set cacheTimeLimit to 5
        set currentTime to ((current date) - (date "Thursday, January 1, 1970 at 00:00:00")) as number
        set cacheFilePath to (POSIX path of (path to home folder)) & ".window_resize_cache"
        set cacheFile to POSIX file cacheFilePath
        
        -- Initialize cache variables
        set cachedProcessName to ""
        set cachedX to missing value
        set cachedY to missing value
        set cachedW to missing value
        set cachedH to missing value
        
        -- Try to read cache
        try
            set cacheContent to (read cacheFile)
            set AppleScript's text item delimiters to ","
            set cacheItems to text items of cacheContent
            
            if (count of cacheItems) ≥ 6 then
                set cachedProcessName to item 1 of cacheItems
                set cachedX to (item 2 of cacheItems) as number
                set cachedY to (item 3 of cacheItems) as number
                set cachedW to (item 4 of cacheItems) as number
                set cachedH to (item 5 of cacheItems) as number
                set cacheTime to (item 6 of cacheItems) as number
                
                -- Check if cache is expired
                if (currentTime - cacheTime) > cacheTimeLimit then
                    set cachedProcessName to ""
                    set cachedX to missing value
                end if
            end if
        on error
            -- Cache file doesn't exist or is corrupted, use defaults
        end try
        
        -- Get frontmost window and its current properties with caching
        set currentProcessName to ""
        set currentX to missing value
        set currentY to missing value
        set currentW to missing value
        set currentH to missing value
        
        tell application "System Events"
            set targetProcess to missing value
            
            -- Try to use cached process first
            if cachedProcessName is not "" then
                try
                    set targetProcess to process cachedProcessName
                    if not (frontmost of targetProcess) then
                        set targetProcess to missing value
                    end if
                on error
                    set targetProcess to missing value
                end try
            end if
            
            -- Fall back to expensive frontmost search if cache failed
            if targetProcess is missing value then
                -- set targetProcess to (first process whose frontmost is true)
                -- more specific and doesn't include background-only processes
               set targetProcess to first application process whose frontmost is true
            end if
            
            set currentProcessName to name of targetProcess
            
            -- Try to use cached position/size if process matches and cache is valid
            if (currentProcessName = cachedProcessName) and (cachedX is not missing value) then
                set currentX to cachedX
                set currentY to cachedY
                set currentW to cachedW
                set currentH to cachedH
            else
                -- Fall back to reading from window
                tell targetProcess
                    tell first window
                        set {currentX, currentY} to position
                        set {currentW, currentH} to size
                    end tell
                end tell
            end if
        end tell
        
        -- Calculate new position and size
        set newX to currentX + deltaX
        set newY to currentY + deltaY
        set newW to currentW + deltaW
        set newH to currentH + deltaH
        
        -- Ensure minimum window size (prevent negative or too small dimensions)
        if newW < 100 then set newW to 100
        if newH < 100 then set newH to 100
        
        -- Apply changes
        tell application "System Events"
            tell targetProcess
                tell first window
                    -- Only set position if there are position changes
                    if deltaX ≠ 0 or deltaY ≠ 0 then
                        set position to {newX, newY}
                    end if
                    
                    -- Only set size if there are size changes
                    if deltaW ≠ 0 or deltaH ≠ 0 then
                        set size to {newW, newH}
                    end if
                end tell
            end tell
        end tell
        
        -- Update cache with new values
        set cacheData to currentProcessName & "," & newX & "," & newY & "," & newW & "," & newH & "," & currentTime
        try
            set fileRef to open for access cacheFile with write permission
            set eof of fileRef to 0
            write cacheData to fileRef
            close access fileRef
        on error
            -- Ignore cache write errors to avoid slowing down the script
        end try
        
    on error errMsg
        display notification "Error: " & errMsg with title "Window Resize Error"
    end try
end run 
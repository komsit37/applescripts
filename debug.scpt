-- Script to retrieve display resolutions for multiple monitors
-- Uses system_profiler to get display information and processes it using sed
-- Returns resolution as {width, height} for specified monitor number
-- Returns {0, 0} if monitor doesn't exist

on getMonitorResolution(monitorNumber)
    set resString to do shell script "system_profiler SPDisplaysDataType | grep 'UI Looks like' | sed -n '" & monitorNumber & "p' | sed -E 's/.*: ([0-9]+) x ([0-9]+).*/\\1 \\2/'"
    if resString is equal to "" then
        return {0, 0} -- Return default values if monitor doesn't exist
    end if
    set {resWidth, resHeight} to words of resString
    return {resWidth as integer, resHeight as integer}
end getMonitorResolution

-- Example usage:
set monitor1Resolution to getMonitorResolution(1)
set monitor2Resolution to getMonitorResolution(2)

log "First Monitor Resolution: " & item 1 of monitor1Resolution & " x " & item 2 of monitor1Resolution
log "Second Monitor Resolution: " & item 1 of monitor2Resolution & " x " & item 2 of monitor2Resolution


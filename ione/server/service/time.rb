# Returns current time in ctime format
# @return [String]
def time
    Time.now.ctime
end

# Formats time from seconds from the start of Time to dd:hh:mm:ss format
# @param [Integer] sec
# @return [String]
def fmt_time(sec)
    sec = sec.to_i
    days = (sec / 86400).to_i
    sec -= days * 86400
    hours = (sec / 3600.0).to_i
    sec -= hours * 3600
    minutes = (sec / 60.0).to_i
    "#{days}d:#{hours}h:#{minutes}m:#{sec % 60}s"
end
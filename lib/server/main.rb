########################################################
#       Server control and info-getting methods        #
########################################################

puts 'Extending Handler class by server-info getters'
class IONe
    # Returns current running IONe Cloud Server version
    # @return [String]
    def version
        LOG_STAT()
        id = id_gen()
        LOG_CALL(id, true, __method__)
        defer { LOG_CALL(id, false, 'version') }
        VERSION
    end
    # Returns IONe Cloud Server uptime(formated)
    # @return [String]
    def uptime
        LOG_STAT()
        id = id_gen()
        LOG_CALL(id, true, __method__)
        defer { LOG_CALL(id, false, 'uptime') }
        fmt_time(Time.now.to_i - STARTUP_TIME)
    end
    # Returns active processes list
    def proc
        $PROC
    end

    # Returns whole IONe settings table if user is Admin
    # @return [Hash]
    def get_all_settings
        return @db[:settings].as_hash(:name, :body) if onblock(:u, -1, @client).is_admin
    end
end
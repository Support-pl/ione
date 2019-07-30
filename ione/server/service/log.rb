# IONe built-in logger functions 
module IONeLoggerKit
    require "#{ROOT}/service/time.rb"
    require "colorize"

    `echo > #{LOG_ROOT}/errors.txt && chown oneadmin:oneadmin #{LOG_ROOT}/errors.txt`
    `echo > #{LOG_ROOT}/sys.log && chown oneadmin:oneadmin #{LOG_ROOT}/sys.log` if !CONF['Other']['key']

    $log = []

    at_exit do
        File.open("#{LOG_ROOT}/old.log", 'a') { |file| file.write($log.join("\n")) }
    end

    DESTINATIONS = Hash.new('ione.log')
    DESTINATIONS.merge!({
        'DEBUG' => 'debug.log'        
    })

    # Logging the message to the one of three destinations
    # @param [String] msg Message you want to log
    # @param [String] method Method name, which is logging now something
    # @note If method name setted to 'SnapController', message will be logged into snapshot.log
    # @note If method name setted to 'DEBUG', message will be logged into debug.log
    # @param [Boolean] _time Print or not to print log time
    # @return [Boolean] true
    def LOG(msg, method = "none", _time = true)
        return true unless MAIN_IONE
        case method
        when 'DEBUG'
            destination = "#{LOG_ROOT}/debug.log"
        when "SnapController"
            destination = "#{LOG_ROOT}/snapshot.log"
        else
            destination = "#{LOG_ROOT}/ione.log"
        end
        msg = msg.to_s
        msg = "[ #{time()} ] " + msg if _time
        msg += " [ #{method} ]" if method != 'none' && method != "" && method != nil

        File.open(destination, 'a'){ |log| log.write msg + "\n" }
        File.open("#{LOG_ROOT}/suspend.log", 'a'){ |log| log.write msg + "\n" } if method == 'Suspend'

        $log << "#{msg} | #{destination}"
        puts "Should be logged, params - #{method}, #{_time}, #{destination}:\n#{msg}" if DEBUG
        true
    end
    # Logging the message with choosen color and font to the one of two destinations
    # Check out 'colorize' gem for available colors and fonts 
    def LOG_COLOR(msg, method = caller_locations(1,1)[0].label.dup, color = 'red', font = 'bold')
        return true unless MAIN_IONE
        destination = "#{LOG_ROOT}/ione.log"
        destination = "#{LOG_ROOT}/snapshot.log" if method == "SnapController"
        msg = msg.to_s.send(color).send(font)
        msg = "[ #{time()} ] " + msg
        method.slice!('block in '.dup)
        msg += " [ #{method} ]" if method != 'none' && method != "" && method != nil

        File.open(destination, 'a'){ |log| log.write msg + "\n" }
        File.open("#{LOG_ROOT}/suspend.log", 'a'){ |log| log.write msg + "\n" } if method == 'Suspend'

        $log << "#{msg} | #{destination}"
        puts "Should be logged, params - #{method}, #{_time}, #{destination}:\n#{msg}" if DEBUG
        true
    end
    alias LOG_ERROR LOG_COLOR
    def LOG_DEBUG(msg, method = 'DEBUG', _time = true)
        destination = "#{LOG_ROOT}/debug.log"
        msg = "[ #{time()} ] #{msg}"
        File.open(destination, 'a'){ |log| log.write msg + "\n" }
        $log << "#{msg} | #{destination}"
        puts "Should be logged, params - #{method}, #{_time}, #{destination}:\n#{msg}" if DEBUG
        true
    end
    # Logging the message to the one of three destinations
    # @param [String] msg Message you want to log
    # @param [String] method Method name, which is logging now something
    # @note This function gets method name automatically
    # @note If method name setted to 'SnapController', message will be logged into snapshot.log
    # @note If method name setted to 'DEBUG', message will be logged into debug.log
    # @param [Boolean] _time Print or not to print log time
    # @return [Boolean] true
    def LOG_TEST(msg, method = caller_locations(1,1)[0].label, _time = true)
        return true unless MAIN_IONE
        case method
        when 'DEBUG'
            destination = "#{LOG_ROOT}/debug.log"
        when "SnapController"
            destination = "#{LOG_ROOT}/snapshot.log"
        else
            destination = "#{LOG_ROOT}/ione.log"
        end
        msg = msg.to_s
        msg = "[ #{time()} ] " + msg if _time
        msg += " [ #{method} ]" if method != 'none' && method != "" && method != nil

        File.open(destination, 'a'){ |log| log.write msg + "\n" }
        File.open("#{LOG_ROOT}/suspend.log", 'a'){ |log| log.write msg + "\n" } if method == 'Suspend'

        $log << "#{msg} | #{destination}"
        puts "Should be logged, params - #{method}, #{_time}, #{destination}:\n#{msg}" if DEBUG
        true
    end

    # Processes list are active now 
    $PROC = []

    # Puts processes to process list and deletes them out
    # @param [Integer] id Process id, you should generate it using id_gen function
    # @param [Boolean] called If true adds process to list, of false deletes
    # @param [String | Object] method Method name or _method_ object. This function trying to get method-name automatically
    # @return [Boolean] true
    # @note You may check this log at $IONELOGROOT/sys.log
    def LOG_CALL(id, called, method = caller_locations(1,1)[0].label)
        level, method = 0, method.to_s
        caller_locations.each do | loc |
            loc = loc.label
            if $methods.include? loc then
                level += 1
                next
            end
            $methods.each do | method |
                if loc.include? method then
                    level += 1 
                    break
                end
            end
        end
        msg = "[ #{time()} ] Method #{called ? $PROC.push("#{method}:#{id}").last : $PROC.delete("#{method}:#{id}")} #{called ? 'called' : 'closed'}\n" if level < 2
        if level > 1  || !called then
            tabs = (0..(level - 3)).to_a.inject("                             "){|tabs, i| tabs +  "    "}
            msg = "#{tabs}|-- Method #{method.to_s}:#{id} #{called ? 'called' : 'closed'}\n"
        end

        File.open(LOG_ROOT + '/sys.log', 'a'){ |log| log.write msg }
        true
    end

    # ID counter
    $id = 0
    
    # ID generator
    # @return [String] heximal number
    def id_gen
        ($id += 1).to_s(16)
    end
end

class IONe
    # Get log from ione.log file
    # @return [String] Log
    def activity_log()
        LOG_STAT()        
        LOG "Log file content has been copied remotely", "activity_log"
        log = File.read("#{LOG_ROOT}/ione.log")
        log
    end
    # Logs given message to ione.log
    # @param [String] msg - your message
    # @return [String] returns given message
    def log(msg)
        LOG_STAT()        
        LOG(msg, "RemoteLOG")
        msg
    end
end
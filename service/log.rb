# IONe built-in logger functions 
module IONeLoggerKit
    require "#{ROOT}/service/time.rb"
    require "colorize"

    `echo > #{LOG_ROOT}/errors.txt && chown oneadmin:oneadmin #{LOG_ROOT}/errors.txt`
    `echo > #{LOG_ROOT}/sys.log && chown oneadmin:oneadmin #{LOG_ROOT}/sys.log`

    $log = []

    at_exit do
        File.open("#{LOG_ROOT}/old.log", 'a') { |file| file.write($log.join("\n")) }
    end

    # Table with log locations linked to method name or given label
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
        case method
        when 'DEBUG'
            destination = "#{LOG_ROOT}/debug.log"
        when "SnapController"
            destination = "#{LOG_ROOT}/snapshot.log"
        when "TrafficRecorder"
            destination = "#{LOG_ROOT}/traffic_recorder.log"
        else
            destination = "#{LOG_ROOT}/ione.log"
        end
        msg = msg.to_s
        msg = "[ #{Time.now.ctime} ] " + msg if _time
        msg += " [ #{method} ]" if method != 'none' && method != "" && method != nil

        File.open(destination, 'a'){ |log| log.write msg + "\n" }
        File.open("#{LOG_ROOT}/suspend.log", 'a'){ |log| log.write msg + "\n" } if method == 'Suspend'

        $log << "#{msg} | #{destination}"
        true
    end
    # Logging the message with choosen color and font to the one of two destinations
    # Check out 'colorize' gem for available colors and fonts 
    def LOG_COLOR(msg, method = caller_locations(1,1)[0].label.dup, color = 'red', font = 'bold')
        destination = "#{LOG_ROOT}/ione.log"
        destination = "#{LOG_ROOT}/snapshot.log" if method == "SnapController"
        destination = "#{LOG_ROOT}/traffic_recorder.log" if method == "TrafficRecorder"
        msg = msg.to_s.send(color).send(font)
        msg = "[ #{Time.now.ctime} ] " + msg
        method.slice!('block in '.dup)
        msg += " [ #{method} ]" if method != 'none' && method != "" && method != nil

        File.open(destination, 'a'){ |log| log.write msg + "\n" }
        File.open("#{LOG_ROOT}/suspend.log", 'a'){ |log| log.write msg + "\n" } if method == 'Suspend'

        $log << "#{msg} | #{destination}"
        true
    end
    alias LOG_ERROR LOG_COLOR
    # Logging the message directly into LOG_LOCATION/debug.log
    def LOG_DEBUG(msg, method = 'DEBUG', _time = true)
        destination = "#{LOG_ROOT}/debug.log"
        msg = "[ #{Time.now.ctime} ] #{msg}"
        File.open(destination, 'a'){ |log| log.write msg + "\n" }
        $log << "#{msg} | #{destination}"
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
    def LOG_AUTO(msg, method = caller_locations(1,1)[0].label, _time = true)
        case method
        when 'DEBUG'
            destination = "#{LOG_ROOT}/debug.log"
        when "SnapController"
            destination = "#{LOG_ROOT}/snapshot.log"
        when "TrafficRecorder"
            destination = "#{LOG_ROOT}/traffic_recorder.log"
        else
            destination = "#{LOG_ROOT}/ione.log"
        end
        msg = msg.to_s
        msg = "[ #{Time.now.ctime} ] " + msg if _time
        msg += " [ #{method} ]" if method != 'none' && method != "" && method != nil

        File.open(destination, 'a'){ |log| log.write msg + "\n" }
        File.open("#{LOG_ROOT}/suspend.log", 'a'){ |log| log.write msg + "\n" } if method == 'Suspend'

        $log << "#{msg} | #{destination}"
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
        LOG "Log file content has been copied remotely", "activity_log"
        log = File.read("#{LOG_ROOT}/ione.log")
        log
    end
    # Logs given message to ione.log
    # @param [String] msg - your message
    # @return [String] returns given message
    def log(msg)
        LOG(msg, "RemoteLOG")
        msg
    end
end
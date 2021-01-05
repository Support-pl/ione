
def 100to101
    # Write TrafficRecorder to conf and scripts
    # touch traffic-recorder log file

    # Update hooks

    # Update UI

    # Remove service/objects/records
    # Add service/billers/*, service/biller.rb, showback.rb
    # Add service/records/*
    # Add service/records.rb

    # Add insert_zero_traffic_record.rb hook

    # Update meta
    # Update lib

    # Update service/objects/*

    # Update ione_server.rb
    # Update service/log.rb
    # Update models/SettingsDriver.rb

    # Delete models/SunstoneServer.rb
    # Delete models/SunstoneViews.rb

    # Delete modules/stat/main.rb
    # Delete service/handlers/cache_handler.rb

    # remove lib/appbindings/main.rb

    # Update sys/ione.service
end

available_versions = [
    ['v1.0.0', 'v1.0.1', method(:100to101)]
]

desc "Update IONe"
task :update do
    puts "Preparing for update..."
    begin
       @version = File.read('/usr/lib/one/ione/meta/version.txt').chomp.split(' ').first
       r = nil
       until %w(y n).include? r do
        print "You have IONe #{@version} installed, is it correct? (y/n) "
        r = STDIN.gets.chomp
       end
       raise if r == 'n'
    rescue
        r = nil
        until %w(y n).include? r do
            print 'Currently installed version cannot be found, do you want to enter it manually? (y/n) '
            r = STDIN.gets.chomp
        end
        if r == 'n' then
            puts 'Bye.'
            exit 0
        end
        r = nil
        until r == 'y' do
            print 'Enter your currenly installed IONe version like vX.Y.Z: '
            @version = STDIN.gets.chomp
            print "You've entered \"#{@version}\", is it correct? (y/n) "
            r = STDIN.gets.chomp
        end
    end

    puts 'Seeking for update scripts...'
    script = available_versions.select { | ver | ver.first == @version }

    r = nil
    until %w(y n).include? r do
        puts "You can update to version #{script[1]} now."
        print "Proceed? (y/n) "
        r = STDIN.gets.chomp
    end
    if r == 'n' then
        puts 'Bye.'
        exit 0
    end
end
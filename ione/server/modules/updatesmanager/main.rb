class IONe
    # Updates IONe from Github
    def IONeUpdate(token, trace = ["Update Process starter:#{__LINE__}"])
        return 'Wrong token!' if token != CONF['UpdatesManager']['update-token']
        LOG_TEST "IONe update query accepted"
        Thread.new do
            begin
                trace << "Creating temporary dirs:#{__LINE__ + 1}"
                `mkdir /tmp/ione`
                `mkdir /tmp/ione_current#{STARTUP_TIME}`

                trace << "Creating backup:#{__LINE__ + 1}"
                `cp -rf #{ROOT}/* /tmp/ione_current/` 

                trace << "Cloning git repository to temporary dir:#{__LINE__ + 1}"
                `git clone --branch #{CONF['UpdatesManager']['branch']} #{CONF['UpdatesManager']['repo']} /tmp/ione`

                trace << "Replacing the old server:#{__LINE__ + 1}"
                `cp -rf /tmp/ione/server/* #{ROOT}/`

                `cp -f /tmp/ione_current/config.yml #{ROOT}/`

                "Starting bundler:#{__LINE__ + 1}"
                `bundle install --gemfile /tmp/ione/Gemfile`

                trace << "Replacing cli utility:#{__LINE__ + 1}"
                `cp /tmp/ione/utils/ione /usr/bin`
                `chmod +x /usr/bin/ione`


                trace << "Replacing systemd service:#{__LINE__ + 1}"
                `mv /tmp/ione/utils/ione.service /lib/systemd/system/ione.service`
                `systemctl daemon-reload`
                
                trace << "Cleaning temporary dir:#{__LINE__ + 1}"
                `rm -rf /tmp/ione`
                `rm -rf #{ROOT}/../utils`

                LOG_COLOR "Update successful, current version: #{File.read("#{ROOT}/meta/version.txt").chomp}\nChanges will be applied after rebooting the server.", 'IONeUpdate', 'lightgreen'
            rescue => e
                LOG_ERROR "Update unsuccessful!!! Nothing will changed. Error: #{e.message}. Traceback is at debug.log"
                LOG trace.join(",\n")
                `cp -rf /tmp/ione_current/* #{ROOT}/`                
            end
        end
        'Update proccess started, check logs for information'
    end
end
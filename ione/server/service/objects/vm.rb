require 'date'
require 'time'

# OpenNebula::VirtualMachine class
class OpenNebula::VirtualMachine
    # Actions supported by OpenNebula scheduler
    SCHEDULABLE_ACTIONS = %w(
        terminate
        terminate-hard
        hold
        release
        stop
        suspend
        resume
        reboot
        reboot-hard
        poweroff
        poweroff-hard
        undeploy
        undeploy-hard
        snapshot-create
    )
    # List of possible billing periods
    # @note Read it in source by pressing button View source down
    BILLING_PERIODS = [
        "0", # Pay-as-you-Go -- default
        /\d/, # Number of days
    ]
    # Generates template for OpenNebula scheduler record
    def generate_schedule_str(id, action, time)
        "\nSCHED_ACTION=[\n" + 
        "  ACTION=\"#{action}\",\n" + 
        "  ID=\"#{id}\",\n" + 
        "  TIME=\"#{time}\" ]"
    end
    # Returns allowed actions to schedule
    # @return [Array]
    def schedule_actions
        SCHEDULABLE_ACTIONS
    end
    # Adds actions to OpenNebula internal scheduler, like --schedule in 'onevm' cli utility
    # @param [String] action - Action which should be scheduled
    # @param [Integer] time - Time when action schould be perfomed in secs
    # @param [String] periodic - Not working now
    # @return true
    def schedule(action, time, periodic = nil)
        return 'Unsupported action' if !SCHEDULABLE_ACTIONS.include? action
        self.info!
        id = 
            begin
                ids = self.to_hash['VM']['USER_TEMPLATE']['SCHED_ACTION']
                if ids.class == Array then
                    ids.last['ID'].to_i + 1
                elsif ids.class == Hash then
                    ids['ID'].to_i + 1
                elsif ids.class == NilClass then
                    ids.to_i
                else
                    raise
                end
            rescue
                0
            end

        # str_periodic = ''

        self.update(self.user_template_str << generate_schedule_str(id, action, time))
    end
    # Unschedules given action by ID
    # @note Not working, if action is already initialized
    def unschedule(id)
        self.info!
        schedule_data, object = self.to_hash['VM']['USER_TEMPLATE']['SCHED_ACTION'], nil

        if schedule_data.class == Array then
            schedule_data.map do | el |
                object = el if el['ID'] == id.to_s
            end
        elsif schedule_data.class == Hash then
            return 'none' if schedule_data['ID'] != id.to_s
            object = schedule_data
        else
            return 'none'
        end
        action, time = object['ACTION'], object['TIME']
        template = self.user_template_str
        template.slice!(generate_schedule_str(id, action, time))
        self.update(template)
    end
    # Lists actions scheduled in OpenNebula
    # @return [NilClass | Hash | Array]
    def scheduler
        self.info!
        self.to_hash['VM']['USER_TEMPLATE']['SCHED_ACTION']
    end
    # Waits until VM will have the given state
    # @param [Integer] s - VM state to wait for
    # @param [Integer] lcm_s - VM LCM state to wait for
    # @return [Boolean]
    def wait_for_state(s = 3, lcm_s = 3)
        i = 0
        until state!() == s && lcm_state!() == lcm_s do
            return false if i >= 3600
            sleep(1)
            i += 1
        end
        true
    end

    #!@group vCenterHelper

    # Sets resources allocation limits at vCenter node
    # @note For correct work of this method, you must keep actual vCenter Password at VCENTER_PASSWORD_ACTUAL attribute in OpenNebula
    # @note Attention!!! VM will be rebooted at the process
    # @note Valid units are: CPU - MHz, RAM - MB
    # @note Method searches VM by it's default name: one-(id)-(name), if target vm got another name, you should provide it
    # @param [Hash] spec - List of limits should be applied to target VM
    # @option spec [Integer] :cpu  MHz limit for VMs CPU usage
    # @option spec [Integer] :ram  MBytes limit for VMs RAM space usage
    # @option spec [Integer] :iops IOPS limit for VMs disk
    # @option spec [String]  :name VM name on vCenter node
    # @return [String]
    # @example Return messages decode
    #   vm.setResourcesAllocationLimits(spec)
    #       => 'Reconfigure Success' -- Task finished with success code, all specs are equal to given
    #       => 'Reconfigure Unsuccessed' -- Some of specs didn't changed
    #       => 'Reconfigure Error:{error message}' -- Exception has been generated while proceed, check your configuration
    def setResourcesAllocationLimits(spec)
        LOG_DEBUG spec.debug_out
        return 'Unsupported query' if IONe.new($client, $db).get_vm_data(self.id)['IMPORTED'] == 'YES'        
        
        query, host = {}, onblock(:h, IONe.new($client, $db).get_vm_host(self.id))
        datacenter = get_vcenter_dc(host)

        vm = recursive_find_vm(datacenter.vmFolder, spec[:name].nil? ? "one-#{self.info! || self.id}-#{self.name}" : spec[:name]).first
        disk = vm.disks.first

        query[:cpuAllocation] = {:limit => spec[:cpu].to_i, :reservation => 0} if !spec[:cpu].nil?
        query[:memoryAllocation] = {:limit => spec[:ram].to_i} if !spec[:ram].nil?
        if !spec[:iops].nil? then
            disk.storageIOAllocation.limit = spec[:iops].to_i
            disk.backing.sharing = nil
            query[:deviceChange] = [{
                    :device => disk,
                    :operation => :edit
            }]
        end

        state = true
        begin
            LOG_DEBUG 'Powering VM Off'
            LOG_DEBUG vm.PowerOffVM_Task.wait_for_completion
        rescue => e
            state = false
        end
        
            LOG_DEBUG 'Reconfiguring VM'
            LOG_DEBUG vm.ReconfigVM_Task(:spec => query).wait_for_completion
        
        begin
            LOG_DEBUG 'Powering VM On'
            LOG_DEBUG vm.PowerOnVM_Task.wait_for_completion
        rescue
        end if state

    rescue => e
        return "Reconfigure Error:#{e.message}<|>Backtrace:#{e.backtrace}"
    ensure
        return nil
    end
    # Checks if vm is on given vCenter Datastore
    def is_at_ds?(ds_name)
        host = onblock(:h, IONe.new($client, $db).get_vm_host(self.id))
        datacenter = get_vcenter_dc(host)
        begin
            datastore = recursive_find_ds(datacenter.datastoreFolder, ds_name, true).first
        rescue
            return 'Invalid DS name.'
        end
        self.info!
        search_template = "VirtualMachine(\"#{self.deploy_id}\")"
        datastore.vm.each do | vm |
            return true if vm.to_s == search_template
        end
        false
    end
    # Gets the datastore, where VM allocated is
    # @return [String] DS name
    def get_vms_vcenter_ds
        host = onblock(:h, IONe.new($client, $db).get_vm_host(self.id))
        datastores = get_vcenter_dc(host).datastoreFolder.children
        
        self.info!
        search_template = "VirtualMachine(\"#{self.deploy_id}\")"
        datastores.each do | ds |
            ds.vm.each do | vm |
                return ds.name if vm.to_s == search_template
            end
        end
    end
    # Resizes VM without powering off the VM
    # @param [Hash] spec
    # @option spec [Integer] :cpu CPU amount to set
    # @option spec [Integer] :ram RAM amount in MB to set
    # @option spec [String] :name VM name on vCenter node
    # @return [Boolean | String]
    # @note Method returns true if resize action ended correct, false if VM not support hot reconfiguring
    def hot_resize(spec = {:name => nil})
        return false if !self.hotAddEnabled?
        begin
            host = onblock(:h, IONe.new($client, $db).get_vm_host(self.id))
            datacenter = get_vcenter_dc(host)

            vm = recursive_find_vm(datacenter.vmFolder, spec[:name].nil? ? "one-#{self.info! || self.id}-#{self.name}" : spec[:name]).first
            query = {
                :numCPUs => spec[:cpu],
                :memoryMB => spec[:ram]
            }
            vm.ReconfigVM_Task(:spec => query).wait_for_completion
            return true
        rescue => e
            return "Reconfigure Error:#{e.message}"            
        end
    end
    # Checks if resources hot add enabled
    # @param [String] name VM name on vCenter node
    # @note For correct work of this method, you must keep actual vCenter Password at VCENTER_PASSWORD_ACTUAL attribute in OpenNebula
    # @note Method searches VM by it's default name: one-(id)-(name), if target vm got another name, you should provide it
    # @return [Hash | String] Returns limits Hash if success or exception message if fails
    def hotAddEnabled?(name = nil)
        begin
            host = onblock(:h, IONe.new($client, $db).get_vm_host(self.id))
            datacenter = get_vcenter_dc(host)

            vm = recursive_find_vm(datacenter.vmFolder, name.nil? ? "one-#{self.info! || self.id}-#{self.name}" : name).first
            return {
                :cpu => vm.config.cpuHotAddEnabled, :ram => vm.config.memoryHotAddEnabled
            }
        rescue => e
            return "Unexpected error, cannot handle it: #{e.message}"
        end
    end
    # Sets resources hot add settings
    # @param [Hash] spec
    # @option spec [Boolean] :cpu 
    # @option spec [Boolean] :ram
    # @option spec [String]  :name VM name on vCenter node
    # @return [true | String]
    def hotResourcesControlConf(spec = {:cpu => true, :ram => true, :name => nil})
        begin
            host, name = onblock(:h, IONe.new($client, $db).get_vm_host(self.id)), spec[:name]
            datacenter = get_vcenter_dc(host)

            vm = recursive_find_vm(datacenter.vmFolder, name.nil? ? "one-#{self.info! || self.id}-#{self.name}" : name).first
            query = {
                :cpuHotAddEnabled => spec[:cpu],
                :memoryHotAddEnabled => spec[:ram]
            }
            state = true
            begin
                LOG_DEBUG 'Powering VM Off'
                LOG_DEBUG vm.PowerOffVM_Task.wait_for_completion
            rescue => e
                state = false
            end
            
                LOG_DEBUG 'Reconfiguring VM'
                LOG_DEBUG vm.ReconfigVM_Task(:spec => query).wait_for_completion
            
            begin
                LOG_DEBUG 'Powering VM On'
                LOG_DEBUG vm.PowerOnVM_Task.wait_for_completion
            rescue
            end if state
        rescue => e
            "Unexpected error, cannot handle it: #{e.message}"
        end
    end
    # Gets resources allocation limits from vCenter node
    # @param [String] name VM name on vCenter node
    # @note For correct work of this method, you must keep actual vCenter Password at VCENTER_PASSWORD_ACTUAL attribute in OpenNebula
    # @note Method searches VM by it's default name: one-(id)-(name), if target vm got another name, you should provide it
    # @return [Hash | String] Returns limits Hash if success or exception message if fails
    def getResourcesAllocationLimits(name = nil)
        begin
            host = onblock(:h, IONe.new($client, $db).get_vm_host(self.id))
            datacenter = get_vcenter_dc(host)

            vm = recursive_find_vm(datacenter.vmFolder, name.nil? ? "one-#{self.info! || self.id}-#{self.name}" : name).first
            vm_disk = vm.disks.first
            {cpu: vm.config.cpuAllocation.limit, ram: vm.config.cpuAllocation.limit, iops: vm_disk.storageIOAllocation.limit}
        rescue => e
            "Unexpected error, cannot handle it: #{e.message}"
        end
    end

    #!@endgroup

    # Returns owner user ID
    # @param [Boolean] info - method doesn't get object full info one more time -- usefull if collecting data from pool
    # @return [Integer]
    def uid(info = true)
        self.info! if info
        self['UID']
    end
    # Returns owner user name
    # @param [Boolean] info - method doesn't get object full info one more time -- usefull if collecting data from pool
    # @param [Boolean] from_pool - levels differenct between object and object received from pool.each | object |
    # @return [String]
    def uname(info = true, from_pool = false)
        self.info! if info
        return @xml[0].children[3].text.to_i unless from_pool
        @xml.children[3].text
    end
    # Gives info about snapshots availability
    # @return [Boolean]
    def got_snapshot?
        self.info!
        !self.to_hash['VM']['TEMPLATE']['SNAPSHOT'].nil?
    end
    # Returns all available snapshots
    # @return [Array<Hash>, Hash, nil]
    def list_snapshots
        out = self.to_hash!['VM']['TEMPLATE']['SNAPSHOT']
        out.class == Array ? out : [ out ]
    end
    # Returns actual state without calling info! method
    def state!
        self.info! || self.state
    end
    # Returns actual lcm state without calling info! method
    def lcm_state!
        self.info! || self.lcm_state
    end
    # Returns actual state as string without calling info! method
    def state_str!
        self.info! || self.state_str
    end
    # Returns actual lcm state as string without calling info! method
    def lcm_state_str!
        self.info! || self.lcm_state_str
    end
    # Calculates VMs Showback
    # @param [Integer] stime_req - Point from which calculation starts(timestamp)
    # @param [Integer] etime_req - Point at which calculation stops(timestamp)
    # @param [Boolean] group_by_day - Groups showbacks by days
    # @return [Hash]
    def calculate_showback stime_req, etime_req, group_by_day = false
        raise ShowbackError, ["Wrong Time-period given", stime_req, etime_req] if stime_req >= etime_req
        
        info!

        stime, etime = stime_req, etime_req

        raise ShowbackError, ["VM didn't exist in given time-period", etime, self['/VM/STIME'].to_i] if self['/VM/STIME'].to_i > etime

        stime = self['/VM/STIME'].to_i if self['/VM/STIME'].to_i > stime
        etime = self['/VM/ETIME'].to_i if self['/VM/ETIME'].to_i < etime && self['/VM/ETIME'].to_i != 0

        requested_time = (etime - stime) / 3600.0
        
        ### Quick response for HOLD and PENDING vms ###
        return {
            "id" => id,
            "name" => name,
            "work_time" => 0,
            "time_period_requested" => etime_req - stime_req,
            "time_period_corrected" => etime - stime,
            "CPU" => 0,
            "MEMORY" => 0,
            "DISK" => 0,
            "DISK_TYPE" => self['/VM/USER_TEMPLATE/DRIVE'],
            "EXCEPTION" => "State #{state == 0 ? "HOLD" : "PENDING"}",
            "TOTAL" => 0
        } if state == 0 || state == 1

        records = OpenNebula::Records.new(id).records
    
        if self['//BILLING_PERIOD'] == 'month' then
            first = records.select{|r| r[:state] != 'pnd'}.sort_by{|r| r[:time]}.first[:time]

            unless group_by_day then
                stime = Time.at(stime).to_datetime
                first = Time.at(first).to_datetime
                etime = Time.at(etime).to_datetime
                current, periods = stime > first ? stime : first, 0

                while current <= etime do
                    periods += 1
                    current = current >> 1
                end

                return {"id" => id, "name" => name, "work_time" => etime.to_time.to_i - first.to_time.to_i, "EXCEPTION" => "Billed by calendar month", "TOTAL" => (periods * self['//PRICE'].to_f).round(2)}
            end
        elsif self['//BILLING_PERIOD'].to_i != 0 then
            
            first = records.select{|r| r[:state] != 'pnd'}.sort_by{|r| r[:time]}.first[:time]
            delta = self['//BILLING_PERIOD'].to_i * 86400

            unless group_by_day then
                
                periods = stime > first ? 0 : 1
                periods += (etime - first) / delta
                
                return {"id" => id, "name" => name, "work_time" => etime - first, "EXCEPTION" => "Billed per #{self['//BILLING_PERIOD'].to_i} days", "TOTAL" => (periods * self['//PRICE'].to_f).round(2)}
            else
                showback = []

                diff = (Time.at(etime).to_date - Time.at(first).to_date).to_i + 1
                diff.times do | day |
                    showback << {
                        'date' => Time.at(first + day * 86400).to_a[3..4].join('/'),
                        'TOTAL' => (
                            day % self['//BILLING_PERIOD'].to_i == 0 ? self['//PRICE'].to_f : 0.0 )
                    }
                end
                return {
                    "id" => id, "name" => name, "work_time" => first - stime,
                    "EXCEPTION" => "Billed per #{self['//BILLING_PERIOD'].to_i} days",
                    "showback" => showback,
                    "TOTAL" => showback.inject(0){|total, record| total + record['TOTAL']}
                }
            end
        end

        

        ### Generating Timeline ###
        timeline = []
        records.each_with_index do | record, i |
            timeline << {
                'stime' => record[:time],
                'etime' => i + 1 != records.size ? records[i + 1][:time] - 1 : etime,
                'state' => record[:state]
            }
        end

        timeline.delete_if { |r| (r['etime'] < stime) || (r['stime'] > etime)   }
        raise OpenNebula::Records::NoRecordsError if timeline.empty?
        timeline[0]['stime'] = stime if timeline[0]['stime'] < stime
        timeline[timeline.size - 1]['etime'] = etime if timeline.last['etime'] > etime


        ### Calculating Capacity ###
        cpu     = self['/VM/TEMPLATE/VCPU'].to_f * self['/VM/TEMPLATE/CPU'].to_f
        memory  = self['/VM/TEMPLATE/MEMORY'].to_f / 1024
        disk    = self['/VM/TEMPLATE/DISK/SIZE'].to_f / 1024

        ### Calculating Showback ###
        cpu_cost        = cpu       * self['/VM/TEMPLATE/CPU_COST'].to_f
        memory_cost     = memory    * self['/VM/TEMPLATE/MEMORY_COST'].to_f
        disk_cost       = disk      * self['/VM/TEMPLATE/DISK_COST'].to_f

        unless group_by_day then
            ### Calculating Work Time ###
            work_time = 0
            timeline.each do | record |
                next unless record['state'] == 'on'
                work_time += record['etime'] - record['stime']
            end
            work_time = work_time / 3600.0

            

            ### Calculating Showback ###
            cpu_cost        *= work_time     
            memory_cost     *= work_time     
            disk_cost       *= requested_time

            return {
                "id" => id,
                "name" => name,
                "work_time" => work_time,
                "time_period_requested" => etime_req - stime_req,
                "time_period_corrected" => etime - stime,
                "CPU" => cpu_cost,
                "MEMORY" => memory_cost,
                "DISK" => disk_cost,
                "DISK_TYPE" => self['/VM/USER_TEMPLATE/DRIVE'],
                "TOTAL" => cpu_cost + memory_cost + disk_cost
            }
        else
            timeline.clone.each_with_index do | r, i |
                diff = (Time.at(r['etime']).to_date - Time.at(r['stime']).to_date).to_i
                if diff >= 1 then
                    result, border = [], Time.at(r['stime']).to_a
                    border[0..2] = 59, 59, 23
                    border = Time.local(*border).to_i

                    result << { 'stime' => r['stime'], 'etime' => border, 'state' => r['state'], 'date' => Time.at(r['stime']).to_a[3..4].join('/') }

                    (diff).times do | day |
                        result << { 'stime' => border += 1, 'date' => Time.at(border).to_a[3..4].join('/'), 'etime' => border += 86399, 'state' => r['state'] }
                    end

                    result[diff]['etime'] = r['etime']
                    
                    timeline[i] = result
                else
                    timeline[i]['date'] = Time.at(r['stime']).to_a[3..4].join('/')
                end
            end
            timeline.flatten!

            timeline.map! do | r |
                {
                    "date" => r['date'],
                    "requested_time" => (r['etime'] - r['stime']),
                    'state' => r['state']
                }
            end
            timeline = timeline.group_by { | r | r['date'] }
            timeline = timeline.map do | date, date_records |
                result = date_records.inject({
                    'date' => date,
                    'work_time' => 0,
                    'requested_time' => 0,
                    'CPU' => 0,
                    'MEMORY' => 0,
                    'DISK' => 0,
                    'TOTAL' => 0
                }) do | showback, record |
                    requested_time = record['requested_time'] / 3600.0
                    work_time = record['state'] == 'on' ? requested_time : 0
                    showback['work_time'] += work_time
                    showback['requested_time'] += record['requested_time']
                    showback['CPU'] += cpu_cost * work_time
                    showback['MEMORY'] += memory_cost * work_time
                    showback['DISK'] +=  disk_cost * requested_time if record['state'] != 'pnd'
                    
                    showback
                end

                result['TOTAL'] += (result['CPU'] + result['MEMORY'] + result['DISK'])
                result
            end

            return {
                "id" => id,
                "name" => name,
                "work_time" => timeline.inject(0){|total, record| total + record['work_time']},
                "requested_time" => timeline.inject(0){|total, record| total + record['requested_time']},
                "time_period_requested" => etime_req - stime_req,
                "time_period_corrected" => etime - stime,
                "showback" => timeline,
                "DISK_TYPE" => self['/VM/USER_TEMPLATE/DRIVE'],
                "TOTAL" => timeline.inject(0){|total, record| total + record['TOTAL']}
            }
        end
    rescue OpenNebula::Records::NoRecordsError
        return {
            "id" => id,
            "name" => name,
            "work_time" => 0,
            "time_period_requested" => etime_req - stime_req,
            "time_period_corrected" => etime - stime,
            "CPU" => 0,
            "MEMORY" => 0,
            "DISK" => 0,
            "DISK_TYPE" => 'no_type',
            "EXCEPTION" => "No Records",
            "TOTAL" => 0
        }
    end
    # Returns important data in JSON format
    # @param [IONe] ione - IONe object for calling its methods
    def JSONObject ione
        info!
        res = {}
        res['id'] = id
        res['name'] = name
        res['ip'] = ione.GetIP self
        res['state'] = state_str
        res['lcm_state'] = lcm_state_str

        JSON.generate res
    end
    # Error while processing(calculating) showback Exception
    class ShowbackError < StandardError

        attr_reader :params

        def initialize params = []
            @params = params[1..(params.length - 1)]
            super "#{params[0]}\nParams:#{@params.inspect}"
        end
    end
end
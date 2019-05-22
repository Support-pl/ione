class UserAccountData

    attr_reader :data

    ELEMENT_ID_KEY = 'OID'

    def initialize uid, start_time, end_time
        @uid = uid

        @vm_pool = VirtualMachinePool.new($client)
        @vm_pool.info @uid

        @start_time = start_time
        @end_time   = end_time
    end
    def filter vms
        @data = @data.select { |vm| vms.include? vm[ELEMENT_ID_KEY].to_i}
    end
end

class UserShowback < UserAccountData

    attr_reader :total_cost

    ELEMENT_ID_KEY = 'VMID'

    def initialize uid, start_time, end_time
        super(uid, start_time, end_time)

        showback = @vm_pool.showback(-2, start_month: @start_time[0], end_month: @end_time[0], start_year:  @start_time[1], end_year:  @end_time[1])
        
        begin
            showback = showback['SHOWBACK_RECORDS']['SHOWBACK']
        rescue => e
            LOG_DEBUG showback.message
            LOG_DEBUG e.message
        end
        @data = showback.select { |vm| vm['UID'].to_i == @uid }

        @total_cost = @data.inject(0){ |summ, vm| summ += vm['TOTAL_COST'].to_i }

        remove_instance_variable(:@vm_pool)
    end
end

class UserAccounting < UserAccountData
    def initialize uid, start_time, end_time
        super(uid, start_time, end_time)

        accounting = @vm_pool.accounting(-2, start_time: @start_time, end_time: @end_time)['HISTORY_RECORDS']['HISTORY']
        @data = accounting.select { |vm| vm['VM']['UID'].to_i == @uid }

        remove_instance_variable(:@vm_pool)
    end
end

class UserMonitoring

    attr_reader :monitoring, :cpu, :memory, :nettx, :netrx, :disk, :showback

    MONITORING_EXPRESSIONS = ['MONITORING/CPU', 'MONITORING/MEMORY', 'MONITORING/NETRX', 'MONITORING/NETTX']

    def initialize uid, vms = []
        @client = $cloud_auth.client(onblock(:u, uid).name!)
        @ione = IONe.new(@client, $db)

        vm_pool = VirtualMachinePool.new(@client, uid)
        vm_pool.info!

        @monitoring = {}
        vm_pool.each do |vm|
            @monitoring[vm.id] = vm.monitoring MONITORING_EXPRESSIONS
        end
        @monitoring.delete_if {|vm| !vms.include?(vm.to_i) } unless vms.empty?

        vms = @monitoring.keys if vms.empty?

        @disk = {}
        vms.map do |vmid|
            begin
            vm_data = IONe.new(@client, $db).get_vm_data(vmid)
            @disk[vmid] = [vm_data.get('DS_TYPE', 'DRIVE')]
            @monitoring[vmid]['MONITORING/DISK'] = @disk[vmid]
            rescue
                binding.pry
            end
        end

        parse        
    end
    def filter_by_time time = 0
        tmp = {}
        @monitoring.map do | vm |
            vm[1].map do | record |
                record[1].delete_if {|poll| poll[0].to_i < time }
                record
            end
            tmp[vm[0]] = vm[1]
        end
        @monitoring = tmp
        nil
    end
    def parse
        @cpu, @memory, @nettx, @netrx = {}, {}, {}, {}
        @monitoring.map do | vm |
            @cpu[vm[0]]         = vm[1]['MONITORING/CPU']
            @memory[vm[0]]      = vm[1]['MONITORING/MEMORY']
            @nettx[vm[0]]       = vm[1]['MONITORING/NETTX']
            @netrx[vm[0]]       = vm[1]['MONITORING/NETRX']
        end
        nil
    end
    def calculate
        @showback = {}

        @monitoring.each do | vmid, data |
            vm = onblock(:vm, vmid)
            vm.info!
            host = onblock(:h, @ione.get_vm_host(vm))
            host.info!
            @showback[vm.id] = {}

            data.each do | key, data|
                key = key.split('/')[1]
                num   = case key
                        when 'NETTX', 'NETRX'
                            1.0
                        when 'CPU', 'MEMORY'
                            vm["/VM/TEMPLATE/#{key}"]
                        else
                            nil
                        end
                num = num.nil? ? 0.0 : num.to_f
                price = case key
                        when 'CPU', 'MEMORY'
                            host["/HOST/TEMPLATE/#{key}_COST"]
                        else
                            nil
                        end

                price = price.nil? ? 1.0 : price.to_f

                if key == 'DISK' then
                    disk_data = vm.to_hash['VM']['TEMPLATE']['DISK']
                    
                    @showback[vm.id][key] = 
                    if disk_data.class == Array then
                        disk_data.inject(0) do |summ, disk|
                            summ += disk['SIZE'].to_f * onblock(:ds, disk['DATASTORE_ID']).to_hash!['DATASTORE']['TEMPLATE']['DISK_COST'].to_f
                        end
                    else
                        disk_data['SIZE'].to_f * onblock(:ds, disk_data['DATASTORE_ID']).to_hash!['DATASTORE']['TEMPLATE']['DISK_COST'].to_f
                    end + 1
                else
                    @showback[vm.id][key] = data.inject(0){|summ, value| summ += (value[1].to_f == 0 ? 0 : 1) * num * price }
                end    
            end
        end
        nil
    end
end

class IONe
    def RetrieveShowback user_id, start_time = [-1, -1], end_time = [-1, -1], filter = []
        LOG_DEBUG [user_id, start_time, end_time, filter].inspect
        showback = UserShowback.new user_id, start_time, end_time

        showback.filter filter unless filter.nil? || filter == []

        return showback.data, showback.total_cost
    end
    def GetMonitoringShowbackData uid, time, vms = []
        user_monitoring = UserMonitoring.new(uid, vms)
        user_monitoring.filter_by_time(time)
        user_monitoring.parse
        user_monitoring.calculate

        user_monitoring.showback
    end
    def CalculateShowback uid, stime, etime = Time.now.to_i, group_by_day = false
        vm_pool = @db[:vm_pool].select(:oid).where(:uid => uid).to_a.map! {| vm | vm[:oid]}

        showback = {}
        vm_pool.each do | vm |
            vm = onblock :vm, vm, @client
            vm.info!

            next if vm['/VM/ETIME'].to_i < stime && vm['/VM/ETIME'].to_i != 0
            begin
                showback[vm.id] = vm.calculate_showback(stime, etime, group_by_day).without('time_period_requested', 'time_period_corrected')
                showback[vm.id]['name'] = vm.name
            rescue OpenNebula::VirtualMachine::ShowbackError => e
                if e.message.include? "VM didn't exist in given time-period" then
                    next
                else
                    raise e
                end
            end
        end

        showback['TOTAL'] = showback.values.inject(0){| result, record | result += record['TOTAL'].to_f }
        showback['time_period_requested'] = etime - stime

        showback
    end
    
    # Does very complicated things, don't think about it)))))
    # @param [Hash] params
    # @option params [Integer] 'uid' - UserID
    # @option params [Integer] 'time' - Start point to collect Showback data
    # @option params [Array<Integer>] 'vms' - VMs filter
    # @option params [Float] 'balance' - New balance for User
    def IaaS_Gate params
        params['vms'] = params['vms'] || []
        showback = CalculateShowback(*params.get('uid', 'time'))

        user = onblock :u, params['uid']
        user.balance = params['balance']
        balance = user.balance
        alert, alert_at = user.alert

        return {
            'showback' => showback,
            'balance'  => balance,
            'alert'    => alert,
            'alert_at' => alert_at
        }
    rescue OpenNebula::VirtualMachine::ShowbackError => e
        return {
            'error'    => e.message,
            'time'     => e.params,
            'type'     => e.class
        }
    rescue OpenNebula::User::UserNotExistsError => e
        return {
            'error'    => e.message,
            'uid'      => params['uid'],
            'type'     => e.class
        }
    end
end
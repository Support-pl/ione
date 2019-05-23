begin
    $db.create_table :records do 
        primary_key :id, :integer, null: false
        String  :state, size: 10, null: false
        Integer :time, null: false
    end
rescue
    puts "Table :records already exists, skipping"
end

class IONe
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
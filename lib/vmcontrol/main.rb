########################################################
#            VM's and Users control methods            #
########################################################

puts 'Extending Handler class by commerce-useful methods'
class IONe
    # Suspends VirtualMachine and makes it uncontrollable for Owner(except Admins)
    # @param [Hash] params - income data
    # @option params [Integer] :vmid VirtualMachine ID for blocking
    # @param [Boolean] log - logs process if true
    # @param [Array<String>] trace
    # @return [NilClass | Array] Returns message and trace if Exception
    def Suspend params, log = true, trace = ["Suspend method called:#{__LINE__}"]
        trace << "Generating sys objects:#{__LINE__ + 1}"
        begin
            trace << "Printing debug info:#{__LINE__ + 1}"
            LOG "Suspending VM#{params['vmid']}", "Suspend" if log
            LOG "Params: #{params.inspect} | log = #{log}", "Suspend" if log
            trace << "Creating VM object:#{__LINE__ + 1}"
            onblock(:vm, params['vmid'].to_i) do | vm |
                r = vm.info!
                raise r if OpenNebula.is_error? r
                begin
                    trace << "Suspending VM:#{__LINE__ + 1}"
                    vm.suspend
                    trace << "Locking VM:#{__LINE__ + 1}"
                    vm.lock 2
                rescue
                    trace << "Some exception raised while suspending VM:#{__LINE__ - 2}"
                    LOG_AUTO "VM wasn't suspended, but rights will be changed" if log
                end
            end
            trace << "Killing proccess:#{__LINE__ + 1}"
            0
        rescue => e
            return e.message, trace
        end
    end
    # Suspends VirtualMachine only
    # @param [Integer] vmid - VirtualMachine ID
    # @return [NilClass]
    def SuspendVM(vmid)
        r = vm.info!
        raise r if OpenNebula.is_error? r
        onblock(:vm, vmid.to_i).suspend
    rescue => e
        return e.message
    end
    # Suspends all given users VMs
    # @param [Integer] uid - User ID
    # @param [Array] vms - VMs filter
    # @return [NilClass]
    def SuspendUser uid, vms = []
        LOG "Suspend Query for User##{uid} received", "Suspend"

        user = onblock :u, uid
        user.vms(@db).each do | vm |
            next if vms.include? vm.id
            begin
                LOG "Suspending VM##{vm.id}", "Suspend"
                vm.suspend
                LOG "Locking VM##{vm.id}", "Suspend"
                vm.lock 2
            rescue => e
                LOG "Error occured while suspending VM##{vm.id}\nCheck Debug log for error-codes and backtrace", "Suspend"
                LOG_DEBUG e.message
                LOG_DEBUG e.backtrace
            end
        end

        nil
    rescue => e
        return e.message
    end
    # Unsuspends VirtualMachine and makes it uncontrollable for Owner(except Admins)
    # @note May be used as PowerON method like {#Resume}
    # @param [Hash] params - income data
    # @option params [Integer] :vmid VirtualMachine ID for blocking
    # @param [Array<String>] trace
    # @return [nil | Array] Returns message and trace if Exception
    def Unsuspend(params, trace = ["Resume method called:#{__LINE__}"])
        result = 
            begin
                LOG "Resuming VM ##{params['vmid']}", "Resume"
                trace << "Creating VM object:#{__LINE__ + 1}"            
                onblock(:vm, params['vmid'].to_i) do | vm |
                    r = vm.info!
                    raise r if OpenNebula.is_error? r
                    trace << "Unlocking VM:#{__LINE__ + 1}"         
                    vm.unlock       
                    trace << "Resuming VM:#{__LINE__ + 1}"                
                    vm.resume
                end
                trace << "Killing proccess:#{__LINE__ + 1}"            
                0
            rescue => e
                [e.message, trace]
            end
        result
    end
    # Unsuspends all users VMs
    # @param [Integer] uid - User ID
    # @param [Array] vms - VMs filter
    # @return [NilClass]
    def UnsuspendUser uid, vms = []
        LOG "Unsuspend Query for User##{uid} received", "Unsuspend"

        user = onblock :u, uid
        user.vms(@db).each do | vm |
            next if vms.include? vm.id
            begin
                LOG "Unlocking VM##{vm.id}", "Unsuspend"
                vm.unlock
                LOG "Resuming VM##{vm.id}", "Unsuspend"
                vm.resume
            rescue => e
                LOG "Error occured while unsuspending VM##{vm.id}\nCheck Debug log for error-codes and backtrace", "Unsuspend"
                LOG_DEBUG e.message
                LOG_DEBUG e.backtrace
            end
        end

        nil
    rescue => e
        return e.message
    end
    # Reboots Virtual Machine
    # @param [Integer] vmid - VirtualMachine ID to reboot
    # @param [Boolean] hard - uses reboot-hard if true
    # @return nil
    def Reboot(vmid, hard = false)
        return "VMID cannot be nil!" if vmid.nil?     
        LOG "Rebooting VM#{vmid}", "Reboot"
        LOG "Params: vmid = #{vmid}, hard = #{hard}", "DEBUG" #if DEBUG
        vm = onblock :vm, vmid
        r = vm.info!
        raise r if OpenNebula.is_error? r
        vm.reboot(hard) # reboots 'hard' if true
    rescue => e
        return e.message
    end
    # Terminates(deletes) user account and VM
    # @param [Integer] userid - user to delete
    # @param [Integer] vmid - VM to delete
    # @return [nil | OpenNebula::Error]    
    def Terminate(userid, vmid)
        LOG "Terminate query call params: {\"userid\" => #{userid}, \"vmid\" => #{vmid}}", "Terminate"
        # If userid will be nil oneadmin account can be broken
        if userid == nil || vmid == nil then
            LOG "Terminate query rejected! 1 of 2 params is nilClass!", "Terminate"
            return 1
        elsif userid == 0 then
            LOG "Terminate query rejected! Tryed to delete root-user(oneadmin)", "Terminate"
        end
        Delete(userid)
        LOG "Terminating VM#{vmid}", "Terminate"
        vm = onblock(:vm, vmid)
        r = vm.info!
        raise r if OpenNebula.is_error? r
        Thread.new do
            begin
                rc = vm.resume
                raise rc if OpenNebula.is_error? rc
                vm.wait_for_state
            rescue
            ensure
                vm.recover(4)
                vm.wait_for_state 1, 0
                vm.terminate(true)
            end
        end
        true
    rescue => err
        return err.messages
    end
    # Powering off VM
    # @note Don't use OpenNebula::VirtualMachine#shutdown - thoose method deletes VM's
    # @param [Integer] vmid - VM to shutdown
    # @return [nil | OpenNebula::Error]
    def Shutdown(vmid)
        LOG "Shutting down VM#{vmid}", "Shutdown"
        vm = onblock :vm, vmid
        r = vm.info!
        raise r if OpenNebula.is_error? r
        vm.poweroff
    rescue => e
        return e.message
    end
    # @!visibility private
    # Releases hold-state VM
    def Release(vmid)
        LOG "New Release Order Accepted!", "Release"
        vm = onblock :vm, vmid
        r = vm.info!
        raise r if OpenNebula.is_error? r
        vm.release
    rescue => e
        return e.message
    end
    # Deletes given user by ID
    # @param [Integer] userid
    # @return [nil | OpenNebula::Error]
    def Delete(userid)
        if userid == 0 then
            LOG "Delete query rejected! Tryed to delete root-user(oneadmin)", "Delete"
        end
        LOG "Deleting User ##{userid}", "Delete"
        onblock(:u, userid).delete
    end
    # Powers On given VM if powered off, or unsuspends if suspended by ID
    # @param [Integer] vmid
    # @return [nil | OpenNebula::Error]
    def Resume(vmid, trial = false)
        onblock(:vm, vmid.to_i) do | vm |
            r = vm.info!
            raise r if OpenNebula.is_error? r
            vm.unschedule(0) if trial
            vm.resume
        end
    rescue => e
        return e.message
    end
    # Removes choosen snapshot for given VM
    # @param [Integer] vmid - VM ID
    # @param [Integer] snapid - Snapshot ID
    # @param [Boolean] log - Making no logs if false
    # @return [nil | OpenNebula::Error]
    def RMSnapshot(vmid, snapid, log = true)
        LOG "Deleting snapshot(ID: #{snapid.to_s}) for VM#{vmid.to_s}", "SnapController" if log
        onblock(:vm, vmid.to_i).snapshot_delete(snapid.to_i)
    end
    # Making new snapshot for given VM with given name
    # @param [Integer] vmid - VM ID
    # @param [String] name - Name for new VM
    # @param [Boolean] log - Making no logs if false
    # @return [Integer | OpenNebula::Error] New snapshot ID
    def MKSnapshot(vmid, name, log = true)
        LOG "Snapshot create-query accepted", 'SnapController' if log
        vm = onblock :vm, vmid
        r = vm.info!
        raise r if OpenNebula.is_error? r
        r = vm.snapshot_create(name)
        raise r if OpenNebula.is_error? r
        r
    rescue => e
        return e.message
    end
    # Reverts choosen snapshot for given VM
    # @param [Integer] vmid - VM ID
    # @param [Integer] snapid - Snapshot ID
    # @param [Boolean] log - Making no logs if false
    # @return [nil | OpenNebula::Error]
    def RevSnapshot(vmid, snapid, log = true)
        LOG "Snapshot revert-query accepted", 'SnapController' if log
        vm = onblock :vm, vmid
        r = vm.info!
        raise r if OpenNebula.is_error? r
        vm.snapshot_revert(snapid.to_i)
    rescue => e
        return e.message
    end
        
    def Unlock vmid, log = true
        LOG "VM Unlock query accepted" if log
        vm = onblock :vm, vmid
        r = vm.info!
        raise r if OpenNebula.is_error? r
        vm.unlock
    rescue => e
        return e.message
    end
    def Lock vmid, log = true
        LOG "VM Lock query accepted" if log
        vm = onblock :vm, vmid
        r = vm.info!
        raise r if OpenNebula.is_error? r
        vm.lock
    rescue => e
        return e.message
    end

    # temp
    # UPD: not really :)
    def SetVMResourcesLimits vmid, host, params
        PostDeployActivities.new(@client).LimitsController(params, vmid, onblock(:h, host))
    end
end

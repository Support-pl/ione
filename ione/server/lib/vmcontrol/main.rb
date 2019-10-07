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
    def Suspend(params, log = true, trace = ["Suspend method called:#{__LINE__}"])
        trace << "Generating sys objects:#{__LINE__ + 1}"
        LOG_STAT()
        id = id_gen()
        LOG_CALL(id, true, __method__)
        defer { LOG_CALL(id, false, 'Suspend') }
        begin
            trace << "Printing debug info:#{__LINE__ + 1}"
            LOG "Suspending VM#{params['vmid']}", "Suspend" if log
            LOG "Params: #{params.inspect} | log = #{log}", "Suspend" if log
            trace << "Creating VM object:#{__LINE__ + 1}"
            onblock(VirtualMachine, params['vmid'].to_i) do | vm |
                begin
                    trace << "Suspending VM:#{__LINE__ + 1}"
                    vm.suspend
                rescue
                    trace << "Some exception raised while suspending VM:#{__LINE__ - 2}"
                    LOG_AUTO "VM wasn't suspended, but rights will be changed" if log
                end
                trace << "Changing user rights:#{__LINE__ + 1}"
                vm.chmod(
                    -1,  0, -1,
                    -1, -1, -1,
                    -1, -1, -1
                    )
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
        onblock(VirtualMachine, vmid.to_i).suspend
    end
    # Suspends all given users VMs
    # @param [Integer] uid - User ID
    # @param [Array] vms - VMs filter
    # @return [NilClass]
    def SuspendUser uid, vms = []
        LOG_STAT()
        id = id_gen()
        LOG_CALL(id, true, __method__)
        defer { LOG_CALL(id, false, 'SuspendUser') }
        LOG "Suspend Query for User##{uid} received", "Suspend"

        user = onblock :u, uid
        user.vms(@db).each do | vm |
            next if vms.include? vm.id
            begin
                LOG "Suspending VM##{vm.id}", "Suspend"
                vm.chmod(
                    -1,  0, -1,
                    -1, -1, -1,
                    -1, -1, -1  )
                vm.suspend
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
        LOG_STAT()
        id = id_gen()
        LOG_CALL(id, true, __method__)
        defer { LOG_CALL(id, false, 'Unsuspend') }
        result = 
            begin
                LOG "Resuming VM ##{params['vmid']}", "Resume"
                trace << "Creating VM object:#{__LINE__ + 1}"            
                onblock(VirtualMachine, params['vmid'].to_i) do | vm |
                    trace << "Resuming VM:#{__LINE__ + 1}"                
                    vm.resume
                    trace << "Changing user rights:#{__LINE__ + 1}"                
                    vm.chmod(
                        -1,  1, -1,
                        -1, -1, -1,
                        -1, -1, -1
                    )
                end
                trace << "Killing proccess:#{__LINE__ + 1}"            
                0
            rescue => e
                return e.message, trace
            end
        result
    end
    # Unsuspends all users VMs
    # @param [Integer] uid - User ID
    # @param [Array] vms - VMs filter
    # @return [NilClass]
    def UnsuspendUser uid, vms = []
        LOG_STAT()
        id = id_gen()
        LOG_CALL(id, true, __method__)
        defer { LOG_CALL(id, false, 'UnsuspendUser') }
        LOG "Unsuspend Query for User##{uid} received", "Unsuspend"

        user = onblock :u, uid
        user.vms(@db).each do | vm |
            next if vms.include? vm.id
            begin
                LOG "Unsuspending VM##{vm.id}", "Unsuspend"
                vm.chmod(
                    1,  1, 1,
                    -1, -1, -1,
                    -1, -1, -1  )
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
        LOG_STAT()
        id = id_gen()
        LOG_CALL(id, true, __method__)
        defer { LOG_CALL(id, false, 'Reboot') }
                  
        return "VMID cannot be nil!" if vmid.nil?     
        LOG "Rebooting VM#{vmid}", "Reboot"
        LOG "Params: vmid = #{vmid}, hard = #{hard}", "DEBUG" #if DEBUG
        onblock(VirtualMachine, vmid.to_i).reboot(hard) # reboots 'hard' if true
    end
    # Terminates(deletes) user account and VM
    # @param [Integer] userid - user to delete
    # @param [Integer] vmid - VM to delete
    # @return [nil | OpenNebula::Error]    
    def Terminate(userid, vmid)
        LOG_STAT()
        id = id_gen()
        LOG_CALL(id, true, __method__)
        defer { LOG_CALL(id, false, 'Terminate') }
                  
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
        Thread.new do
            vm = onblock(:vm, vmid)
            begin
                rc = vm.resume
                raise rc if rc.class == OpenNebula::Error
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
        return err
    end
    # Powering off VM
    # @note Don't user OpenNebula::VirtualMachine#shutdown - this method deletes VM's
    # @param [Integer] vmid - VM to shutdown
    # @return [nil | OpenNebula::Error]
    def Shutdown(vmid)
        LOG_STAT()
        id = id_gen()
        LOG_CALL(id, true, __method__)
        defer { LOG_CALL(id, false, 'Shutdown') }
                
        LOG "Shutting down VM#{vmid}", "Shutdown"
        onblock(VirtualMachine, vmid).poweroff
    end
    # @!visibility private
    # Releases hold-state VM
    def Release(vmid)
        LOG_STAT()
        id = id_gen()
        LOG_CALL(id, true, __method__)
        defer { LOG_CALL(id, false, 'Release') }

        LOG "New Release Order Accepted!", "Release"
        onblock(VirtualMachine, vmid).release
    end
    # Deletes given user by ID
    # @param [Integer] userid
    # @return [nil | OpenNebula::Error]
    def Delete(userid)
        LOG_STAT()
        id = id_gen()
        LOG_CALL(id, true, __method__)
        defer { LOG_CALL(id, false, 'Delete') }

        if userid == 0 then
            LOG "Delete query rejected! Tryed to delete root-user(oneadmin)", "Delete"
        end
        LOG "Deleting User ##{userid}", "Delete"
        onblock(User, userid).delete
    end
    # Powers On given VM if powered off, or unsuspends if suspended by ID
    # @param [Integer] vmid
    # @return [nil | OpenNebula::Error]
    def Resume(vmid, trial = false)
        LOG_STAT()
        id = id_gen()
        LOG_CALL(id, true, __method__)
        defer { LOG_CALL(id, false, 'Resume') }

        onblock(VirtualMachine, vmid.to_i) do | vm |
            vm.unschedule(0) if trial
            vm.resume
        end
    end
    # Removes choosen snapshot for given VM
    # @param [Integer] vmid - VM ID
    # @param [Integer] snapid - Snapshot ID
    # @param [Boolean] log - Making no logs if false
    # @return [nil | OpenNebula::Error]
    def RMSnapshot(vmid, snapid, log = true)
        LOG_STAT()
        id = id_gen()
        LOG_CALL(id, true, __method__)
        defer { LOG_CALL(id, false, 'RMSnapshot') }

        LOG "Deleting snapshot(ID: #{snapid.to_s}) for VM#{vmid.to_s}", "SnapController" if log
        onblock(VirtualMachine, vmid.to_i).snapshot_delete(snapid.to_i)
    end
    # Making new snapshot for given VM with given name
    # @param [Integer] vmid - VM ID
    # @param [String] name - Name for new VM
    # @param [Boolean] log - Making no logs if false
    # @return [Integer | OpenNebula::Error] New snapshot ID
    def MKSnapshot(vmid, name, log = true)
        LOG_STAT()
        id = id_gen()
        LOG_CALL(id, true, __method__)
        defer { LOG_CALL(id, false, 'MKSnapshot') }

        LOG "Snapshot create-query accepted", 'SnapController' if log
        onblock(VirtualMachine, vmid.to_i).snapshot_create(name)
    end
    # Reverts choosen snapshot for given VM
    # @param [Integer] vmid - VM ID
    # @param [Integer] snapid - Snapshot ID
    # @param [Boolean] log - Making no logs if false
    # @return [nil | OpenNebula::Error]
    def RevSnapshot(vmid, snapid, log = true)
        LOG_STAT()
        id = id_gen()
        LOG_CALL(id, true, __method__)
        defer { LOG_CALL(id, false, 'RevSnapshot') }
        
        LOG "Snapshot revert-query accepted", 'SnapController' if log
        onblock(VirtualMachine, vmid.to_i).snapshot_revert(snapid.to_i)
    end

    # temp
    def SetVMResourcesLimits vmid, host, params
        PostDeployActivities.new(@client).LimitsController(params, vmid, host)
    end
end
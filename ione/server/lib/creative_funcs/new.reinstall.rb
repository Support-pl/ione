    # Creates VM for Old OpenNebula account and with old IP address
    # @param [Hash] params - all needed data for VM reinstall
    # @option params [Integer] :vmid - VirtualMachine for Reinstall ID
    # @option params [Integer] :userid - new Virtual Machine owner
    # @option params [String] :username - Administrator username for Windows Machines
    # @option params [String] :passwd Password for new Virtual Machine 
    # @option params [Integer] :templateid - templateid for Instantiate
    # @option params [Integer] :cpu vCPU cores amount for new VM
    # @option params [Integer] :iops IOPS limit for new VM's drive 
    # @option params [String] :units Units for RAM and drive size, can be 'MB' or 'GB'
    # @option params [Integer] :ram RAM size for new VM
    # @option params [Integer] :drive Drive size for new VM
    # @option params [String] :ds_type VM deploy target datastore drives type, 'SSD' ot 'HDD'
    # @option params [Bool] :release (false) VM will be started on HOLD if false
    # @param [Array<String>] trace - public trace log
    # @return [Hash, nil, String] 
    # @example Example out
    #   Success: { 'vmid' => 124, 'vmid_old' => 123, 'ip' => '0.0.0.0', 'ip_old' => '0.0.0.0' }
    #   Some params not given: String('ReinstallError - some params are nil')
    #   Debug turn method off: nil
    #   Debug return fake data: { 'vmid' => rand(params['vmid'].to_i + 1000), 'vmid_old' => params['vmid'], 'ip' => '0.0.0.0', 'ip_old' => '0.0.0.0' } 
    def Reinstall(params, trace = ["Reinstall method called:#{__LINE__}"])
        LOG_STAT()
        id = id_gen()
        LOG_CALL(id, true)
        defer { LOG_CALL(id, false, 'Reinstall') }
            LOG_DEBUG params.merge!({ :method => 'Reinstall' }).debug_out
            return nil if params['debug'] == 'turn_method_off'
            return { 'vmid' => rand(params['vmid'].to_i + 1000), 'vmid_old' => params['vmid'], 'ip' => '0.0.0.0', 'ip_old' => '0.0.0.0' } if params['debug'] == 'data'   

            LOG "Reinstalling VM#{params['vmid']}", 'Reinstall'
            trace << "Checking params:#{__LINE__ + 1}"
            if params.get('vmid', 'groupid', 'userid', 'templateid').include?(nil) then
                LOG "ReinstallError - some params are nil", 'Reinstall'
                return "ReinstallError - some params are nil"
            end
            params['vmid'], params['groupid'], params['userid'], params['templateid'] = params.get('vmid', 'groupid', 'userid', 'templateid').map { |el| el.to_i }
            
            params['cpu'], params['ram'], params['drive'], params['iops'] = params.get('cpu', 'ram', 'drive', 'iops').map { |el| el.to_i }
            
            begin
                params['iops'] = CONF['vCenter']['drive-types'][params['ds_type']]
                LOG_DEBUG "IOps: #{params['iops'].class.to_s}(#{params['iops']})"
            rescue
                LOG_DEBUG "No vCenter configuration found"
            end
            
            params['username'] = params['username'] || 'Administrator'
            

            LOG_DEBUG 'Initializing vm object'
            trace << "Initializing old VM object:#{__LINE__ + 1}"            
            vm = onblock(VirtualMachine, params['vmid'])
            LOG_DEBUG 'Collecting data from old template'
            trace << "Collecting data from old template:#{__LINE__ + 1}"            
            nics = vm.to_hash!['VM']['TEMPLATE']['NIC']
            if nics.class == Hash then
                nics = [ nics ]
            elsif nics.class == NilClass then
                nics = :no
            end

            LOG_DEBUG 'Initializing template obj'
            LOG_DEBUG 'Generating new template'
            trace << "Generating NIC context:#{__LINE__ + 1}"
            context = ""
            nics.each do | nic |
                context += "NIC = [\n\tIP=\"#{nic['IP']}\",\n\tNETWORK=\"#{nic['NETWORK']}\",\n\tNETWORK_UNAME=\"#{nic['NETWORK_UNAME']}\"\n]\n"
            end unless nics == :no
            trace << "Generating template object:#{__LINE__ + 1}"            
            template = onblock(Template, params['templateid'])
            template.info!
            trace << "Checking OS type:#{__LINE__ + 1}"            
            win = template.win?
            trace << "Generating credentials and network context:#{__LINE__ + 1}"
            context += "CONTEXT = [\n\tPASSWORD=\"#{params['passwd']}\",\n\tNETWORK=\"YES\"#{ win ? ",\n\tUSERNAME = \"#{params['username']}\"" : nil}\t]\n"
            # context += "CONTEXT = [\n\tPASSWORD=\"#{params['passwd']}\",\n\tETH0_IP=\"#{nic['IP']}\",\n\tETH0_GATEWAY=\"#{nic['GATEWAY']}\",\n\tETH0_DNS=\"#{nic['DNS']}\",\n\tNETWORK=\"YES\"#{ win ? ",\n\tUSERNAME = \"#{params['username']}\"" : nil}\t]\n"
            trace << "Generating specs configuration:#{__LINE__ + 1}"
            context +=  "VCPU = #{params['cpu'] == 0 ? vm['/VM/TEMPLATE/VCPU'] : params['cpu']}\n" \
                        "MEMORY = #{params['ram'] == 0 ? vm['/VM/TEMPLATE/MEMORY'] : params['ram'] * (params['units'] == 'GB' ? 1024 : 1)}\n" \
                        "DISK = [ \n" \
                        "IMAGE_ID = \"#{template.to_hash['VMTEMPLATE']['TEMPLATE']['DISK']['IMAGE_ID']}\",\n" \
                        "SIZE = \"#{params['drive'] * (params['units'] == 'GB' ? 1024 : 1)}\",\n" \
                        "OPENNEBULA_MANAGED = \"NO\"\t]"
            LOG_DEBUG "Resulting capacity template:\n#{context}"
            
            trace << "Terminating VM:#{__LINE__ + 1}"            
            vm.terminate(true)
            LOG_COLOR 'Waiting until terminate process will over', 'Reinstall', 'light_yellow'
            trace << ":#{__LINE__ + 1}"            
            until STATE_STR(params['vmid']) == 'DONE' do
                sleep(0.2)
            end if params['release']
            LOG_COLOR "Terminate process is over, new VM is deploying now", 'Reinstall', 'green'
            LOG_DEBUG 'Creating new VM'
            trace << "Instantiating template:#{__LINE__ + 1}"
            vmid = template.instantiate(
                ( params['login'] || onblock(:u, params['userid']){ |u| u.info!; u.name }) + '_vm', false, context)

            LOG_DEBUG "New VM ID or an OpenNebula::Error: #{begin vmid.to_str rescue vmid.to_s end}"
            begin    
                if vmid.class != Fixnum && vmid.include?('IP/MAC') then
                    trace << "Retrying template instantiation:#{__LINE__ + 1}"                
                    sleep(3)
                    vmid = template.instantiate(params['login'] + '_vm', false, context)
                end
            rescue => e
                return vmid, vmid.class, vmid.message if vmid.class != Fixnum
                return vmid, vmid.class
            end           

            return vmid.message if vmid.class != Fixnum

            trace << "Changing VM owner:#{__LINE__ + 1}"
            onblock(:vm, vmid).chown(params['userid'], USERS_GROUP)

            #####   PostDeploy Activity define   #####
            Thread.new do

                host = params['host'].nil? ? $default_host : params['host']

                onblock(:vm, vmid) do | vm |
                    LOG_DEBUG 'Deploying VM to the host'
                    vm.deploy(host, false, ChooseDS(params['ds_type']))
                    LOG_DEBUG 'Waiting until VM will be deployed'
                    vm.wait_for_state
                end

                postDeploy = PostDeployActivities.new @client

                #LimitsController

                LOG_DEBUG "Executing LimitsController for VM#{vmid} | Cluster type: #{ClusterType(host)}"
                trace << "Executing LimitsController for VM#{vmid} | Cluster type: #{ClusterType(host)}:#{__LINE__ + 1}"
                postDeploy.LimitsController(params, vmid, host)

                #endLimitsController
                #TrialController
                if params['trial'] then
                    trace << "Creating trial counter thread:#{__LINE__ + 1}"
                    postDeploy.TrialController(params, vmid, host)
                end
                #endTrialController
                #AnsibleController
                
                if params['ansible'] && params['release'] then
                    trace << "Creating Ansible Installer thread:#{__LINE__ + 1}"
                    postDeploy.AnsibleController(params, vmid, host)
                end

                #endAnsibleController

            end if params['release']
            ##### PostDeploy Activity define END #####

            return { 'vmid' => vmid, 'vmid_old' => params['vmid'], 'ip' => GetIP(vmid) }
        rescue => e
            LOG_ERROR "Error ocurred while Reinstall: #{e.message}"
            return e.message, trace
    end
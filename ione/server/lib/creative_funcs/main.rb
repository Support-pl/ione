class IONe
    def sleep_test(timeout)
        sleep(timeout)
        return 'DONE'
    end
    # Creates new user account
    # @param [String]   login       - login for new OpenNebula User
    # @param [String]   pass        - password for new OpenNebula User
    # @param [Integer]  groupid     - Secondary group for new user
    # @param [OpenNebula::Client] client
    # @param [Boolean]  object      - Returns userid of the new User and object of new User
    # @param [String]   locale      - Sets given locale for Sunstone
    # @return [Integer | Integer, OpenNebula::User]
    # @example Examples
    #   Success:                    777
    #       Object set to true:     777, OpenNebula::User(777)
    #   Error:                      "[one.user.allocation] Error ...", maybe caused if user with given name already exists
    #   Error:                      0
    def UserCreate(login, pass, groupid = nil, locale = nil, client:@client, object:false, type:'vcenter')
        id = id_gen()
        LOG_CALL(id, true)
        defer { LOG_CALL(id, false, 'UserCreate') }
        user = User.new(User.build_xml(0), client) # Generates user template using oneadmin user object
        allocation_result =
            begin
                user.allocate(login, pass, "core", groupid.nil? ? [USERS_GROUP] : [groupid]) # Allocating new user with login:pass
            rescue => e
                e.message
            end
        if !allocation_result.nil? then
            LOG_DEBUG allocation_result.message #If allocation was successful, allocate method returned nil
            return 0
        end
        attributes = "SUNSTONE=[ LANG=\"#{locale || CONF['OpenNebula']['users-default-lang']}\" ]"
        attributes += "AZURE_TOKEN=\"#{login}\"" if type == 'azure'
        attributes += "BALANCE=\"0\"\nLABELS=\"IaaS\"" if groupid.to_i == $db[:settings].where(:name => 'IAAS_GROUP_ID').to_a.last[:body].to_i
        user.update(attributes, true)
        return user.id, user if object
        user.id
    end
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
            nic, context = vm.to_hash!['VM']['TEMPLATE']['NIC'], vm.to_hash['VM']['TEMPLATE']['CONTEXT']
            
            LOG_DEBUG 'Initializing template obj'
            LOG_DEBUG 'Generating new template'
            trace << "Generating NIC context:#{__LINE__ + 1}"
            context = "NIC = [\n\tIP=\"#{nic['IP']}\",\n\tDNS=\"#{nic['DNS']}\",\n\tGATEWAY=\"#{nic['GATEWAY']}\",\n\tNETWORK=\"#{nic['NETWORK']}\",\n\tNETWORK_UNAME=\"#{nic['NETWORK_UNAME']}\"\n]\n"
            trace << "Generating template object:#{__LINE__ + 1}"            
            template = onblock(Template, params['templateid'])
            template.info!
            trace << "Checking OS type:#{__LINE__ + 1}"            
            win = template.win?
            trace << "Generating credentials and network context:#{__LINE__ + 1}"
            context += "CONTEXT = [\n\tPASSWORD=\"#{params['passwd']}\",\n\tETH0_IP=\"#{nic['IP']}\",\n\tETH0_GATEWAY=\"#{nic['GATEWAY']}\",\n\tETH0_DNS=\"#{nic['DNS']}\",\n\tNETWORK=\"YES\"#{ win ? ",\n\tUSERNAME = \"#{params['username']}\"" : nil}\t]\n"
            trace << "Generating specs configuration:#{__LINE__ + 1}"
            context += "VCPU = #{params['cpu']}\n" \
                        "MEMORY = #{params['ram'] * (params['units'] == 'GB' ? 1024 : 1)}\n" \
                        "DISK = [ \n" \
                        "IMAGE_ID = \"#{template.to_hash['VMTEMPLATE']['TEMPLATE']['DISK']['IMAGE_ID']}\",\n" \
                        "SIZE = \"#{params['drive'] * (params['units'] == 'GB' ? 1024 : 1)}\",\n" \
                        "OPENNEBULA_MANAGED = \"NO\"\t]" \
                        "DRIVE = \"#{params['ds_type']}\""
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

                #LOG_DEBUG "Executing LimitsController for VM#{vmid} | Cluster type: #{ClusterType(host)}"
                #trace << "Executing LimitsController for VM#{vmid} | Cluster type: #{ClusterType(host)}:#{__LINE__ + 1}"
                #postDeploy.LimitsController(params, vmid, host)

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

            return { 'vmid' => vmid, 'vmid_old' => params['vmid'], 'ip' => GetIP(vmid), 'ip_old' => nic['IP'] }
        rescue => e
            LOG_ERROR "Error ocurred while Reinstall: #{e.message}"
            return e.message, trace
    end
    # Creates new virtual machine from the given OS template and resize it to given specs, and new user account, which becomes owner of this VM 
    # @param [Hash] params - all needed data for new User and VM creation
    # @option params [String] :login Username for new OpenNebula account
    # @option params [String] :password Password for new OpenNebula account
    # @option params [String] :passwd Password for new Virtual Machine 
    # @option params [Integer] :templateid Template ID to instantiate
    # @option params [Integer] :cpu vCPU cores amount for new VM
    # @option params [Integer] :iops IOPS limit for new VM's drive 
    # @option params [String] :units Units for RAM and drive size, can be 'MB' or 'GB'
    # @option params [Integer] :ram RAM size for new VM
    # @option params [Integer] :drive Drive size for new VM
    # @option params [String] :ds_type VM deploy target datastore drives type, 'SSD' or 'HDD'
    # @option params [Integer] :groupid Additional group, in which user should be
    # @option params [Boolean] :trial (false) VM will be suspended after TRIAL_SUSPEND_DELAY
    # @option params [Boolean] :release (false) VM will be started on HOLD if false
    # @option params [String]  :user-template Addon template, you may append to default template(Use XML-string as OpenNebula requires)
    # @param [Array<String>] trace - public trace log
    # @return [Hash, nil] UserID, VMID and IP address if success, or error message and backtrace log if error
    # @example Example out
    #   Success: {'userid' => 777, 'vmid' => 123, 'ip' => '0.0.0.0'}
    #   Debug is set to true: nil
    #   Template not found Error: {'error' => "TemplateLoadError", 'trace' => (trace << "TemplateLoadError:#{__LINE__ - 1}")(Array<String>)}
    #   User create Error: {'error' => "UserAllocateError", 'trace' => trace(Array<String>)}
    #   Unknown error: { 'error' => e.message, 'trace' => trace(Array<String>)} 
    def CreateVMwithSpecs(params, trace = ["#{__method__.to_s} method called:#{__LINE__}"])
        LOG_STAT()
        LOG_CALL(id = id_gen(), true, __method__)
        defer { LOG_CALL(id, false, 'CreateVMwithSpecs') }
        LOG_DEBUG params.merge!(:method => __method__.to_s).debug_out
        # return {'userid' => 6666, 'vmid' => 6666, 'ip' => '127.0.0.1'}
        trace << "Checking params types:#{__LINE__ + 1}"
            
            
        params['cpu'], params['ram'], params['drive'], params['iops'] = params.get('cpu', 'ram', 'drive', 'iops').map { |el| el.to_i }

        begin
            params['iops'] = params['iops'] == 0 ? CONF['vCenter']['drive-types'][params['ds-type']] : params['iops']
        rescue
            LOG_DEBUG "No vCenter configuration found"
        end

        params['username'] = params['username'] || 'Administrator'
        params['extra'] = params['extra'] || {'type' => 'vcenter'}
        ###################### Doing some important system stuff ###############################################################
        
        return nil if DEBUG
        LOG_TEST "CreateVMwithSpecs for #{params['login']} Order Accepted! #{params['trial'] == true ? "VM is Trial" : nil}"
        
        LOG_DEBUG "Params: #{params.out}"
        
        trace << "Checking template:#{__LINE__ + 1}"
        onblock(:t, params['templateid']) do | t |
            result = t.info!
            if params['templateid'] == 0 || result != nil then
                LOG_ERROR "Error: TemplateLoadError" 
                return {'error' => "TemplateLoadError", 'trace' => (trace << "TemplateLoadError:#{__LINE__ - 1}")}
            end
        end
            
        #####################################################################################################################
        
        #####   Initializing useful variables   #####
        userid, vmid = 0, 0
        ##### Initializing useful variables END #####
        
        
        #####   Creating new User   #####
        LOG_TEST "Creating new user for #{params['login']}"
        if params['nouser'].nil? || !params['nouser'] then
            trace << "Creating new user:#{__LINE__ + 1}"
            userid, user =
                UserCreate(
                    params['login'], params['password'], USERS_GROUP, object:true,
                    type: params['extra']['type'] ) if params['test'].nil?
            LOG_ERROR "Error: UserAllocateError" if userid == 0
            trace << "UserAllocateError:#{__LINE__ - 2}" if userid == 0
            return {'error' => "UserAllocateError", 'trace' => trace} if userid == 0
        else
            userid, user = params['userid'], onblock(:u, params['userid'])
        end
        params['user_id'] = userid
        LOG_TEST "New User account created"

        ##### Creating new User END #####
        
        #####   Creating and Configuring VM   #####
        LOG_TEST "Creating VM for #{params['login']}"
        trace << "Creating new VM:#{__LINE__ + 1}"
        onblock(:t, params['templateid']) do | t |
            t.info!
            specs = ""
            if !t['/VMTEMPLATE/TEMPLATE/CAPACITY'] && t['/VMTEMPLATE/TEMPLATE/HYPERVISOR'].upcase == "VCENTER" then
                specs = "VCPU = #{params['cpu']}\n" \
                        "MEMORY = #{params['ram'] * (params['units'] == 'GB' ? 1024 : 1)}\n" \
                        "DISK = [ \n" \
                        "IMAGE_ID = \"#{t.to_hash['VMTEMPLATE']['TEMPLATE']['DISK']['IMAGE_ID']}\",\n" \
                        "SIZE = \"#{params['drive'] * (params['units'] == 'GB' ? 1024 : 1)}\",\n" \
                        "OPENNEBULA_MANAGED = \"NO\"\t]" \
                        "DRIVE = \"#{params['ds_type']}\""
            elsif t['/VMTEMPLATE/TEMPLATE/HYPERVISOR'] == 'AZURE' then
                specs = "OS_DISK_SIZE = \"#{params['drive']}\"\n" \
                        "SIZE = \"#{params['extra']['instance_size']}\"\n" \
                        "VM_USER_NAME = \"#{params['username']}\"\n" \
                        "PASSWORD = \"#{params['passwd']}\"\n" \
                        "VCPU = #{params['cpu']}\n" \
                        "MEMORY = #{params['ram'] * (params['units'] == 'GB' ? 1024 : 1)}\n"
            end
            trace << "Updating user quota:#{__LINE__ + 1}"
            user.update_quota_by_vm(
                'append' => true, 'cpu' => params['cpu'],
                'ram' => params['ram'] * (params['units'] == 'GB' ? 1024 : 1),
                'drive' => params['drive'] * (params['units'] == 'GB' ? 1024 : 1)
            ) unless t['/VMTEMPLATE/TEMPLATE/CAPACITY'] == 'FIXED'
            LOG_DEBUG "Resulting capacity template:\n" + specs
            vmid = t.instantiate("#{params['login']}_vm", true, specs + "\n" + params['user-template'].to_s)
        end

        raise "Template instantiate Error: #{vmid.message}" if vmid.class != Fixnum
        
        host =  if params['host'].nil? then
                    JSON.parse(@db[:settings].as_hash(:name, :body)['NODES_DEFAULT'])[params['extra']['type'].upcase]
                else
                    params['host']
                end

        LOG_TEST 'Configuring VM Template'
        trace << "Configuring VM Template:#{__LINE__ + 1}"            
        onblock(:vm, vmid) do | vm |
            trace << "Changing VM owner:#{__LINE__ + 1}"
            begin
                r = vm.chown(userid, USERS_GROUP)
                raise r.message unless r.nil?
            rescue
                LOG_DEBUG "CHOWN error, params: #{userid}, #{vm}"
            end

            if params['extra']['type'] == 'vcenter' then
                win = onblock(:t, params['templateid']).win?
                LOG_DEBUG "Instantiating VM as#{win ? nil : ' not'} Windows"
                trace << "Setting VM context:#{__LINE__ + 2}"
                begin
                    vm.updateconf(
                        "CONTEXT = [ NETWORK=\"YES\", PASSWORD = \"#{params['passwd']}\", SSH_PUBLIC_KEY = \"$USER[SSH_PUBLIC_KEY]\"#{ win ? ", USERNAME = \"#{params['username']}\"" : nil} ]"
                    )
                rescue => e
                    LOG_DEBUG "Context configuring error: #{e.message}"
                end

                trace << "Setting VM VNC settings:#{__LINE__ + 2}"
                begin
                    vm.updateconf(
                        "GRAPHICS = [ LISTEN=\"0.0.0.0\", PORT=\"#{(CONF['OpenNebula']['base-vnc-port'] + vmid).to_s}\", TYPE=\"VNC\" ]"
                    ) # Configuring VNC
                rescue => e
                    LOG_DEBUG "VNC configuring error: #{e.message}"
                end
            end

            if params['extra']['type'] == 'vcenter' then
                trace << "Deploying VM:#{__LINE__ + 1}"
                vm.deploy(host, false, ChooseDS(params['ds_type']))
            else
                trace << "Deploying VM:#{__LINE__ + 1}"
                vm.deploy(host, false)
            end if params['release']
            # vm.deploy($default_host, false, params['datastore'].nil? ? ChooseDS(params['ds_type']): params['datastore']) if params['release']
        end
            ##### Creating and Configuring VM END #####            

            #####   PostDeploy Activity define   #####
        Thread.new do

            LOG_DEBUG "Starting PostDeploy Activities for VM#{vmid}"
                
            onblock(:vm, vmid).wait_for_state

            LOG_DEBUG "VM is active now, let it go"

            postDeploy = PostDeployActivities.new @client

            #LimitsController

            #LOG_DEBUG "Executing LimitsController for VM#{vmid} | Cluster type: #{ClusterType(host)}"
            #trace << "Executing LimitsController for VM#{vmid} | Cluster type: #{ClusterType(host)}:#{__LINE__ + 1}"
            #postDeploy.LimitsController(params, vmid, host)

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

        LOG_TEST 'Post-Deploy joblist defined, basic installation job ended'
        return out = {'userid' => userid, 'vmid' => vmid, 'ip' => GetIP(vmid)}
    rescue => e
        out = { :exception => e.message, :trace => trace << 'END_TRACE' }
        LOG_DEBUG out.debug_out
        return out
    end
    def ReinstallTestMethod(params, vmid)
        postDeploy = PostDeployActivities.new @client
        #####   PostDeploy Activity define   #####

            host = params['host'].nil? ? $default_host : params['host']

            #AnsibleController
            
            if params['ansible'] && params['release'] then
                postDeploy.AnsibleController(params, vmid, host)
            end

            #endAnsibleController

        ##### PostDeploy Activity define END #####
    rescue => e
        return e.message
    end
    # Class for pst-deploy activities methods
    #   All methods will receive creative methods params, new vm ID, and host, where VM was deployed
    class PostDeployActivities
        def initialize client
            @ione = IONe.new(client, $db)
        end
        include Deferable
        # Executes given playbooks at fresh-deployed vm
        def AnsibleController(params, vmid, host = nil)
            LOG_CALL(id = id_gen(), true, __method__)
            onblock(:vm, vmid).wait_for_state
            sleep(60)
            unless params['ansible_local_id'].nil? then
                LOG_DEBUG "Ansible Local ID: #{params['ansible_local_id']}"
                LOG_DEBUG('Starting process')
                install_process =
                AnsiblePlaybookProcess.new(
                    playbook_id:    params['ansible_local_id'],
                    uid:            params['userid'],
                    hosts:          { vmid => ["#{@ione.GetIP(vmid)}:#{CONF['OpenNebula']['users-vms-ssh-port']}"]}, #!!!
                    vars:           params['ansible_vars'],
                    comment:        "Post-Deploy Activity - Ansible",
                    auth:           'default'
                )
                LOG_DEBUG "Proc ID #{install_process.install_id}"
                install_process.run
                LOG_DEBUG "Runned"
                params['ansible-service']
            else
                LOG_DEBUG "Starting not local playbook"
                Thread.new do
                    @ione.AnsibleController(params.merge({
                        'super' => '', 'host' => "#{@ione.GetIP(vmid)}:#{CONF['OpenNebula']['users-vms-ssh-port']}", 'vmid' => vmid
                    }))
                end
            end
            LOG_COLOR "Install-thread started, you should wait until the #{params['ansible-service']} will be installed", 'AnsibleController', 'light_yellow'
        rescue => e
            LOG_DEBUG e.message
            LOG_DEBUG e.backtrace
        ensure
            LOG_CALL(id, false, 'AnsibleController')
        end
        # If Cluster type is vCenter, sets up Limits at the node
        def LimitsController(params, vmid, host = nil)
            LOG_CALL(id = id_gen(), true, __method__)
            defer { LOG_CALL(id, false, 'LimitsController') }
            onblock(:vm, vmid) do | vm |
                lim_res = vm.setResourcesAllocationLimits(
                    cpu: params['cpu'] * CONF['vCenter']['cpu-limits-koef'], ram: params['ram'] * (params['units'] == 'GB' ? 1024 : 1), iops: params['iops']
                )
                unless lim_res.nil? then
                    err, back = lim_res.split("<|>")
                    LOG_ERROR "Limits was not set, error: #{err}"
                    LOG_DEBUG "Limits was not set, error: #{err}\n#{back}"
                end
            end if ClusterType(host) == 'vcenter'
        end
        # If VM is trial, starts time and schedule suspend method
        def TrialController(params, vmid, host = nil)
            LOG_CALL(id = id_gen(), true, __method__)        
            LOG "VM #{vmid} suspend action scheduled", 'TrialController'
            action_time = Time.now.to_i + ( params['trial-suspend-delay'].nil? ?
                                TRIAL_SUSPEND_DELAY :
                                params['trial-suspend-delay'] )
            onblock(:vm, vmid).wait_for_state
            if !onblock(:vm, vmid).schedule('suspend', action_time).nil? then
                LOG_ERROR 'Scheduler process error', 'TrialController'
            end
            LOG_CALL(id, false, 'TrialController')
        end
    
        deferable :LimitsController
    end
end

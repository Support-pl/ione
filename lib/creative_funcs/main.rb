class IONe
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
  def UserCreate(login, pass, groupid = nil, locale = nil, client: @client, object: false, type: 'vcenter')
    user = User.new(User.build_xml(0), client) # Generates user template using oneadmin user object
    allocation_result =
      begin
        user.allocate(login, pass, "core", groupid.nil? ? [IONe::Settings['USERS_GROUP']] : [groupid]) # Allocating new user with login:pass
      rescue => e
        e.message
      end
    if !allocation_result.nil? then
      LOG_DEBUG allocation_result.message # If allocation was successful, allocate method returned nil
      return 0
    end

    attrs = {
      SUNSTONE: {
        LANG: locale || IONe::Settings['USERS_DEFAULT_LANG'] || 'en_US'
      }
    }
    attrs['AZURE_TOKEN'] = login if type == 'azure'
    attrs.merge! BALANCE: 0, LABELS: "IaaS" if groupid.to_i == IONe::Settings['IAAS_GROUP_ID']

    user.update(attrs.to_one_template, true)
    return user.id, user if object

    user.id
  end

  # Recreates VM with same NICs for same user
  # @param [Hash] params - all needed data for VM reinstall
  # @option params [Integer] :vmid VirtualMachine for Reinstall ID
  # @option params [Integer] :userid new Virtual Machine owner
  # @option params [Integer] :groupid new Virtual Machine group
  # @option params [String] :username Administrator username for Windows Machines
  # @option params [String] :vm_name New VM instance name(otherwise old name is going to be used)
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
    params.to_s!
    LOG_DEBUG params.merge!({ :method => 'Reinstall' }).debug_out
    return nil if params['debug'] == 'turn_method_off'

    LOG "Reinstalling VM#{params['vmid']}", 'Reinstall'
    trace << "Checking params:#{__LINE__ + 1}"
    if params.get('vmid', 'groupid', 'userid', 'templateid').include?(nil) then
      LOG "ReinstallError - some params are nil", 'Reinstall'
      LOG_DEBUG params.get('vmid', 'groupid', 'userid', 'templateid')
      return "ReinstallError - some params are nil", params
    end
    params['vmid'], params['groupid'], params['userid'], params['templateid'] = params.get('vmid', 'groupid', 'userid', 'templateid').map { |el|
      el.to_i
    }

    params['cpu'], params['ram'], params['drive'], params['iops'] = params.get('cpu', 'ram', 'drive', 'iops').map { |el| el.to_i }

    begin
      params['iops'] = IONe::Settings['VCENTER_DRIVES_IOPS'][params['ds_type']]
      LOG_DEBUG "IOps: #{params['iops'].class}(#{params['iops']})"
    rescue
      LOG_DEBUG "No vCenter configuration found"
    end

    trace << "Checking template:#{__LINE__ + 1}"
    template = onblock(:t, params['templateid']) do | t |
      result = t.info!
      if result != nil then
        LOG_ERROR "Error: TemplateLoadError"
        return { 'error' => "TemplateLoadError", 'trace' => (trace << "TemplateLoadError:#{__LINE__ - 3}") }
      end
      params['extra'] = params['extra'] || { 'type' => t['/VMTEMPLATE/TEMPLATE/HYPERVISOR'] }
      t
    end

    LOG_DEBUG 'Initializing vm object'
    trace << "Initializing old VM object:#{__LINE__ + 1}"
    vm = onblock(:vm, params['vmid'])
    LOG_DEBUG 'Collecting data from old template'
    trace << "Collecting data from old template:#{__LINE__ + 1}"
    context = vm.to_hash!['VM']['TEMPLATE']

    params['username'] = params['username'] || vm['//CONTEXT/USERNAME']
    params['vm_name']  = params['vm_name']  || vm.name

    LOG_DEBUG 'Generating new template'
    trace << "Generating credentials and network context:#{__LINE__ + 1}"
    context['CONTEXT'] = {
      'USERNAME' => params['username'],
        'PASSWORD' => params['passwd'] || vm['//CONTEXT/PASSWORD'],
        'NETWORK' => context['CONTEXT']['NETWORK'],
        'SSH_PUBLIC_KEY' => context['CONTEXT']['SSH_PUBLIC_KEY']
    }
    context['NIC'] = [context['NIC']] if context['NIC'].class == Hash
    context['NIC'].map! do |nic|
      nic.without(
        'TARGET', 'MAC', 'NAME', 'SECURITY_GROUPS',
        'BRIDGE', 'BRIDGE_TYPE', 'NIC_ID', 'VN_MAD',
        'CLUSTER_ID', 'AR_ID', 'NETWORK', 'NETWORK_UNAME'
      )
    end
    context['NIC'] = context['NIC'].last if context['NIC'].size == 1
    trace << "Generating specs configuration:#{__LINE__ + 1}"
    context.merge!({
      "VCPU" => params['cpu'],
      "MEMORY" => params['ram'] * (params['units'] == 'GB' ? 1024 : 1),
      "DRIVE" => params['ds_type'],
      "DISK" => {
        "IMAGE_ID" => template.to_hash['VMTEMPLATE']['TEMPLATE']['DISK']['IMAGE_ID'],
          "SIZE" => params['drive'] * (params['units'] == 'GB' ? 1024 : 1),
          "OPENNEBULA_MANAGED" => "NO"
      }
    })
    context['TEMPLATE_ID'] = params['templateid']

    context = context.without('GRAPHICS').to_one_template
    LOG_DEBUG "Resulting capacity template:\n#{context}"

    trace << "Terminating VM:#{__LINE__ + 1}"
    vm.terminate(true)
    LOG_COLOR 'Waiting until terminate process will over', 'Reinstall', 'light_yellow'
    trace << ":#{__LINE__ + 1}"
    until STATE_STR(params['vmid']) == 'DONE' do
      sleep(0.2)
    end
    LOG_COLOR "Terminate process is over, new VM is deploying now", 'Reinstall', 'green'
    LOG_DEBUG 'Creating new VM'
    trace << "Instantiating template:#{__LINE__ + 1}"
    vmid = template.instantiate(params['vm_name'], false, context)
    LOG_DEBUG "New VM ID or an OpenNebula::Error: #{begin vmid.to_str rescue vmid.to_s end}"
    begin
      if vmid.class != Integer && vmid.include?('IP/MAC') then
        trace << "Retrying template instantiation:#{__LINE__ + 1}"
        sleep(3)
        vmid = template.instantiate(params['login'] + '_vm', false, context)
      end
    rescue
      return vmid.class, vmid.message if vmid.class != Integer

      return vmid.class
    end

    return vmid.message if vmid.class != Integer

    trace << "Changing VM owner:#{__LINE__ + 1}"
    onblock(:vm, vmid).chown(params['userid'], params['groupid'] || IONe::Settings['USERS_GROUP'])

    #####   PostDeploy Activity define   #####
    Thread.new do
      host = if params['host'].nil? then
               IONe::Settings['NODES_DEFAULT'][params['extra']['type'].upcase]
             else
               params['host']
             end

      vm = onblock(:vm, vmid)
      LOG_DEBUG "Deploying VM to the host ##{host}"
      vm.deploy(host, false, ChooseDS(params['ds_type']))
      LOG_DEBUG 'Waiting until VM will be deployed'
      vm.wait_for_state

      post_deploy = PostDeployActivities.new @client

      # TrialController
      if params['trial'] then
        trace << "Creating trial counter thread:#{__LINE__ + 1}"
        post_deploy.TrialController(params, vmid, host)
      end
      # endTrialController
      # AnsibleController

      if params['ansible'] && params['release'] then
        trace << "Creating Ansible Installer thread:#{__LINE__ + 1}"
        post_deploy.AnsibleController(params, vmid, host)
      end

      # endAnsibleController
    end if params['release']
    ##### PostDeploy Activity define END #####

    return { 'vmid' => vmid, 'vmid_old' => params['vmid'], 'ip' => GetIP(vmid, true), 'ip_old' => GetIP(vm) }
  rescue => e
    LOG_ERROR "Error ocurred while Reinstall: #{e.message}"
    return e.message, trace
  end

  # Recreates VM - leaves same ID, same IP addresses, amount of resources, etc, but recreates on host
  # @param [Hash] params
  # @option params [Integer] :vm
  # @option params [String] :passwd (optional)
  # @option deploy [Boolean] :deploy (optional)
  # @return [TrueClass, Integer] - true and host where VM been deployed before recreate
  def Recreate(params, trace = ["Recreate method called:#{__LINE__}"])
    params.to_sym!
    LOG "Recreating VM#{params[:vm]}", 'Recreate'

    trace << "Getting VM:#{__LINE__}"
    vm = onblock(:vm, params[:vm])
    vm.info!
    trace << "Checking access rights:#{__LINE__}"
    onblock(:u, -1, @client) do | u |
      u.info!
      if u.id != vm.uid && !u.groups.include?(0) then
        raise StandardError.new("Not enough access to perform Recreate")
      end
    end
    trace << "Getting VM host:#{__LINE__}"
    host, _ = vm.host
    trace << "Recovering VM:#{__LINE__}"
    vm.recover(4)

    if params[:passwd] then
      trace << "Changing VM password#{__LINE__}"
      vm.passwd params[:passwd]
    end

    if params[:deploy] then
      trace << "Waiting for state PENDING to deploy VM:#{__LINE__}"
      vm.wait_state("PENDING", 120)
      trace << "Deploying VM:#{__LINE__}"
      vm.deploy(host.to_i)
    end

    return true, host.to_i
  rescue => e
    LOG_ERROR "Error ocurred while Reinstall: #{e.message}"
    raise e
  end

  # Creates new virtual machine from the given OS template and resize it to given specs, and new user account, which becomes owner of this VM
  # @param [Hash] params - all needed data for new User and VM creation
  # @option params [String]  :login Username for new OpenNebula account
  # @option params [String]  :password Password for new OpenNebula account
  # @option params [String]  :vm_name New VM instance name(otherwise old name is going to be used)
  # @option params [String]  :passwd Password for new Virtual Machine
  # @option params [Integer] :templateid Template ID to instantiate
  # @option params [Integer] :cpu vCPU cores amount for new VM
  # @option params [Integer] :iops IOPS limit for new VM's drive
  # @option params [String]  :units Units for RAM and drive size, can be 'MB' or 'GB'
  # @option params [Integer] :ram RAM size for new VM
  # @option params [Integer] :drive Drive size for new VM
  # @option params [String]  :ds_type VM deploy target datastore drives type, 'SSD' or 'HDD'
  # @option params [Integer] :groupid Additional group, in which user should be
  # @option params [Integer] :ips Public IPs amount(default: 1)
  # @option params [Boolean] :trial (false) VM will be suspended after IONe::Settings['TRIAL_SUSPEND_DELAY']
  # @option params [Boolean] :release (false) VM will be started on HOLD if false
  # @option params [Hash]    :user-template Addon template, you may append to default template
  # @option params [Boolean] :allow_snapshots Allow user to create snapshots
  # @param [Array<String>] trace - public trace log
  # @return [Hash, nil] UserID, VMID and IP address if success, or error message and backtrace log if error
  # @example Example out
  #   Success: {'userid' => 777, 'vmid' => 123, 'ip' => '0.0.0.0'}
  #   Debug is set to true: nil
  #   Template not found Error: {'error' => "TemplateLoadError", 'trace' => (trace << "TemplateLoadError:#{__LINE__ - 1}")(Array<String>)}
  #   User create Error: {'error' => "UserAllocateError", 'trace' => trace(Array<String>)}
  #   Unknown error: { 'error' => e.message, 'trace' => trace(Array<String>)}
  def CreateVMwithSpecs(params, trace = ["#{__method__} method called:#{__LINE__}"])
    LOG_DEBUG params.merge!(:method => __method__.to_s).debug_out
    trace << "Checking params types:#{__LINE__ + 1}"

    params['cpu'], params['ram'], params['drive'], params['iops'] = params.get('cpu', 'ram', 'drive', 'iops').map { |el| el.to_i }
    params['ips'] = params['ips'].nil? ? 1 : params['ips'].to_i
    params['user-template'] = {} if params['user-template'].nil?

    begin
      params['iops'] = params['iops'] == 0 ? IONe::Settings['VCENTER_DRIVES_IOPS'][params['ds-type']] : params['iops']
    rescue
      LOG_DEBUG "No vCenter configuration found"
    end

    params['vm_name'] = params['vm_name'] || "#{params['login']}_vm"
    ###################### Doing some important system stuff ###############################################################

    LOG_AUTO "CreateVMwithSpecs for #{params['login']} Order Accepted! #{params['trial'] == true ? "VM is Trial" : nil}"

    LOG_DEBUG "Params: #{params.debug_out}"

    trace << "Checking template:#{__LINE__ + 1}"
    onblock(:t, params['templateid']) do | t |
      result = t.info!
      if result != nil then
        LOG_ERROR "Error: TemplateLoadError"
        return { 'error' => "TemplateLoadError", 'trace' => (trace << "TemplateLoadError:#{__LINE__ - 1}") }
      end
      params['extra'] = params['extra'] || { 'type' => t['/VMTEMPLATE/TEMPLATE/HYPERVISOR'] }
    end

    #####################################################################################################################

    #####   Initializing useful variables   #####
    userid, vmid = 0, 0
    ##### Initializing useful variables END #####

    #####   Creating new User   #####
    LOG_AUTO "Creating new user for #{params['login']}"
    if params['nouser'].nil? || !params['nouser'] then
      trace << "Creating new user:#{__LINE__ + 1}"
      userid, user =
        UserCreate(
          params['login'], params['password'], IONe::Settings['USERS_GROUP'], object: true,
              type: params['extra']['type']
        ) if params['test'].nil?
      LOG_ERROR "Error: UserAllocateError" if userid == 0
      trace << "UserAllocateError:#{__LINE__ - 2}" if userid == 0
      return { 'error' => "UserAllocateError", 'trace' => trace } if userid == 0
    else
      userid, user = params['userid'], onblock(:u, params['userid'])
    end
    params['user_id'] = userid
    LOG_AUTO "New User account created"

    ##### Creating new User END #####

    #####   Creating and Configuring VM   #####
    LOG_AUTO "Creating VM for #{params['login']}"
    trace << "Creating new VM:#{__LINE__ + 1}"
    onblock(:t, params['templateid']) do | t |
      t.info!
      params['username'] = params['username'] || (t.win? ? 'Administrator' : 'root')
      specs = ""
      if !t['/VMTEMPLATE/TEMPLATE/CAPACITY'] && t['/VMTEMPLATE/TEMPLATE/HYPERVISOR'].upcase == "VCENTER" then
        specs = {
          "VCPU" => params['cpu'],
          "MEMORY" => params['ram'] * (params['units'] == 'GB' ? 1024 : 1),
          "DRIVE" => params['ds_type'],
          "DISK" => {
            "IMAGE_ID" => t.to_hash['VMTEMPLATE']['TEMPLATE']['DISK']['IMAGE_ID'],
              "SIZE" => params['drive'] * (params['units'] == 'GB' ? 1024 : 1),
              "OPENNEBULA_MANAGED" => "NO"
          }
        }
      elsif t['/VMTEMPLATE/TEMPLATE/HYPERVISOR'].upcase == 'AZURE' then
        specs = {
          "OS_DISK_SIZE" => params['drive'],
          "SIZE" => params['extra']['instance_size'],
          "VM_USER_NAME" => params['username'],
          "PASSWORD" => params['passwd'],
          "VCPU" => params['cpu'],
          "MEMORY" => params['ram'] * (params['units'] == 'GB' ? 1024 : 1)
        }
      elsif t['/VMTEMPLATE/TEMPLATE/HYPERVISOR'].upcase == 'KVM' then
        specs = {
          "CPU" => 1,
          "VCPU" => params['cpu'],
          "MEMORY" => params['ram'] * (params['units'] == 'GB' ? 1024 : 1),
          "DRIVE" => params['ds_type'],
          "DISK" => {
            "DEV_PREFIX" => "vd",
              "DRIVER" => "qcow2",
              "SIZE" => params['drive'] * (params['units'] == 'GB' ? 1024 : 1),
              "OPENNEBULA_MANAGED" => "NO"
          }
        }
        key = t.to_hash['VMTEMPLATE']['TEMPLATE']['DISK']['IMAGE_ID'].nil? ? 'IMAGE' : 'IMAGE_ID'
        specs['DISK'][key] = t.to_hash['VMTEMPLATE']['TEMPLATE']['DISK'][key]
      end
      trace << "Updating user quota:#{__LINE__ + 1}"
      user.update_quota_by_vm(
        'append' => true, 'cpu' => params['cpu'],
        'ram' => params['ram'] * (params['units'] == 'GB' ? 1024 : 1),
        'drive' => params['drive'] * (params['units'] == 'GB' ? 1024 : 1)
      ) unless t['/VMTEMPLATE/TEMPLATE/CAPACITY'] == 'FIXED'

      unless params['allow_snapshots'].nil? then
        params['user-template']['SNAPSHOTS_ALLOWED'] = params['allow_snapshots'].to_s.upcase
      end

      trace << "Setting up NICs:#{__LINE__ + 1}"
      specs['NIC'] = []
      params['ips'].times do
        specs['NIC'] << { NETWORK_ID: IONe::Settings['PUBLIC_NETWORK_DEFAULTS']['NETWORK_ID'] }
      end

      LOG_DEBUG "Resulting capacity template:\n" + specs.debug_out
      specs = specs.to_one_template
      vmid = t.instantiate(params['vm_name'], true, specs + "\n" + params['user-template'].to_one_template)
    end

    raise "Template instantiate Error: #{vmid.message}" if OpenNebula.is_error? vmid

    host = if params['host'].nil? then
             IONe::Settings['NODES_DEFAULT'][params['extra']['type'].upcase]
           else
             params['host']
           end

    LOG_AUTO 'Configuring VM Template'
    trace << "Configuring VM Template:#{__LINE__ + 1}"
    onblock(:vm, vmid) do | vm |
      trace << "Changing VM owner:#{__LINE__ + 1}"
      begin
        r = vm.chown(userid, IONe::Settings['USERS_GROUP'])
        raise r.message unless r.nil?
      rescue
        LOG_DEBUG "CHOWN error, params: #{userid}, #{vm}"
      end

      if %w(VCENTER KVM).include? params['extra']['type'].upcase then
        LOG_DEBUG "Instantiating VM as#{win ? nil : ' not'} Windows"
        trace << "Setting VM context:#{__LINE__ + 2}"
        begin
          vm.updateconf(
            {
              CONTEXT: {
                NETWORK: "YES",
                PASSWORD: params['passwd'],
                SSH_PUBLIC_KEY: "$USER[SSH_PUBLIC_KEY]",
                USERNAME: params['username']
              }
            }.to_one_template
          )
        rescue => e
          LOG_DEBUG "Context configuring error: #{e.message}"
        end

        trace << "Setting VM VNC settings:#{__LINE__ + 2}"
        begin
          vm.updateconf(
            {
              GRAPHICS: {
                LISTEN: "0.0.0.0",
                PORT: (IONe::Settings['BASE_VNC_PORT'] + vmid),
                TYPE: "VNC"
              }
            }.to_one_template
          ) # Configuring VNC
        rescue => e
          LOG_DEBUG "VNC configuring error: #{e.message}"
        end
      end

      if %w(VCENTER KVM).include? params['extra']['type'].upcase then
        trace << "Deploying VM:#{__LINE__ + 1}"
        vm.deploy(host, false, ChooseDS(params['ds_type'], params['extra']['type']))
      else
        trace << "Deploying VM:#{__LINE__ + 1}"
        vm.deploy(host, false)
      end if params['release']
    end
    ##### Creating and Configuring VM END #####

    #####   PostDeploy Activity define   #####
    Thread.new do
      LOG_DEBUG "Starting PostDeploy Activities for VM#{vmid}"

      onblock(:vm, vmid).wait_for_state

      LOG_DEBUG "VM is active now, let it go"

      post_deploy = PostDeployActivities.new @client

      # TrialController

      if params['trial'] then
        trace << "Creating trial counter thread:#{__LINE__ + 1}"
        post_deploy.TrialController(params, vmid, host)
      end

      # endTrialController
      # AnsibleController

      if params['ansible'] && params['release'] then
        trace << "Creating Ansible Installer thread:#{__LINE__ + 1}"
        post_deploy.AnsibleController(params, vmid, host)
      end

      # endAnsibleController
    end if params['release']
    ##### PostDeploy Activity define END #####

    LOG_AUTO 'Post-Deploy joblist defined, basic installation job ended'
    return { 'userid' => userid, 'vmid' => vmid, 'ip' => GetIP(vmid) }
  rescue => e
    begin
      out = { :exception => e.message, :trace => trace << 'END_TRACE' }
      LOG_DEBUG e.backtrace
      LOG_DEBUG out.debug_out
      out[:params] = params
      return out
    ensure
      onblock(:vm, vmid).recover(3) if (defined? vmid) && !(OpenNebula.is_error? vmid)
      user.delete if defined? user
    end
  end

  # Class for pst-deploy activities methods
  #   All methods will receive creative methods params, new vm ID, and host, where VM was deployed
  class PostDeployActivities
    def initialize client
      @ione = IONe.new(client, $db)
    end
    include Deferable
    # Executes given playbooks at fresh-deployed vm
    def AnsibleController(params, vmid, _host = nil)
      onblock(:vm, vmid).wait_for_state
      sleep(60)
      unless params['ansible_local_id'].nil? then
        LOG_DEBUG "Ansible Local ID: #{params['ansible_local_id']}"
        LOG_DEBUG('Starting process')
        install_process =
          AnsiblePlaybookProcess.new(
            playbook_id:    params['ansible_local_id'],
              uid:            params['userid'],
              hosts:          { vmid => ["#{@ione.GetIP(vmid)}:#{$ione_conf['OpenNebula']['users-vms-ssh-port']}"] }, # !!!
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
          @ione.AnsibleController(
            params.merge(
              {
                'super' => '', 'vmid' => vmid,
                'host' => "#{@ione.GetIP(vmid)}:#{$ione_conf['OpenNebula']['users-vms-ssh-port']}"
              }
            )
          )
        end
      end
      LOG_COLOR "Install-thread started, you should wait until the #{params['ansible-service']} will be installed", 'AnsibleController',
                'light_yellow'
    rescue => e
      LOG_DEBUG e.message
      LOG_DEBUG e.backtrace
    end

    # If Cluster type is vCenter, sets up Limits at the node
    def LimitsController(params, vmid, host = nil)
      onblock(:vm, vmid) do | vm |
        key = IONe::Settings['VCENTER_CPU_LIMIT_FREQ_PER_CORE'][host.name!].nil? ? 'default' : host.name!

        lim_res = vm.setResourcesAllocationLimits(
          cpu: params['cpu'] * IONe::Settings['VCENTER_CPU_LIMIT_FREQ_PER_CORE'][key],
          ram: params['ram'] * (params['units'] == 'GB' ? 1024 : 1), iops: params['iops']
        )
        unless lim_res.nil? then
          err, back = lim_res.split("<|>")
          LOG_ERROR "Limits was not set, error: #{err}"
          LOG_DEBUG "Limits was not set, error: #{err}\n#{back}"
        end
      end if ClusterType(host.id) == 'vcenter'
    end

    # If VM is trial, starts time and schedule suspend method
    def TrialController(params, vmid, _host = nil)
      LOG "VM #{vmid} suspend action scheduled", 'TrialController'
      action_time = Time.now.to_i + (params['trial-suspend-delay'].nil? ?
                          IONe::Settings['TRIAL_SUSPEND_DELAY'] :
                          params['trial-suspend-delay'])
      onblock(:vm, vmid).wait_for_state
      if !onblock(:vm, vmid).schedule('suspend', action_time).nil? then
        LOG_ERROR 'Scheduler process error', 'TrialController'
      end
    end

    deferable :LimitsController
  end
end

class IONe
  # Logs sent message into ione.log and gives data about availability
  # @param [String] msg - message to log
  # @return [String('DONE') | String('PONG')]
  # @example
  #   ZmqJsonRpc::Client.new(uri, 50).Test('PING') => 'PONG' -> Service available
  #                                                => Exception -> Service down
  def Test(msg, log = "Test")
    LOG "Test message received, text: #{msg}", log if msg != 'PING'
    if msg == "PING" then
      return "PONG"
    end

    "DONE"
  end

  # @!group VirtualMachines Info

  # Returns vmid by owner id
  # @param [Integer] uid - owner id
  # @return [Integer | 'none']
  # @example
  #   => Integer => user and vm found
  #   => 'none'  => no user or now vm exists
  def get_vm_by_uid(uid)
    vmp = VirtualMachinePool.new(@client)
    vmp.info_all!
    vmp.each do | vm |
      return vm.id.to_i if vm.uid(false) == uid
    end
    'none'
  end

  # Returns user vms by user id
  # @param [Integer] uid - owner id
  # @return [Array<Hash>]
  # @example
  #   => [{:id => ..., :name => ...}, {:id => ..., :name => ...}, ...]
  def get_vms_by_uid(uid)
    vmp, vms = VirtualMachinePool.new(@client), []
    vmp.info_all!
    vmp.each do | vm |
      vms << { :id => vm.id.to_i, :name => vm.name } if vm.uid(false) == uid
    end
    vms
  end

  # @!endgroup

  # @!group Users Info

  # Returns user id by username
  # @param [String] name - username
  # @return [Integer| 'none']
  # @example
  #   => Integer => user found
  #   => 'none'  => no user exists
  def get_uid_by_name(name)
    up = UserPool.new(@client)
    up.info_all!
    up.each do | u |
      return u.id.to_i if u.name == name
    end
    'none'
  end

  # @!endgroup

  # @!group VirtualMachines Info

  # Returns vmid, userid and VM IP by owner username
  # @param [String] name - username
  # @return [Hash]
  # @example
  #   => {:vmid => Integer, :userid => Integer, :ip => String} => User and VM found
  #   => {:vmid => 'none', :userid => 'none', :ip => String}
  def get_vm_by_uname name
    userid = get_uid_by_name(name)
    vmid = get_vm_by_uid(userid)
    unless vmid.nil? then
      { :vmid => vmid, :userid => userid, :ip => GetIP(vmid) }
    else
      nil
    end
  end

  # Returns host name, where VM has been deployed
  # @param [Integer] vm - VM ID
  # @param [Boolean] hid - returns host id if true
  # @return [String | nil]
  # @example
  #   => String('example-node-vcenter') => Host was found
  #   => nil => Host wasn't found
  def get_vm_host vm, hid = false
    vm = onblock(:vm, vm, @client) if vm.class == Integer
    history = vm.to_hash!['VM']["HISTORY_RECORDS"]['HISTORY'] # Searching hostname at VM allocation history
    history = history.last if history.class == Array # If history consists of 2 or more lines - returns last
    return hid ? [history['HOSTNAME'], history['HID']] : history['HOSTNAME']
  rescue
    return nil # Returns NilClass if did not found anything - possible if vm is at HOLD or PENDING state
  end

  # Returns datastore name, where VM has been deployed
  # @param [Integer] vmid - VM ID
  # @return [String | nil]
  # @example
  #   => String('example-ds-vcenter') => Host was found
  #   => nil => Host wasn't found
  def get_vm_ds vmid
    onblock(:vm, vmid, @client) do | vm |
      h = vm.to_hash!['VM']["HISTORY_RECORDS"]['HISTORY'] # Searching hostname at VM allocation history
      return h['DS_ID'] if h.class == Hash # If history consists of only one line - returns it
      return h.last['DS_ID'] if h.class == Array # If history consists of 2 or more lines - returns last

      nil # Returns NilClass if did not found anything - possible if vm is at HOLD or PENDING state
    end
  end

  # Returns VM listing with some additional data, available nodes list and free IP-addresses in AddressPool
  # @param [Array] vms - filter, returns only listed vms
  # @return [Array<Hash>, Array<String>, Array<String> | Array<Hash>, Array<String>]
  # @example VM's filter given
  #       compare_info([1, 2, ...]) =>
  #           [{
  #               :vmid => 1, :userid => 1, :host => 'example-node0',
  #               :login => 'username', :ip => '0.0.0.0', :state => 'RUNNING'
  #           }, ...], ['example-node0', 'example-node1', ...]
  # @example VM's filter not given
  #       compare_info() =>
  #           [{
  #               :vmid => 0, :userid => 0, :host => 'example-node0',
  #               :login => 'username', :ip => '192.168.10.3', :state => 'RUNNING'
  #           }, ...], ['example-node0', 'example-node1', ...], ['192.168.10.2', '192.168.10.4', '192.168.10.5', ...]
  def compare_info vms = []
    info = []
    infot = Thread.new do
      unless vms.empty? then
        vm_pool = vms.map! do |vmid|
          onblock(:vm, vmid) { | vm | vm.info! || vm }
        end
      else
        vm_pool = VirtualMachinePool.new(@client)
        vm_pool.info_all!
      end
      vm_pool.each do |vm| # Creating VM list from VirtualMachine Pool Object
        begin
          info << {
            vmid: vm.id, userid: vm.uid(false), host: get_vm_host(vm.id),
            login: vm.uname(false, true), ip: GetIP(vm),
            state: (vm.lcm_state != 0 ? vm.lcm_state_str : vm.state_str)
          }
        rescue
          break
        end
      end
    end

    return info || infot.join unless vms.empty?

    free = []
    freet = Thread.new do
      vn_pool = VirtualNetworkPool.new(@client)
      vn_pool.info_all!
      vn_pool.each do | vn | # Getting leases from each VN
        break if vn.nil?

        begin
          # This, generates list of free addresses in given VN
          vn = vn.to_hash!["VNET"]["AR_POOL"]["AR"][0]
          next if (vn['IP'] && vn['SIZE']).nil?

          pool = ((vn["IP"].split('.').last.to_i)..(vn["IP"].split('.').last.to_i + vn["SIZE"].to_i)).to_a.map! { |item|
            vn['IP'].split('.').slice(0..2).join('.') + "." + item.to_s
          }
          vn['LEASES']['LEASE'].each do | lease |
            pool.delete(lease['IP'])
          end
          free.push pool
        rescue
        end
      end
    end

    host_pool, hosts = HostPool.new(@client), [] # Collecting hostnames(node-names) from HostPool
    host_pool.info_all!
    host_pool.each do | host |
      hosts << host.name
    end

    freet.join
    infot.join

    return info, hosts, free
  end

  # @!endgroup

  # @!group Users Info

  # Returns User template in XML
  # @param [Integer] userid
  # @return [String] XML
  def GetUserInfo(userid)
    onblock(:u, userid) do |user|
      user.info!
      user.to_xml
    end
  end

  # @!endgroup

  # Returns monitoring information about datastores
  # @param [String] type - choose datastores types for listing: system('sys') or image('img')
  # @return [Array<Hash> | String]
  # @example
  #   DatastoresMonitoring('sys') => [{"id"=>101, "name"=>"NASX", "full_size"=>"16TB", "used"=>"3.94TB", "type"=>"HDD", "deploy"=>"TRUE"}, ...]
  #   DatastoresMonitoring('ing') => String("WrongTypeExeption: type 'ing' not exists")
  def DatastoresMonitoring(type)
    return "WrongTypeExeption: type '#{type}' not exists" if type != 'sys' && type != 'img'

    # @!visibility private
    # Converts MB to GB
    size_convert = lambda do | mb |
      if mb.to_f / 1024 > 768 then
        return "#{(mb.to_f / 1048576.0).round(2)}TB"
      else
        return "#{(mb.to_f / 1024.0).round(2)}GB"
      end
    end

    img_pool, mon = DatastorePool.new(@client), []
    img_pool.info_all!
    img_pool.each do | img |
      mon << {
        'id' => img.id, 'name' => img.name.split('(').first, :full_size => size_convert[img.to_hash['DATASTORE']['TOTAL_MB']],
          'used' => size_convert[img.to_hash['DATASTORE']['USED_MB']],
          'type' => img.to_hash['DATASTORE']['TEMPLATE']['DRIVE_TYPE'],
          'deploy' => img.to_hash['DATASTORE']['TEMPLATE']['DEPLOY'],
          'hypervisor' => img.to_hash['DATASTORE']['TEMPLATE']['HYPERVISOR']
      } if img.short_type_str == type && img.id > 2
    end
    mon
  end

  # Returns monitoring information about nodes
  # @return [Array<Hash>]
  # @example
  #   HostsMonitoring() => {"id"=>0, "name"=>"vCloud", "full_size"=>"875.76GB", "reserved"=>"636.11GB", "running_vms"=>179, "cpu"=>"16.14%"}
  def HostsMonitoring()
    # @!visibility private
    # Converts MB to GB
    size_convert = lambda do | mb |
      if mb.to_f / 1048576 > 768 then
        return "#{(mb.to_f / 1073741824.0).round(2)}TB"
      else
        return "#{(mb.to_f / 1048576.0).round(2)}GB"
      end
    end

    host_pool, mon = HostPool.new(@client), []
    host_pool.info!
    host_pool.each do | host |
      host = host.to_hash['HOST']
      mon << {
        :id => host['ID'].to_i, :name => host['NAME'], :full_size => size_convert[host.to_hash['HOST_SHARE']['TOTAL_MEM']],
          :reserved => size_convert[host.to_hash['HOST_SHARE']['MEM_USAGE']],
          :running_vms => host.to_hash['HOST_SHARE']['RUNNING_VMS'].to_i,
          :cpu => "#{(host.to_hash['HOST_SHARE']['USED_CPU'].to_f / host.to_hash['HOST_SHARE']['TOTAL_CPU'].to_f * 100).round(2)}%"
      }
    end
    mon
  end

  # Checks if resources hot add enabled
  # @param [Integer] vmid VM ID
  # @param [String] name VM name on vCenter node
  # @note For correct work of this method, you must keep actual vCenter Password at VCENTER_PASSWORD_ACTUAL attribute in OpenNebula
  # @note Method searches VM by it's default name: one-(id)-(name), if target vm got another name, you should provide it
  # @return [Hash | String] Returns limits Hash if success or exception message if fails
  def get_vm_hotadd_conf(vmid, name = nil)
    onblock(:vm, vmid).hotAddEnabled? name
  end

  # Sets resources hot add settings
  # @param [Hash] params
  # @option params [Boolean] :vmid VM ID
  # @option params [Boolean] :cpu
  # @option params [Boolean] :ram
  # @option params [String]  :name VM name on vCenter node
  # @return [true | String]
  def set_vm_hotadd_conf(params)
    params.to_sym!
    onblock(:vm, params[:vmid]).hotResourcesControlConf(params)
  end

  # Resize VM without powering off the VM
  # @param [Hash] params
  # @option params [Boolean] :vmid VM ID
  # @option params [Integer] :cpu CPU amount to set
  # @option params [Integer] :ram RAM amount in MB to set
  # @option params [String] :name VM name on vCenter node
  # @return [Boolean | String]
  # @note Method returns true if resize action ended correct, false if VM not support hot reconfiguring
  def vm_hotadd(params)
    params.to_sym!
    onblock(:vm, params[:vmid]).hot_resize(params)
  end

  # @!group Users Info

  # Checks if User exists
  def user_exists uid
    onblock(:u, uid).exists?
  end

  # @!endgroup

  # @!group User Control

  # Deletes user and all his VMs
  def UserDelete uid
    u = onblock(:u, uid)
    u.vms(@db).each do | vm |
      vm.terminate true
    end
    u.delete
    true
  rescue => e
    LOG_DEBUG e.message
  end

  # @!endgroup

  # @!group VirtualMachines info

  # Returns all vms available with given credentials
  # @param [Integer] chunks - number of chunks per page
  # @param [Integer] page - page number(shift)
  # @return [Array<Integer>]
  def get_available_vms chunks = nil, page = 0
    vmp = VirtualMachinePool.new(@client)
    vmp.info_all!

    if chunks.nil? then
      vmp.inject([]) do |r, vm|
        r << {
          id: vm.id,
              name: vm.name,
              ip: GetIP(vm),
              state: vm.state_str,
              lcm_state: vm.lcm_state_str,
              host: get_vm_host(vm)
        }
      end
    else
      vmp.inject([]) { |r, vm| r << vm }.each_slice(chunks).to_a[page].map do | vm |
        {
          id: vm.id,
              name: vm.name,
              ip: GetIP(vm),
              state: vm.state_str,
              lcm_state: vm.lcm_state_str,
              host: get_vm_host(vm)
        }
      end
    end
  end

  # @!endgroup
end

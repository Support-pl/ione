require 'rbvmomi'
require "#{ROOT}/service/custom_objects.rb"

# Useful methods for OpenNebula classes, functions and constants.
module ONeHelper
    
    VIM = RbVmomi::VIM # Alias for RbVmomi::VIM

    # Searches Instances at vCenter by name at given folder
    # @param [RbVmomi::VIM::Folder] folder - folder where search
    # @param [String] name - VM name at vCenter
    # @param [Boolean] exact
    # @return [Array<RbVmomi::VIM::VirtualMachine>]
    # @note Tested and used for VMs, but can search at any datacenter folder
    # @note Source https://github.com/MarkArbogast/vsphere-helper/blob/master/lib/vsphere_helper/helpers.rb#L51-#L68
    def recursive_find_vm(folder, name, exact = false)
        # @!visibility private
        # Comparator for object names
        def matches(child, name, exact = false)
            is_vm = child.class == RbVmomi::VIM::VirtualMachine
            name_matches = (name == "*") || (exact ? (child.name == name) : (child.name.include? name))
            is_vm && name_matches
        end
        found = []
        folder.children.each do |child|
          if matches(child, name, exact)
            found << child
          elsif child.class == RbVmomi::VIM::Folder
            found << recursive_find_vm(child, name, exact)
          end
        end
      
        found.flatten
    end
    # Searches Instances at vCenter by name at given folder
    # @param [RbVmomi::VIM::Folder] folder - folder where search
    # @param [String] name - DS name at vCenter
    # @param [Boolean] exact
    # @return [Array<RbVmomi::VIM::Datastore>]
    def recursive_find_ds(folder, name, exact = false)
        # @!visibility private
        # Comparator for object names
        def matches(child, name, exact = false)
            is_ds = child.class == RbVmomi::VIM::Datastore
            name_matches = (name == "*") || (exact ? (child.name == name) : (child.name.include? name))
            is_ds && name_matches
        end
        found = []
        folder.children.each do |child|
          if matches(child, name, exact)
            found << child
          elsif child.class == RbVmomi::VIM::Folder
            found << recursive_find_vm(child, name, exact)
          end
        end
      
        found.flatten
    end

    # Returns VIM::Datacenter for host
    # @param [OpenNebula::Host] host
    # @return [Datacenter]
    def get_vcenter_dc(host)
        host = host.to_hash!['HOST']['TEMPLATE']
        VIM.connect(
            :host => host['VCENTER_HOST'], :insecure => true,
            :user => host['VCENTER_USER'], :password => host['VCENTER_PASSWORD_ACTUAL']
        ).serviceInstance.find_datacenter
    end
    # Returns Datastore IP and Path
    # @param [Integer] host - host ID
    # @param [String] name - Datastore name
    # @return [String, String] ip, path
    def get_ds_vdata(host, name)
        get_vcenter_dc(onblock(:h, host)).datastoreFolder.children.each do | ds |
            next if ds.name != name
            begin
                return ds.info.nas.remoteHost, ds.info.nas.remotePath
            rescue
                nil
            end
        end
    end

    # Prints given objects classes
    # @param [Array] args
    # @return [NilClass]
    def putc(*args)
        args.each do | el |
            puts el.class
        end
        nil
    end

    # {#onblock} supported instances list 
    ON_INSTANCES = {
        :vm  => VirtualMachine,
        :t   => Template,
        :h   => Host,
        :u   => User,
        :vn  => VirtualNetwork,
        :ds  => Datastore,
        :mpa => MarketPlaceApp,
        :ma  => MarketPlace,
        :vr  => VirtualRouter,
        :vdc => Vdc,
        :sg  => SecurityGroup,
        :z   => Zone,
        :d   => Document,
        :c   => Cluster,
        :acl => Acl,
        :g   => Group,
        :i   => Image,
        :p   => Pool
    }

    # Generates any 'Pool' element object or yields it
    # @param [Class | Symbol] object - object class to create or symbol linked to target class
    # @param [Integer] id - element id at its Pool
    # @param [OpenNebula::Client] client - auth provider object, if 'none' uses global variable '$client'
    # @return [OpenNebula::PoolElement]
    # @example Getting VirtualMachine object
    #   $client = Client.new('oneadmin:secret', 'http://localhost:2633/RPC2')
    #       * * *
    #   vm = onblock :vm, 777
    #   p vm.class
    #       => #<OpenNebula::VirtualMachine:0x00000004c64720>
    # @yield [object] If block is given, onblock yields given object
    # @example Using VirtualMachine object inside block
    #   onblock :vm, 777 do | vm |
    #       vm.info!
    #       puts JSON.pretty_generate(vm.to_hash)
    #   end
    def onblock(object, id, client = 'none')
        client = $client if client == 'none'
        if object.class != Class then
            object = ON_INSTANCES[object]
            return 'Error: Unknown instance name given' if object.nil?
        end
        if block_given?
            yield object.new_with_id id.to_i, client
        else
            object.new_with_id id.to_i, client
        end
    end
    # Returns random Datastore ID filtered by disk type
    # @note Remember to configure DRIVE_TYPE(HDD|SSD) and DEPLOY(TRUE|FALSE) attributes at your Datastores
    # @param [String] ds_type   - Datastore type, may be HDD or SSD, returns any DS if not given
    # @return [Integer]
    def ChooseDS(ds_type = nil, hypervisor = nil)
        dss = IONe.new($client, $db).DatastoresMonitoring('sys').sort! { | ds | 100 * ds['used'].to_f / ds['full_size'].to_f }
        dss.delete_if { |ds| ds['type'] != ds_type || ds['deploy'] != 'TRUE' || (!hypervisor.nil? && ds['hypervisor'] != hypervisor.upcase) } unless ds_type.nil?
        ds = dss[rand(dss.size)]
        LOG_DEBUG "Deploying to #{ds['name']}"
        ds['id']
    end
    # Returns given cluster hypervisor type
    # @param [Integer] hostid ID of the host to check
    # @return [String]
    # @example
    #       ClusterType(0) => 'vcenter'
    #       ClusterType(1) => 'kvm'
    def ClusterType(hostid)
        onblock(:h, hostid) do | host |
            host.info!
            host.to_hash['HOST']['TEMPLATE']['HYPERVISOR']
        end
    end
end
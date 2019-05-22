# OpenNebula::User class
class OpenNebula::User
    # Sets user quota by his existing VMs and/or appends new vm specs to it
    # @param [Hash] spec
    # @option spec [Boolean]          'append'  Set it true if you wish to append specs
    # @option spec [Integer | String] 'cpu'     CPU quota limit to append
    # @option spec [Integer | String] 'ram'     RAM quota limit to append
    # @note Method sets quota to 'used' values by default
    # @return nil
    def update_quota_by_vm(spec = {})
        quota = self.to_hash!['USER']['VM_QUOTA']['VM']
        if quota.nil? then
            quota = Hash.new
        end
        self.set_quota(
            "VM=[
                CPU=\"#{(spec['cpu'].to_i + quota['CPU_USED'].to_i).to_s}\", 
                MEMORY=\"#{(spec['ram'].to_i + quota['MEMORY_USED'].to_i).to_s}\", 
                SYSTEM_DISK_SIZE=\"#{spec['drive'].to_i + quota['SYSTEM_DISK_SIZE_USED'].to_i}\", 
                VMS=\"#{spec['append'].nil? ? quota['VMS_USED'].to_s : (quota['VMS_USED'].to_i + 1).to_s}\" ]"
        )
    end
    def name!
        info!
        name
    end

    def balance
        to_hash!['USER']['TEMPLATE']['BALANCE']
    end
    def balance= num
        update("BALANCE = #{num}", true)
    end
    def alert
        alert_at = to_hash!['USER']['TEMPLATE']['ALERT'] || $db[:settings].where(:name => 'ALERT').to_a.last[:body]
        return balance <= alert_at, alert_at
    end
    def alert= at
        update("ALERT = #{at}", true)
    end
    def vms
        vm_pool = VirtualMachinePool.new(@client, id)
        vm_pool.info!
        vm_pool.to_a
    rescue
        nil
    end
    def exists?
        self.info! == nil
    end

    class UserNotExistsError < StandardError
        def initialize msg = "User not exists or error occurred while getting user."
           super
        end
    end
end
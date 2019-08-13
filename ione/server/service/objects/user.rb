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
        info! || self['TEMPLATE/BALANCE']
    end
    def balance= num
        update("BALANCE = #{num}", true)
    end
    def alert
        alert_at = (info! || self['TEMPLATE/ALERT']) || $db[:settings].where(:name => 'ALERT').to_a.last[:body]
        return balance.to_f <= alert_at.to_f, alert_at.to_f
    end
    def alert= at
        update("ALERT = #{at}", true)
    end
    def vms db
        db[:vm_pool].where(uid: @pe_id).exclude(:state => 6).select(:oid).to_a.map { |row| onblock(:vm, row[:oid]){|vm| vm.info! || vm} }
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
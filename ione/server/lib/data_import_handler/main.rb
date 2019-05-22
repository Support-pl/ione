puts 'Extending Handler class by IMPORT func'
class IONe
    # Imports wild VM
    def IMPORT(params)
        LOG_DEBUG params
        # return nil
        if params.class == Hash
            begin
            userid = UserCreate(params['username'], params['password'])
            if userid == 0 then
                up = UserPool.new(@client)
                up.info_all!
                up.each do |u|
                    if u.name == params['username'] then
                        userid = u.id
                        break
                    end
                end
            end
            params['vmid'] = GetVMIDbyIP(params['ip']) if params['vmid'].nil?
            return { params['serviceid'].to_s => [userid, nil] } if params['vmid'].nil?
            vm = get_pool_element(VirtualMachine, params['vmid'], @client)
            vm.chown(userid, USERS_GROUP)
            user = User.new(User.build_xml(userid), @client)
            used = vm.to_hash!['VM']['TEMPLATE']
            user_quota = user.to_hash!['USER']['VM_QUOTA']
            begin
                user.set_quota(
                    "VM=[
                    CPU=\"#{(used['CPU'].to_i + user_quota['CPU_USED'].to_i).to_s}\", 
                    MEMORY=\"#{(used['MEMORY'].to_i + user_quota['MEMORY_USED'].to_i).to_s}\", 
                    SYSTEM_DISK_SIZE=\"-1\", 
                    VMS=\"#{(user_quota['VMS_USED'].to_i + 1).to_s}\" ]")
            rescue
            end
            vm.rename("user_#{params['serviceid'].to_s}_vm")
            return { params['serviceid'].to_s => [userid, params['vmid']] }
            rescue
                LOG_DEBUG params
                LOG_DEBUG userid
            end
        end
        params.map! do |el|
            el = IMPORT(el)
        end
    end
end
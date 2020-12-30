class IONe
    # Will call object method if smth like vm_poweroff(1) called
    def method_missing m, *args, &block
        obj, method = m.to_s.split('_')
        if ONeHelper::ON_INSTANCES.keys.include? obj.to_sym then
            onblock(obj.to_sym, args[0], @client).send(method, self)
        else
            super
        end
    end
end
class IONe
    def method_missing m, *args, &block
        binding.pry
        obj, method = m.to_s.split('_')
        if ONeHelper::ON_INSTANCES.keys.include? obj.to_sym then
            onblock(obj.to_sym, args[0]).send(method, self)
        else
            super
        end
    end
end
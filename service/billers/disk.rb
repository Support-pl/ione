class DiskBiller < Biller
    # Checking if Capacity costs are given, otherwise there is no point to calculate it
    def check_biller
        @costs = JSON.parse(costs['DISK_COST'])
        return false if @costs.nil?

        r = 
            @costs.values.inject(0) do | r, c |
                r += c.to_i
            rescue
                r
            end
        return false if r <= 0

        @cost = r[@vm['/VM/USER_TEMPLATE/DRIVE']].to_f
        return @cost > 0
    rescue
        return false
    end

    def bill bill, state, delta
        bill[:capacity] = delta * @cost
        bill
    end
end
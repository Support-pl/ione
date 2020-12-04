class CapacityBiller < Biller
    def check_biller
        @costs = JSON.parse(costs['CAPACITY_COST'])
        return false if @costs.nil?

        r = 
            @costs.values.inject(0) do | r, c |
                r += c.to_i
            rescue
                r
            end
        return r > 0
    rescue
        return false
    end
end
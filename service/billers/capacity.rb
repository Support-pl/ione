class CapacityBiller < Biller
    # Checking if Capacity costs are given, otherwise there is no point to calculate it
    def check_biller
        @costs = JSON.parse(costs['CAPACITY_COST'])
        return false if @costs.nil?

        @cost = 
            @costs.values.inject(0) do | r, c |
                r += c.to_f
            rescue
                r
            end
        return @cost > 0
    rescue
        return false
    end

    def bill bill, state, delta
        if state[:state] == 'on' || billing_period != 'PAYG' then
            bill[:capacity] = delta * @cost
        end
        bill
    end
end
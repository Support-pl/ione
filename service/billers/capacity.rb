class CapacityBiller < Biller
    # Checking if Capacity costs are given, otherwise there is no point to calculate it
    def check_biller
        @costs = JSON.parse(costs['CAPACITY_COST'])
        return false if @costs.nil?

        costs = 
            @costs.values.inject(0) do | r, c |
                r += c.to_f
            rescue
                r
            end
        if costs > 0 then
            @cost = @costs['CPU_COST'].to_f * @vm['//TEMPLATE/VCPU'].to_i + @costs['MEMORY_COST'].to_f * @vm['//TEMPLATE/MEMORY'].to_i
            return true
        end

        return false
    rescue
        return false
    end

    def bill bill:, state:, delta:, record: nil
        if state[:state] == 'on' || billing_period != 'PAYG' then
            bill[:capacity] = delta * @cost
        end
        bill
    end
end
class TrafficBiller < Biller
    def check_biller
        @cost = JSON.parse(costs['TRAFFIC_COST'])
        return false if @cost.nil?

        @cost = @cost.to_f
        @costs = { rx: @cost, tx: @cost } # Will Add support for differnt rx and tx prices

        return @costs.values.inject(0) do | r, c |
            r += c.to_f
        rescue
            r
        end > 0
    rescue
        return false
    end
end
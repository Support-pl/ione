class TrafficBiller < Biller
    def check_biller
        @cost = JSON.parse(costs['TRAFFIC_COST'])
        return false if @cost.nil?

        @cost = @cost.to_f
        return @cost > 0
    rescue
        return false
    end
end
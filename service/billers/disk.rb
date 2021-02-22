# VM Disk costs biller
class DiskBiller < Biller
    # Checking if Capacity costs are given, otherwise there is no point to calculate it
    def check_biller
        @costs = JSON.parse(costs['DISK_COSTS'])
        return false if @costs.nil?

        r = 
            @costs.values.inject(0) do | r, c |
                r += c.to_f
            rescue
                r
            end
        return false if r <= 0

        @cost = @costs[@vm['/VM/USER_TEMPLATE/DRIVE']].to_f
        @size = @vm.drives.inject(0) { | r, d | r += d['SIZE'].to_i } / 1000.0
        return @cost > 0
    rescue
        return false
    end

    # @see Biller#bill
    def bill bill:, state:, delta:, record: nil
        bill[:disk] = delta * @cost * @size
        bill
    end
end
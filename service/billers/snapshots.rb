class SnapshotsBiller < Biller
    def check_biller
        @cost = JSON.parse(costs['SNAPSHOT_COST'])
        return false if @cost.nil?

        @cost = @cost.to_f
        return @cost > 0
    rescue
        return false
    end

    def bill bill:, state:, delta:, record: nil
        bill[:snapshots] = delta * @cost * state[:snaps]
        bill
    end
end
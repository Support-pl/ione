# VM Disk costs biller
class DiskBiller < Biller
  # Checking if Capacity costs are given, otherwise there is no point to calculate it
  def check_biller
    @costs = JSON.parse(costs['DISK_COSTS'])
    res =
      @costs.values.inject(0) do | r, c |
        r += c.to_f
      rescue
        r
      end
    @cost = @costs[@vm['/VM/USER_TEMPLATE/DRIVE']].to_f

    @costs = JSON.parse(costs['BACKUP_IMAGE_COSTS'])
    res +=
      @costs.values.inject(0) do | r, c |
        r += c.to_f
      rescue
        r
      end
    @size = @vm.drives.first['SIZE'].to_i / 1000.0

    return res > 0
  rescue
    return false
  end

  # @see Biller#bill
  def bill bill:, state:, delta:, record: nil
    bill[:disk] = delta * @cost * @size
    for rec in state[:system_disk] do
      bill[:disk] += delta * @cost * rec[:size].to_i / 1000.0
    end if state[:system_disk]
    for rec in state[:backup_disk] do
      bill[:disk] += delta * @costs[rec[:img].to_s].to_f * rec[:size].to_i / 1000.0
    end if state[:backup_disk]
    bill
  end
end

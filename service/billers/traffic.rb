# Biller for VM in- and outbound traffic costs
class TrafficBiller < Biller
  # Checking if Traffic costs are given, otherwise there is no point to calculate it
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

  # @see Biller#bill
  def bill bill:, state:, _delta:, record:
    if record.class == TrafficRecord then
      bill[:rx] = state[:rx] / 1e+9 * @costs[:rx]
      bill[:tx] = state[:tx] / 1e+9 * @costs[:tx]
    end
    bill
  end
end

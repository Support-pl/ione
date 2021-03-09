# Billers parent(actually template) class
# Needed just to describe what does Biller class should be able to do and provides couple of methods
class Biller
  def initialize vm
    @vm = vm
  end

  # Costs hash
  def costs
    SETTINGS_TABLE.as_hash(:name, :body).select { |key| key.include? 'COST' }
  end

  # Check if this biller should be used in Billing !important
  def check_biller
    true
  end

  # Gets VM billing period
  def billing_period
    @vm['//BILLING_PERIOD']
  end

  # Makes bill for given state, delta and record. Modifies :bill hash
  # @return whatever
  def bill _bill:, _state:, _delta:, _record: nil
    0
  end
end

# Import all available billers from service/billers
Dir["#{ROOT}/service/billers/*.rb"].each { |file| require file }

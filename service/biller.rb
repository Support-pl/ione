class Biller

    def initialize vm
        @vm = vm
    end

    # Costs hash
    def costs
        SETTINGS_TABLE.as_hash(:name, :body).select {|key| key.include? 'COST' }
    end

    # Check if this biller should be used in Billing
    def check_biller
        true
    end

    def billing_period
        @vm['//BILLING_PERIOD']
    end

    def bill bill, state, delta
        0
    end
end

Dir["#{ROOT}/service/billers/*.rb"].each {|file| require file }

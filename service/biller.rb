class Biller

    def initialize vm
        @vm = vm
    end

    def costs
        SETTINGS_TABLE.as_hash(:name, :body).select {|key| key.include? 'COST' }
    end

    def check_biller
        true
    end
end

Dir["#{ROOT}/service/billers/*.rb"].each {|file| require file }

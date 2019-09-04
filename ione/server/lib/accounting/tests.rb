# Simple test for an #IaaS_Gate method
def check_total r
    r.each do |key, value|
        next if key == 'TOTAL' || key == 'time_period_requested'
        showback = value['showback']

        if showback.nil? && value.class != Hash then
            print key.to_s.red, ' -- ', value, "\n"
            next
        elsif value.class == Hash && value['EXCEPTION'] == 'No Records' then
            puts "----------------------------#{key.to_s}----------------------------".yellow
            next
        end

        puts "----------------------------#{key.to_s}----------------------------"

        showback.each do | record |
            string = record['CPU'].to_s + ' + '
            string += record['MEMORY'].to_s + ' + '
            string += record['DISK'].to_s + ' + '
            string += record['PUBLIC_IP'].to_s

            string += ' -> ' + (record['CPU'] + record['MEMORY'] + record['DISK'] + record['PUBLIC_IP']).to_s
            string += ' == ' + record['TOTAL'].to_s
            string += ' | ' + record['date']

            if record['CPU'] + record['MEMORY'] + record['DISK'] + record['PUBLIC_IP'] != record['TOTAL'] then
                string = string.red
            else
                string = string.green
            end
            puts string
        end
    end
end
begin
    LOG 'Traffic Recorder has been initialized', 'TrafficRecorder'
    loop do
        begin
            vm_pool = VirtualMachinePool.new($client)
            vm_pool.info_all
            inserts_total = 0

            vm_pool.each do | vm |
                inserts = TrafficRecords.new(vm.id, true).sync vm        
                LOG "VM #{vm.id}: Inserted #{inserts} new traffic records", "TrafficRecorder"
                inserts_total += inserts
            end

            LOG "TrafficRecorder inserted totally #{inserts_total} new traffic records", 'TrafficRecorder'
            sleep($ione_conf['TrafficRecorder']['check-period'])
        rescue => e
            LOG "TrafficRecorder Error, code: #{e.message}\nTrafficRecorder is down now", 'TrafficRecorder'
            sleep(30)
        end
    end
rescue
    LOG "TrafficRecorder fatal error, service is crashed", 'TrafficRecorderThread'
end
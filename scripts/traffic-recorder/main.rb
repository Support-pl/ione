begin
    LOG 'Traffic Recorder has been initialized', 'TrafficRecorder'
    loop do
        begin
            vm_pool = VirtualMachinePool.new($client)
            vm_pool.info_all
            inserts_total = 0

            vm_pool.each do | vm |
                mon = vm.monitoring(['NETTX', 'NETRX'])
                inserts = 0
                for key, data in mon do
                    last = TrafficRecord.where(type: key, vm: vm.id).order(Sequel.asc(:ts)).last
                    last = { ts: 0 } if last.nil?
                    for rec in data do
                        if rec.first.to_i > last[:ts] then
                            TrafficRecord.insert vm: vm.id, ts: rec.first.to_i, val: rec.last, type: key
                            inserts += 1
                        end
                    end
                end
                LOG "VM #{vm.id}: Inserted #{inserts} new traffic records", "TrafficRecorder"
                inserts_total += inserts
            end

            LOG "TrafficRecorder inserted totally #{inserts_total} new traffic records", 'TrafficRecorder'
            sleep($ione_conf['TrafficRecorder']['check-period'])
        rescue => e
            LOG "TrafficRecorder Error, code: #{e.message}\TrafficRecorder is down now", 'TrafficRecorder'
            sleep(30)
        end
    end
rescue
    LOG "TrafficRecorder fatal error, service is crashed", 'TrafficRecorderThread'
end
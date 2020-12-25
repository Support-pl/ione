begin
    LOG 'Traffic Recorder has been initialized', 'TrafficRecorder'
    loop do
        begin
            vm_pool = VirtualMachinePool.new($client)
            vm_pool.info_all
            inserts_total = 0

            vm_pool.each do | vm |
                mon_raw = vm.monitoring(['NETTX', 'NETRX'])
                mon = {}
                mon_raw['NETTX'].each do | el |
                    mon[el.first] = {}
                    mon[el.first][:tx] = el.last
                end
                mon_raw['NETRX'].each do | el |
                    mon[el.first][:rx] = el.last
                end

                inserts = 0
                last = TrafficRecord.where(vm: vm.id).order(Sequel.asc(:ts)).last
                last = { ts: 0 } if last.nil?

                for ts, data in mon do
                    ts = ts.to_i
                    if ts > last[:ts] then
                        args = data.merge(vm: vm.id, ts: ts)
                        TrafficRecord.insert **args
                        inserts += 1
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
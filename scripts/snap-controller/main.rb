begin
  LOG 'Snapshot Controller has been initialized', 'SnapController'
  loop do
    begin
      $snap_controller_status = 'ACTIVE'
      vm_pool = VirtualMachinePool.new($client)
      vm_pool.info_all
      target_vms, out, iter, found = [], "", -1, true
      iter += 1
      while found do
        found = false
        vm_pool.each do | vm |
          target_vms << vm if vm.got_snapshot?
        end
        target_vms.each do | vm |
          active_state = IONe.new($client, $db).LCM_STATE(vm.id) == 3
          LOG "Collecting snaps from #{vm.id}", 'SnapController'
          vm.list_snapshots.each do | snap |
            break if snap.class == Array || snap.nil?

            age = ((Time.now.to_i - snap['TIME'].to_i) / 3600.0).round(2)
            out += "\t|  #{age >= 24 ? 'V' : 'X'}  |  #{active_state ? 'V' : 'X'}  | #{vm.id} |   #{' ' if age < 10}#{age}  | #{snap['NAME']}\n"
            IONe.new($client, $db).RMSnapshot(vm.id, snap['SNAPSHOT_ID'], false) || found if age >= 24 && active_state
          end
        end
        sleep(300) if found
      end
      LOG "Detected snapshots:\n\t| rm? | del | vmid |   age   |          name          \n#{out}\nDeleting snapshots, which marked with 'V'",
          'SnapController'
      $snap_controller_status = 'SLEEP'
      sleep($ione_conf['SnapshotController']['check-period'] - iter * 300)
    rescue => e
      LOG "SnapController Error, code: #{e.message}\nSnapController is down now", 'SnapController'
      sleep(30)
    end
  end
rescue
  LOG "SnapController fatal error, service is crashed", 'SnapControllerThread'
  $snap_controller_status = 'FAIL'
end

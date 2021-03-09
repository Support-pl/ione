desc "Test Capacity Showback"
task :cap_showback_test => :before_test do
  puts "\n####################\n# Testing capacity #\n####################"

  $db[:settings].where(name: "CAPACITY_COST").update(body: "{\"CPU_COST\":\"0.5\",\"MEMORY_COST\":\"0.5\"}")
  $db[:settings].where(name: "DISK_COSTS").update(body: "{\"HDD\":\"0.0\"}")

  r = onblock(:vm, 3).calculate_showback 0, 1200
  if r[:TOTAL] == 600 then
    passed
  else
    warn "0, 1200 => #{r[:TOTAL]}"
  end
  r = onblock(:vm, 3).calculate_showback 300, 1200
  if r[:TOTAL] == 300 then
    passed
  else
    warn "300, 1200 => #{r[:TOTAL]}"
  end
  r = onblock(:vm, 3).calculate_showback 300, 500
  if r[:TOTAL] == 200 then
    passed
  else
    warn "300, 500 => #{r[:TOTAL]}"
  end
  r = onblock(:vm, 3).calculate_showback 300, 1400
  if r[:TOTAL] == 500 then
    passed
  else
    warn "300, 1400 => #{r[:TOTAL]}"
  end
end

desc "Test Disk Showback"
task :disk_showback_test => :before_test do
  puts "\n################\n# Testing Disk #\n################"

  $db[:settings].where(name: "CAPACITY_COST").update(body: "{\"CPU_COST\":\"0.0\",\"MEMORY_COST\":\"0.0\"}")
  $db[:settings].where(name: "DISK_COSTS").update(body: "{\"HDD\":\"1\"}")

  r = onblock(:vm, 3).calculate_showback 0, 1200
  if r[:TOTAL] == 1200 then
    passed
  else
    warn "0, 1200 => #{r[:TOTAL]}"
  end
  r = onblock(:vm, 3).calculate_showback 300, 1200
  if r[:TOTAL] == 900 then
    passed
  else
    warn "300, 1200 => #{r[:TOTAL]}"
  end
  r = onblock(:vm, 3).calculate_showback 300, 500
  if r[:TOTAL] == 200 then
    passed
  else
    warn "300, 500 => #{r[:TOTAL]}"
  end
  r = onblock(:vm, 3).calculate_showback 300, 1400
  if r[:TOTAL] == 1100 then
    passed
  else
    warn "300, 1400 => #{r[:TOTAL]}"
  end
end

desc "Showback Tests"
task :showback_test => [:cap_showback_test, :disk_showback_test] do; end

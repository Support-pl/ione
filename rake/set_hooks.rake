$: << '/usr/lib/one/ruby'
require 'opennebula'

@hooks = [
  {
    "NAME" => 'set-price',
    "TYPE" => 'api',
    "CALL" => 'one.vm.allocate',
    "COMMAND" => '/usr/lib/one/ione/hooks/set_price.rb',
    "ARGUMENTS" => '$API'
  },
  {
    "NAME" => 'check-balance-vm-allocate',
    "TYPE" => 'api',
    "CALL" => 'one.vm.allocate',
    "COMMAND" => '/usr/lib/one/ione/hooks/check_balance.rb vm',
    "ARGUMENTS" => '$API'
  },
  {
    "NAME" => 'check-balance-tmpl-instantiate',
    "TYPE" => 'api',
    "CALL" => 'one.template.instantiate',
    "COMMAND" => '/usr/lib/one/ione/hooks/check_balance.rb tmpl',
    "ARGUMENTS" => '$API'
  },
  {
    "NAME" => 'insert-zero-traffic-record-vm-allocate',
    "TYPE" => 'api',
    "CALL" => 'one.vm.allocate',
    "COMMAND" => '/usr/lib/one/ione/hooks/insert_zero_traffic_record.rb vm',
    "ARGUMENTS" => '$API'
  },
  {
    "NAME" => 'insert-zero-traffic-record-tmpl-instantiate',
    "TYPE" => 'api',
    "CALL" => 'one.template.instantiate',
    "COMMAND" => '/usr/lib/one/ione/hooks/insert_zero_traffic_record.rb tmpl',
    "ARGUMENTS" => '$API'
  },
  {
    "NAME" => 'pending',
    "ON" => "CUSTOM",
    "STATE" => "PENDING",
    "LCM_STATE" => "LCM_INIT",
    "COMMAND" => "/usr/lib/one/ione/hooks/record.rb",
    "ARGUMENTS" => "\$TEMPLATE pnd",
    "TYPE" => "state",
    "RESOURCE" => "VM"
  },
  {
    "NAME" => 'hold',
    "ON" => "CUSTOM",
    "STATE" => "HOLD",
    "LCM_STATE" => "LCM_INIT",
    "COMMAND" => "/usr/lib/one/ione/hooks/record.rb",
    "ARGUMENTS" => "\$TEMPLATE pnd",
    "TYPE" => "state",
    "RESOURCE" => "VM"
  },
  {
    "NAME" => 'active-boot',
    "ON" => "CUSTOM",
    "STATE" => "ACTIVE",
    "LCM_STATE" => "BOOT",
    "COMMAND" => "/usr/lib/one/ione/hooks/record.rb",
    "ARGUMENTS" => "\$TEMPLATE on",
    "TYPE" => "state",
    "RESOURCE" => "VM"
  },
  {
    "NAME" => 'active-running',
    "ON" => "CUSTOM",
    "STATE" => "ACTIVE",
    "LCM_STATE" => "RUNNING",
    "COMMAND" => "/usr/lib/one/ione/hooks/record.rb",
    "ARGUMENTS" => "\$TEMPLATE on",
    "TYPE" => "state",
    "RESOURCE" => "VM"
  },
  {
    "NAME" => 'inactive-stopped',
    "ON" => "CUSTOM",
    "STATE" => "STOPPED",
    "LCM_STATE" => "LCM_INIT",
    "COMMAND" => "/usr/lib/one/ione/hooks/record.rb",
    "ARGUMENTS" => "\$TEMPLATE off",
    "TYPE" => "state",
    "RESOURCE" => "VM"
  },
  {
    "NAME" => 'inactive-suspended',
    "ON" => "CUSTOM",
    "STATE" => "SUSPENDED",
    "LCM_STATE" => "LCM_INIT",
    "COMMAND" => "/usr/lib/one/ione/hooks/record.rb",
    "ARGUMENTS" => "\$TEMPLATE off",
    "TYPE" => "state",
    "RESOURCE" => "VM"
  },
  {
    "NAME" => 'inactive-done',
    "ON" => "CUSTOM",
    "STATE" => "DONE",
    "LCM_STATE" => "LCM_INIT",
    "COMMAND" => "/usr/lib/one/ione/hooks/record.rb",
    "ARGUMENTS" => "\$TEMPLATE off",
    "TYPE" => "state",
    "RESOURCE" => "VM"
  },
  {
    "NAME" => 'inactive-poweroff',
    "ON" => "CUSTOM",
    "STATE" => "POWEROFF",
    "LCM_STATE" => "LCM_INIT",
    "COMMAND" => "/usr/lib/one/ione/hooks/record.rb",
    "ARGUMENTS" => "\$TEMPLATE off",
    "TYPE" => "state",
    "RESOURCE" => "VM"
  },
  {
    "NAME" => 'set-limits',
    "ON" => "RUNNING",
    "COMMAND" => "/usr/lib/one/ione/hooks/vcenter/set_limits.rb",
    "ARGUMENTS" => "$ID $PREV_STATE $PREV_LCM_STATE",
    "TYPE" => "state",
    "RESOURCE" => "VM"
  },
  {
    "NAME" => 'reserve-ar-on-create',
    "TYPE" => 'api',
    "CALL" => 'one.user.allocate',
    "COMMAND" => '/usr/lib/one/ione/hooks/set_ar.rb',
    "ARGUMENTS" => '$API'
  },
  {
    "NAME" => 'release-ar-on-remove',
    "TYPE" => 'api',
    "CALL" => 'one.user.delete',
    "COMMAND" => '/usr/lib/one/ione/hooks/remove_ar.rb',
    "ARGUMENTS" => '$API'
  },
  {
    "NAME" => 'vn-record-crt',
    "TYPE" => 'api',
    "CALL" => 'one.vn.allocate',
    "COMMAND" => '/usr/lib/one/ione/hooks/vn_record.rb',
    "ARGUMENTS" => '$API crt'
  },
  {
    "NAME" => 'vn-record-del',
    "TYPE" => 'api',
    "CALL" => 'one.vn.delete',
    "COMMAND" => '/usr/lib/one/ione/hooks/vn_record.rb',
    "ARGUMENTS" => '$API del'
  },
  {
    "NAME" => 'disk-attach-record',
    "TYPE" => 'api',
    "CALL" => 'one.vm.attach',
    "COMMAND" => '/usr/lib/one/ione/hooks/disk_record_crt.rb',
    "ARGUMENTS" => '$API'
  },
  {
    "NAME" => 'disk-detach-record',
    "TYPE" => 'api',
    "CALL" => 'one.vm.detach',
    "COMMAND" => '/usr/lib/one/ione/hooks/disk_record_del.rb',
    "ARGUMENTS" => '$API'
  }
]

desc "Setting needed Hooks"
task :hooks do
  if defined? @src_dir then
    cd @src_dir

    puts 'Copying hooks scripts'
    cp_r "hooks", "/usr/lib/one/ione/"
    chmod_R "+x", "/usr/lib/one/ione/hooks/"
  end

  require 'colorize'
  require '/usr/lib/one/ione/lib/std++/main.rb'

  puts 'Adding hooks to HookPool'
  for hook in @hooks do
    rc = OpenNebula::Hook.new_with_id(0, OpenNebula::Client.new).allocate(hook.to_one_template)
    if OpenNebula.is_error? rc then
      puts "#{hook['NAME']}#{' ' * (48 - hook['NAME'].size)}--- X".red
    else
      puts "#{hook['NAME']}#{' ' * (48 - hook['NAME'].size)}--- V".green
    end
  end
end

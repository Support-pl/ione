require 'opennebula'

@hooks = [
  {
    "NAME" => 'set-price',
    "TYPE" => 'api',
    "CALL" => 'one.vm.allocate',
    "COMMAND" => 'set_price.rb',
    "ARGUMENTS" => '$API'
  },
  {
    "NAME" => 'check-balance-vm-allocate',
    "TYPE" => 'api',
    "CALL" => 'one.vm.allocate',
    "COMMAND" => 'check_balance.rb vm',
    "ARGUMENTS" => '$API'
  },
  {
    "NAME" => 'check-balance-tmpl-instantiate',
    "TYPE" => 'api',
    "CALL" => 'one.template.instantiate',
    "COMMAND" => 'check_balance.rb tmpl',
    "ARGUMENTS" => '$API'
  },
  {
    "NAME" => 'insert-zero-traffic-record-vm-allocate',
    "TYPE" => 'api',
    "CALL" => 'one.vm.allocate',
    "COMMAND" => 'insert_zero_traffic_record.rb vm',
    "ARGUMENTS" => '$API'
  },
  {
    "NAME" => 'insert-zero-traffic-record-tmpl-instantiate',
    "TYPE" => 'api',
    "CALL" => 'one.template.instantiate',
    "COMMAND" => 'insert_zero_traffic_record.rb tmpl',
    "ARGUMENTS" => '$API'
  },
  {
    "NAME" => 'pending',
    "ON" => "CUSTOM",
    "STATE" => "PENDING",
    "LCM_STATE" => "LCM_INIT",
    "COMMAND" => "record.rb",
    "ARGUMENTS" => "\$TEMPLATE pnd",
    "TYPE" => "state",
    "RESOURCE" => "VM"
  },
  {
    "NAME" => 'hold',
    "ON" => "CUSTOM",
    "STATE" => "HOLD",
    "LCM_STATE" => "LCM_INIT",
    "COMMAND" => "record.rb",
    "ARGUMENTS" => "\$TEMPLATE pnd",
    "TYPE" => "state",
    "RESOURCE" => "VM"
  },
  {
    "NAME" => 'active-boot',
    "ON" => "CUSTOM",
    "STATE" => "ACTIVE",
    "LCM_STATE" => "BOOT",
    "COMMAND" => "record.rb",
    "ARGUMENTS" => "\$TEMPLATE on",
    "TYPE" => "state",
    "RESOURCE" => "VM"
  },
  {
    "NAME" => 'active-running',
    "ON" => "CUSTOM",
    "STATE" => "ACTIVE",
    "LCM_STATE" => "RUNNING",
    "COMMAND" => "record.rb",
    "ARGUMENTS" => "\$TEMPLATE on",
    "TYPE" => "state",
    "RESOURCE" => "VM"
  },
  {
    "NAME" => 'inactive-stopped',
    "ON" => "CUSTOM",
    "STATE" => "STOPPED",
    "LCM_STATE" => "LCM_INIT",
    "COMMAND" => "record.rb",
    "ARGUMENTS" => "\$TEMPLATE off",
    "TYPE" => "state",
    "RESOURCE" => "VM"
  },
  {
    "NAME" => 'inactive-suspended',
    "ON" => "CUSTOM",
    "STATE" => "SUSPENDED",
    "LCM_STATE" => "LCM_INIT",
    "COMMAND" => "record.rb",
    "ARGUMENTS" => "\$TEMPLATE off",
    "TYPE" => "state",
    "RESOURCE" => "VM"
  },
  {
    "NAME" => 'inactive-done',
    "ON" => "CUSTOM",
    "STATE" => "DONE",
    "LCM_STATE" => "LCM_INIT",
    "COMMAND" => "record.rb",
    "ARGUMENTS" => "\$TEMPLATE off",
    "TYPE" => "state",
    "RESOURCE" => "VM"
  },
  {
    "NAME" => 'inactive-poweroff',
    "ON" => "CUSTOM",
    "STATE" => "POWEROFF",
    "LCM_STATE" => "LCM_INIT",
    "COMMAND" => "record.rb",
    "ARGUMENTS" => "\$TEMPLATE off",
    "TYPE" => "state",
    "RESOURCE" => "VM"
  },
  {
    "NAME" => 'set-limits',
    "ON" => "RUNNING",
    "COMMAND" => "vcenter/set_limits.rb",
    "ARGUMENTS" => "$TEMPLATE",
    "TYPE" => "state",
    "RESOURCE" => "VM"
  },
  {
    "NAME" => 'check-running-state',
    "ON" => "CUSTOM",
    "STATE" => "ACTIVE",
    "LCM_STATE" => "RUNNING",
    "ARGUMENTS" => "$TEMPLATE",
    "COMMAND" => "vcenter/check_running_state.rb",
    "TYPE" => "state",
    "RESOURCE" => "VM"
  },
  {
    "NAME" => 'user-create-networking-setup',
    "TYPE" => 'api',
    "CALL" => 'one.user.allocate',
    "COMMAND" => 'user_create_networking_setup.rb',
    "ARGUMENTS" => '$API'
  },
  {
    "NAME" => 'user-post-delete-clean-up',
    "TYPE" => 'api',
    "CALL" => 'one.user.delete',
    "COMMAND" => 'user_post_delete_clean_up.rb',
    "ARGUMENTS" => '$API'
  },
  {
    "NAME" => 'vn-record-crt',
    "TYPE" => 'api',
    "CALL" => 'one.vn.allocate',
    "COMMAND" => 'vn_record.rb',
    "ARGUMENTS" => '$API crt'
  },
  {
    "NAME" => 'vn-record-del',
    "TYPE" => 'api',
    "CALL" => 'one.vn.delete',
    "COMMAND" => 'vn_record.rb',
    "ARGUMENTS" => '$API del'
  },
  {
    "NAME" => 'disk-attach-record',
    "TYPE" => 'api',
    "CALL" => 'one.vm.attach',
    "COMMAND" => 'disk_record_crt.rb',
    "ARGUMENTS" => '$API'
  },
  {
    "NAME" => 'disk-detach-record',
    "TYPE" => 'api',
    "CALL" => 'one.vm.detach',
    "COMMAND" => 'disk_record_del.rb',
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

    cp "hooks/web_hook.rb", "/var/lib/one/remotes/hooks/web_hook.rb"
    chmod "+x", "/var/lib/one/remotes/hooks/web_hook.rb"
  end

  begin
    require 'colorize'
  rescue
    class String
      def red
        self
      end

      def green
        self
      end
    end
  end

  ENV["ONE_CREDENTIALS"] = OpenNebula::Client.new.one_auth
  ENV["ONE_ENDPOINT"] = OpenNebula::Client.new.one_endpoint
  ENV["IONE_LOCATION"] = "/usr/lib/one/ione"
  Rake::Task["hooks_tp"].invoke
end

desc "Setting needed hooks in Container environment"
task :hooks_tp do
  client = OpenNebula::Client.new(ENV["ONE_CREDENTIALS"], ENV["ONE_ENDPOINT"])

  user = OpenNebula::User.new_with_id(-1, client)
  begin
    print "Connecting to OpenNebula XML-RPC API... "
    rc = user.info!
    raise if OpenNebula.is_error? rc
  rescue
    puts "Error!"
    puts rc.message
    print "Retrying in 30sec... "
    sleep 30
    retry
  end

  $: << ENV["IONE_LOCATION"]
  require 'lib/std++/main.rb'

  for hook in @hooks do
    print "Allocating hook #{hook['NAME']}... "
    hook["ARGUMENTS"] = hook["COMMAND"] + ' ' + hook["ARGUMENTS"]
    hook["COMMAND"] = '/var/lib/one/remotes/hooks/web_hook.rb'

    rc = OpenNebula::Hook.new_with_id(0, client).allocate(hook.to_one_template)
    if OpenNebula.is_error? rc then
      puts "Error: " + rc.message
    else
      puts "Success: #{rc}"
    end
  end

  chmod_R "+x", "#{ENV["IONE_LOCATION"]}/hooks/"
end

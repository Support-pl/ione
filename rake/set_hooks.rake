$: << '/usr/lib/one/ruby'
require 'opennebula'
require '/usr/lib/one/ione/lib/std++/main.rb'

@hooks = [
    {
        "NAME" => 'set-price',
        "TYPE" => 'api',
        "CALL" => 'one.vm.allocate',
        "COMMAND" => 'set_price.rb',
        "ARGUMENTS" => '$API'
    },
    {
        "NAME" => 'pending',
        "ON" => "CUSTOM",
        "STATE" => "PENDING",
        "LCM_STATE" => "LCM_INIT",
        "COMMAND" => "record.rb",
        "ARGUMENTS" => "$ID",
        "TYPE" => "state",
        "RESOURCE" => "VM"
    },
    {
        "NAME" => 'hold',
        "ON" => "CUSTOM",
        "STATE" => "HOLD",
        "LCM_STATE" => "LCM_INIT",
        "COMMAND" => "record.rb",
        "ARGUMENTS" => "$ID",
        "TYPE" => "state",
        "RESOURCE" => "VM"
    },
    {
        "NAME" => 'active-boot',
        "ON" => "CUSTOM",
        "STATE" => "ACTIVE",
        "LCM_STATE" => "BOOT",
        "COMMAND" => "record.rb",
        "ARGUMENTS" => "$ID",
        "TYPE" => "state",
        "RESOURCE" => "VM"
    },
    {
        "NAME" => 'active-running',
        "ON" => "CUSTOM",
        "STATE" => "ACTIVE",
        "LCM_STATE" => "RUNNING",
        "COMMAND" => "record.rb",
        "ARGUMENTS" => "$ID",
        "TYPE" => "state",
        "RESOURCE" => "VM"
    },
    {
        "NAME" => 'inactive-stopped',
        "ON" => "CUSTOM",
        "STATE" => "STOPPED",
        "LCM_STATE" => "LCM_INIT",
        "COMMAND" => "record.rb",
        "ARGUMENTS" => "$ID",
        "TYPE" => "state",
        "RESOURCE" => "VM"
    },
    {
        "NAME" => 'inactive-suspended',
        "ON" => "CUSTOM",
        "STATE" => "SUSPENDED",
        "LCM_STATE" => "LCM_INIT",
        "COMMAND" => "record.rb",
        "ARGUMENTS" => "$ID",
        "TYPE" => "state",
        "RESOURCE" => "VM"
    },
    {
        "NAME" => 'inactive-done',
        "ON" => "CUSTOM",
        "STATE" => "DONE",
        "LCM_STATE" => "LCM_INIT",
        "COMMAND" => "record.rb",
        "ARGUMENTS" => "$ID",
        "TYPE" => "state",
        "RESOURCE" => "VM"
    },
    {
        "NAME" => 'inactive-poweroff',
        "ON" => "CUSTOM",
        "STATE" => "POWEROFF",
        "LCM_STATE" => "LCM_INIT",
        "COMMAND" => "record.rb",
        "ARGUMENTS" => "$ID",
        "TYPE" => "state",
        "RESOURCE" => "VM"
    },
    {
        "NAME" => 'set-limits',
        "ON" => "RUNNING",
        "COMMAND" => "vcenter/set_limits.rb",
        "ARGUMENTS" => "$ID $PREV_STATE $PREV_LCM_STATE",
        "TYPE" => "state",
        "RESOURCE" => "VM"
    },
    {
        "NAME" => 'reserve-ar-on-create',
        "TYPE" => 'api',
        "CALL" => 'one.user.allocate',
        "COMMAND" => 'set_ar.rb',
        "ARGUMENTS" => '$API'
    },
    {
        "NAME" => 'release-ar-on-remove',
        "TYPE" => 'api',
        "CALL" => 'one.user.delete',
        "COMMAND" => 'set_ar.rb',
        "ARGUMENTS" => '$API'
    },
    {
        "NAME" => 'vn-record-crt',
        "TYPE" => 'api',
        "CALL" => 'one.vn.add_ar',
        "COMMAND" => 'vn_record.rb',
        "ARGUMENTS" => '$API crt'
    },
    {
        "NAME" => 'vn-record-del',
        "TYPE" => 'api',
        "CALL" => 'one.vn.rm_ar',
        "COMMAND" => 'vn_record.rb',
        "ARGUMENTS" => '$API del'
    }
]

task :hooks do
    puts 'Copying hooks scripts'
    cp_r "hooks", "/var/lib/one/remotes/"
    chmod_R "+x", "/var/lib/one/remotes/hooks/"

    puts 'Adding hooks to HookPool'
    for hook in @hooks do
        OpenNebula::Hook.new_with_id(0, OpenNebula::Client.new).allocate(hook.to_one_template)
    end
end
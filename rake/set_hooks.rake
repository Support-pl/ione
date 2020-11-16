@hooks_conf = <<-EOF

#**********************************#
# Hooks for IONe                   #
#**********************************#
# You can move it to hook section  #
#**********************************#

VM_HOOK = [
    name      = "set_price",
    on        = "CREATE",
    command   = "set_price.rb",
    arguments = "$ID"
]

VM_HOOK = [
    name      = "pending",
    on        = "CUSTOM",
    state     = "PENDING",
    lcm_state = "LCM_INIT",
    command   = "record.rb",
    arguments = "$ID" ]

VM_HOOK = [
    name      = "pending",
    on        = "CUSTOM",
    state     = "HOLD",
    lcm_state = "LCM_INIT",
    command   = "record.rb",
    arguments = "$ID" ]

VM_HOOK = [
    name      = "active",
    on        = "CUSTOM",
    state     = "ACTIVE",
    lcm_state = "BOOT",
    command   = "record.rb",
    arguments = "$ID" ]

VM_HOOK = [
    name      = "active",
    on        = "CUSTOM",
    state     = "ACTIVE",
    lcm_state = "RUNNING",
    command   = "record.rb",
    arguments = "$ID" ]

VM_HOOK = [
    name      = "inactive",
    on        = "CUSTOM",
    state     = "STOPPED",
    lcm_state = "LCM_INIT",
    command   = "record.rb",
    arguments = "$ID" ]

VM_HOOK = [
    name      = "inactive",
    on        = "CUSTOM",
    state     = "SUSPENDED",
    lcm_state = "LCM_INIT",
    command   = "record.rb",
    arguments = "$ID" ]

VM_HOOK = [
    name      = "inactive",
    on        = "CUSTOM",
    state     = "DONE",
    lcm_state = "LCM_INIT",
    command   = "record.rb",
    arguments = "$ID" ]

VM_HOOK = [
    name      = "inactive",
    on        = "CUSTOM",
    state     = "POWEROFF",
    lcm_state = "LCM_INIT",
    command   = "record.rb",
    arguments = "$ID" ]

VM_HOOK = [
    name      = "set_limits",
    on        = "RUNNING",
    command   = "vcenter/set_limits.rb",
    arguments = "$ID $PREV_STATE $PREV_LCM_STATE" ]


USER_HOOK = [
    name = "reserve_ar_on_create",
    on = "CREATE",
    command = "set_ar.rb",
    arguments = "$ID" ]

USER_HOOK = [
    name = "release_ar_on_remove",
    on = "REMOVE",
    command = "remove_ar.rb",
    arguments = "$TEMPLATE" ]

VNET_HOOK = [
    name        = "vn_record",
    on          = "CREATE",
    command     = "vn_record.rb",
    arguments   = "$ID"
]
VNET_HOOK = [
    name        = "vn_record",
    on          = "REMOVE",
    command     = "vn_record.rb",
    arguments   = "$ID"
]

EOF

task :hooks do
    puts 'Copying hooks'
    cp_r "hooks", "/var/lib/one/remotes/"
    chmod_R "+x", "/var/lib/one/remotes/hooks/"

    puts 'Appending hooks to oned.conf'
    File.open('/etc/one/oned.conf', 'a') do | conf |
        conf << @hooks_conf
    end
end
`gem install shell`
require 'shell'
sh = Shell.new

#####################################
# Setting ENV
#####################################

src_dir = sh.pwd

#####################################
# Installing packages
#####################################

puts "Installing NPM and zeromq"
sh.system `yum install -y npm make automake gcc gcc-c++ kernel-devel ruby-devel zeromq zeromq-devel`

puts "Installing bower and grunt"
sh.system 'npm install -g bower grunt grunt-cli'

puts "Setting hooks up"
sh.system "cp -rf hooks /usr/lib/one/remotes/" 

puts "Moving sunstone src files"
sunstone = %w(
    models public routes views ione
)

sh.system "chown oneadmin -R ./* && chgrp oneadmin -R ./*"

sunstone.each do | files |
    sh.system "cp -rf #{files} /usr/lib/one/sunstone/"
end
sh.system "cp sunstone-server.rb /usr/lib/one/sunstone/"
sh.system "cp config.ru /usr/lib/one/sunstone/"
sh.system 'cp Gemfile /usr/lib/one/sunstone'

sh.cd '/usr/lib/one/sunstone/public'

puts "Installung bower and NPM packages"
sh.system 'npm install && bower install --allow-root'

puts "Building source"
sh.system 'grunt requirejs'

puts "Installing gems for IONe"
sh.system 'bundle install'

sh.cd src_dir

sh.system 'cp -f ./sunstone-views.yaml /etc/one/'
sh.system 'cp -rf ./sunstone-views /etc/one/'
# sh.system 'cp -f ./ione/ione.conf /etc/one/'

puts 'Appending hooks to oned.conf'

hooks = 
'VM_HOOK = [
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
'

hooks +=
'USER_HOOK = [
    name = "reserve_ar_on_create",
    on = "CREATE",
    command = "set_ar.rb",
    arguments = "$ID" ]

USER_HOOK = [
    name = "release_ar_on_remove",
    on = "REMOVE",
    command = "remove_ar.rb",
    arguments = "$TEMPLATE" ]
'

File.open('/etc/one/oned.conf', 'a') do conf
    conf << hooks
end
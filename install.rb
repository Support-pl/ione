whoami = `whoami`.chomp
unless whoami == 'root' then
    puts "You must be oneadmin to avoid problems with installing packages"
    exit(-1)
end

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
sh.system 'sudo yum install -y npm make automake gcc gcc-c++ kernel-devel ruby-devel zeromq zeromq-devel'

puts "Installing bower and grunt"
sh.system 'sudo npm install -g bower grunt grunt-cli'

puts "Setting hooks up"
sh.system "sudo cp -rf hooks /var/lib/one/remotes/"
sh.system "sudo chmod -R +x /var/lib/one/remotes/"

puts "Moving sunstone src files"
sunstone = %w(
    models public routes views ione
)

sunstone.each do | files |
    sh.system "sudo cp -rf #{files} /usr/lib/one/sunstone/"
end
sh.system "sudo cp sunstone-server.rb /usr/lib/one/sunstone/"
sh.system "sudo cp config.ru /usr/lib/one/sunstone/"
sh.system "sudo chown oneadmin:oneadmin -R /usr/lib/one/sunstone"

sh.system "sudo cp -f sunstone-views.yaml /etc/one/"
sh.system "sudo chown oneadmin:oneadmin /etc/one/sunstone-views.yaml"
sh.system "sudo chmod 775 /etc/one/sunstone-views.yaml"
sh.system "sudo cp -rf sunstone-views /etc/one/"
sh.system "sudo chown -R oneadmin:oneadmin /etc/one/sunstone-views"
sh.system "sudo chmod -R 775 /etc/one/sunstone-views"

puts "Appending gems to Gemfile"
sh.system('sudo chown -R oneadmin:oneadmin /usr/share/one/')
gems = File.read('Gemfile')
File.open('/usr/share/one/Gemfile', 'a') do | gemfile |
    gemfile << "\n# Gems for IONe\n"
    gemfile << gems
end

sh.cd '/usr/lib/one/sunstone/public'

puts "Installung bower and NPM packages"
sh.system 'sudo npm install && bower install --allow-root'

puts "Building source"
sh.system 'sudo ./build.sh'
sh.system 'sudo cp -f ./dist/main-dist.js ./dist/main.js'

puts "Installing gems for IONe"
sh.cd '..'
# sh.system 'bundle install'
sh.system 'echo | sudo /usr/share/one/install_gems'

sh.cd src_dir

sh.system 'sudo cp -f ./sunstone-views.yaml /etc/one/'
sh.system 'sudo cp -rf ./sunstone-views /etc/one/'
sh.system 'cp -f ./ione/ione.conf /etc/one/'

puts 'Appending hooks to oned.conf'

hooks = "#*******************************************************************************" \
        "# Appending hooks for IONe" \
        "#*******************************************************************************" \
        "# You can move it to hook section" \
        "#*******************************************************************************"

hooks.gsub!("#", "\n#")
hooks += "\n\n"

hooks += 
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

File.open('/etc/one/oned.conf', 'a') do | conf |
    conf << hooks
end

puts "Creating log files"
sh.system "touch /var/log/one/ione.log"
sh.system "touch /var/log/one/debug.log"
sh.system "chown oneadmin:oneadmin /var/log/one/*"
sh.system "chmod 700 /var/log/one/*"

puts "Restarting one.d, Sunstone and httpd"
sh.system "sudo systemctl restart opennebula && systemctl status opennebula"
sh.system "sudo systemctl restart opennebula-sunstone && systemctl status opennebula-sunstone"
sh.system "sudo systemctl restart httpd && systemctl status httpd"
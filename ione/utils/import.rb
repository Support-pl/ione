###########################################
# Setting up Environment                   #
###########################################
ONE_LOCATION=ENV["ONE_LOCATION"]
if !ONE_LOCATION
    RUBY_LIB_LOCATION="/usr/lib/one/ruby"
else
    RUBY_LIB_LOCATION=ONE_LOCATION+"/lib/ruby"
end
$: << RUBY_LIB_LOCATION
require "opennebula"
include OpenNebula
###########################################
# OpenNebula credentials
CREDENTIALS = 'oneadmin:secret'
# XML_RPC endpoint where OpenNebula is listening
ENDPOINT = 'http://localhost:2633/RPC2'
$client = Client.new(CREDENTIALS, ENDPOINT)

host_pool = HostPool.new($client)
host_pool.info_all

host_pool.each do |h|
    puts "#{h.id} -- #{h.name}"
end
print 'Выбрать кластер(id): '
host = Host.new(Host.build_xml(gets.to_i), $client)
puts
host.info!
wilds = host.importable_wilds
for i in 0..(wilds.size - 1) do
    puts "#{i.to_s}. #{wilds[i]['VM_NAME']}"
end
print 'Выбрать ВМ для импортирования: '
require 'base64'
template = Base64::decode64 wilds[gets.to_i]['IMPORT_TEMPLATE']

xml = OpenNebula::VirtualMachine.build_xml
vm = OpenNebula::VirtualMachine.new(xml, $client)

rc = vm.allocate(template)
result = rc if OpenNebula.is_error?(rc)
loop do
    vm.update("
        NIC = [
        BRIDGE = \"#{print 'Ввести название сети(btk-unlim/btk-inet): ' || gets.to_s.chomp}\",
        IP = \"#{print 'Ввести IP адрес ВМ: ' || gets.to_s.chomp}\",
        MAC = \"#{print 'Ввести MAC адрес' || gets.to_s.chomp}\",
        NIC_ID = \"0\",
        SECURITY_GROUPS = \"0\",
        VN_MAD = \"dummy\" ]
    ")
    print 'Все ли данные верны?(y/n): '
    break if gets.to_s.chomp == 'y'
end


vm.deploy(host.id, false)
result = vm.id

puts rc
puts result
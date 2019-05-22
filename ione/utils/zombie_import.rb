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

vm, template = {}, ""
print "Enter vm bios id: "
vm['DEPLOY_ID'] = gets.to_s.chomp
print "Enter vm name at cluster: "
vm['VM_NAME'] = gets.to_s.chomp
print "Enter cluster name: "
cluster = gets.to_s.chomp
print "Enter CPU, vCPU and RAM: "
specs = gets.to_s.chomp.split(' ')
print "Enter current vm-state(RUNNING or POWEROFF): "
state = gets.to_s.chomp
print "Enter current guest IP address: "
ip = gets.to_s.chomp
print "Enter current guest MAC address:"
mac = gets.to_s.chomp
print "Enter current ESX host: "
esx = gets.to_s.chomp
print "Enter id, that vm will get after import: "
id = gets.to_i
vm['ID'] = id.to_s
template = "NAME = \"#{vm['VM_NAME']}\"
CPU = \"#{specs.first}\"
vCPU = \"#{specs[1]}\"
MEMORY = \"#{specs.last}\"
HYPERVISOR = \"vcenter\"
PUBLIC_CLOUD = [
  TYPE        =\"vcenter\",
  VM_TEMPLATE =\"#{vm['DEPLOY_ID']}\",
  HOST        =\"#{cluster}\"
]
GRAPHICS = [
    LISTEN = \"0.0.0.0\",
    PORT = \"#{5900 + id}\",
    TYPE = \"VNC\"
]
NIC = [
    IP = \"#{ip}\",
    MAC = \"#{mac}\",
    NETWORK = \"btk-inet - vOne\",
    NETWORK_UNAME = \"CloudAdmin\",
    SECURITY_GROUPS = \"0\"
]
IMPORT_VM_ID = \"#{vm['DEPLOY_ID']}\"
IMPORT_STATE = \"#{state.upcase}\"
SCHED_REQUIREMENTS = \"NAME=\\\"#{cluster}\\\"\"
DESCRIPTION = \"vCenter Virtual Machine imported by OpenNebula from Cluster #{cluster}\""
require 'base64'
vm['IMPORT_TEMPLATE'] = Base64.encode64(template)
puts "You have: "
puts template

print "Let's get the party started?(yes/no):"
if gets.to_s.chomp != 'yes' then
    Kernel.exit
end

puts "Party is here..."
host = Host.new(Host.build_xml(0), $client)
host.info!
wild = vm
template = Base64.decode64(wild['IMPORT_TEMPLATE'])

xml = OpenNebula::VirtualMachine.build_xml
vm = OpenNebula::VirtualMachine.new(xml, $client)

vcenter_wild_vm = wild.key? "VCENTER_TEMPLATE"
if vcenter_wild_vm
    require 'vcenter_driver'
    host_id = 0
    vm_ref  = wild["DEPLOY_ID"]
    return VCenterDriver::Importer.import_wild(host_id, vm_ref, vm, template)
else
    rc = vm.allocate(template)
    result = rc if OpenNebula.is_error?(rc)
    vm.deploy(0, false)
    result = vm.id
end

puts rc
puts result
begin
    puts result.message
rescue => e
    Kernel.exit
end
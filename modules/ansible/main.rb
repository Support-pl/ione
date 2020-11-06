########################################################
#               Ansible Playbooks runner               #
########################################################

puts 'Initializing Ansible constants'
# Hostname or IP-address of host where ansible installed
ANSIBLE_HOST = $ione_conf['AnsibleServer']['host']
# Ansible-host SSH-port
ANSIBLE_HOST_PORT = $ione_conf['AnsibleServer']['port']
# SSH user to user
ANSIBLE_HOST_USER = $ione_conf['AnsibleServer']['user']
require 'net/ssh'
require 'net/sftp'

require "#{ROOT}/modules/ansible/db.rb"

puts 'Extending handler class by AnsibleController'

class IONe
    # Runs given playbook on given host
    # @param [Hash] params - Parameters for Ansible execution
    # @option params [String] host - hostname or IP-address of VM where to run playbook in host:port format
    # @option params [Array] services - services to run on VM
    # @return [200]
    # @example
    #   {
    #     'host' => '127.0.0.1:22',
    #     'services' => [
    #       'playbook0' => 'playbook0 body',
    #       'playbook1' => 'playbook1 body'
    #     ]
    def AnsibleController(params)
        LOG_DEBUG params.merge!({:method => __method__.to_s}).debug_out
        host, playbooks = params['host'], params['services']
        ip, err = host.split(':').first, ""
        Thread.new do
            playbooks.each do |service, playbook|
                installid = id_gen.crypt(service.delete(' ')[0..3]).delete('!@#$%^&*()_+:"\'.,\/\\')
                LOG "#{service} should be installed on #{ip}, installation ID is: #{installid}", "AnsibleController"
                begin
                    LOG 'Connecting to Ansible', 'AnsibleController'            
                    err = "Line #{__LINE__ + 1}: Error while connecting to Ansible-server"
                    Net::SSH.start(ANSIBLE_HOST, ANSIBLE_HOST_USER, :port => ANSIBLE_HOST_PORT) do | ssh |
                        err = "Line #{__LINE__ + 1}: Error while creating temporary playbook file occurred"
                        File.open("/tmp/#{installid}.yml", 'w') { |file| file.write(playbook.gsub('<%group%>', installid)) }
                        err = "Line #{__LINE__ + 1}: Error while uploading playbook occurred"
                        ssh.sftp.upload!("/tmp/#{installid}.yml", "/tmp/#{installid}.yml")
                        err = "Line #{__LINE__ + 1}: Error while creating temporary ansible-inventory file occurred"
                        File.open("/tmp/#{installid}.ini", 'w') { |file| file.write("[#{installid}]\n#{host}\n") }
                        err = "Line #{__LINE__ + 1}: Error while uploading ansible-inventory occurred"
                        ssh.sftp.upload!("/tmp/#{installid}.ini", "/tmp/#{installid}.ini")
                        Thread.exit if params['upload']
                        LOG 'PB and hosts have been generated', 'AnsibleController' 
                        err = "Line #{__LINE__ + 1}: Error while executing playbook occured"
                        LOG 'Executing PB', 'AnsibleController' 
                        ssh.exec!("ansible-playbook /tmp/#{installid}.yml -i /tmp/#{installid}.ini")
                        LOG 'PB has been Executed', 'AnsibleController' 
                        LOG "#{service} installed on #{ip}", "AnsibleController"
                        LOG 'Wiping hosts and pb files', 'AnsibleController' 
                        ssh.sftp.remove!("/tmp/#{installid}.ini")
                        File.delete("/tmp/#{installid}.ini")
                        ssh.sftp.remove!("/tmp/#{installid}.yml")
                        File.delete("/tmp/#{installid}.yml")
                    end
                rescue => e
                    LOG "An Error occured, while installing #{service} on #{ip}: #{err}, Code: #{e.message}", "AnsibleController"
                end
            end
            LOG 'Ansible job ended', 'AnsibleController'
            if !params['end-method'].nil? then
                LOG 'Calling end-method', 'AnsibleController'
                begin
                    send params['end-method'], params
                rescue
                end
            end
            Thread.exit
        end
        return 200
    end
    
    # @!group Ansible
    
    # Creates playbook
    # @param [Hash] args - Parameters for new playbook
    # @option args [String] name - (Mandatory)
    # @option args [Integer] uid - Owner id (Mandatory)
    # @option args [Integer] gid - Group id (Mandatory)
    # @option args [String] description - (Optional)
    # @option args [String] body - (Mandatory)
    # @option args [String] extra_data - You may store here additional data, such as supported OS (Optional)
    # @return [Fixnum] new playbook id
    def CreateAnsiblePlaybook args = {}
        AnsiblePlaybook.new(args.to_sym!).id
    end
    # Returns playbook from DB by id
    # @param [Fixnum] id - Playbook id in DB
    # @return [Hash] Playbook data
    def GetAnsiblePlaybook id
        AnsiblePlaybook.new(id:id).to_hash
    end
    # Updates playbook using given data by id
    # @param [Hash] args - id and keys for updates
    # @option args [Fixnum] id - ID of playbook to update (Mandatory)
    # @option args [String] name
    # @option args [Integer] uid - Owner id
    # @option args [Integer] gid - Group id
    # @option args [String] description
    # @option args [String] body
    # @option args [String] extra_data
    def UpdateAnsiblePlaybook args = {}
        ap = AnsiblePlaybook.new id:args.delete('id')
        args.each do | key, value |
            ap.send(key + '=', value)
        end
        ap.update
    end
    # Deletes playbook from DB by id
    # @param [Fixnum] id
    # @return [NilClass]
    def DeleteAnsiblePlaybook id
        AnsiblePlaybook.new(id:id).delete
    end
    # Returns variables from playbook(from vars section in playbook body)
    # @param [Fixnum] id
    # @return [Hash] Variables with default values
    def GetAnsiblePlaybookVariables id
        AnsiblePlaybook.new(id:id).vars        
    end
    # Returns playbook in AnsibleController acceptable form
    # @param [Fixnum] id
    # @return [Hash]
    def GetAnsiblePlaybook_ControllerRunnable id, vars = {}
        AnsiblePlaybook.new(id:id).runnable vars
    end
    #
    # Returns Playbooks from DB
    #
    # @param [Fixnum] chunks - number of playbooks per page(chunk)
    # @param [Fixnum] page - page number(shift)
    #
    # @return [Array<Hash>]
    #
    def ListAnsiblePlaybooks chunks = nil, page = 0
        pool = AnsiblePlaybook.list
        pool.delete_if {|pb| !ansible_check_permissions(pb, @client.user, 0) } # Deletes playbooks, which aren't under user access
        
        return pool if chunks.nil?
        
        pool.each_slice(chunks).to_a[page]
    end
    # Checks AnsiblePlaybook Syntax
    # @see AnsiblePlaybook.check_syntax Check this method source to learn syntax special rules
    # @return [Boolean]
    def CheckAnsiblePlaybookSyntax body
        AnsiblePlaybook.check_syntax body
    end
    # Creates Process instance with given playbook, host and variables
    # @param [Fixnum] playbook_id - Playbook ID
    # @param [Fixnum] uid - User ID who initialized playbook
    # @param [Array<String>] hosts - Array of hosts where to run playbook
    # @param [Hash] vars - Hash with playbook variables values
    # @param [String] comment
    # @param [String] auth - auth driver
    def AnsiblePlaybookToProcess playbook_id, uid, hosts = [], vars = {}, comment = '', auth = 'default'
        AnsiblePlaybookProcess.new(
            playbook_id: playbook_id,
            uid: uid,
            hosts: hosts,
            vars: vars,
            comment: comment,
            auth: auth
        ).id
    end
    # Returns AnsblePlaybook run Process by id as Hash with humanreadable state
    # @param [Fixnum] id - Process id
    # @return [Hash]
    def GetAnsiblePlaybookProcess id
        AnsiblePlaybookProcess.new(proc_id:id).human
    end
    # Deletes given AnsiblePlaybookProcess
    # @param [Fixnum] id - Process id
    # @return [NilClass]
    def DeleteAnsiblePlaybookProcess id
        AnsiblePlaybookProcess.new(proc_id:id).delete
    end
    # Runs given AnsiblePlaybookProcess in PENDING state
    # @param [Fixnum] id - Process id
    # @return [NilClass | Thread] - returns Thread if everything's fine, nil if wrong state
    def RunAnsiblePlaybookProcess id
        AnsiblePlaybookProcess.new(proc_id:id).run
    end
    # Returns given AnsiblePlaybookProcess state
    # @param [Fixnum] id - Process id
    # @return [String]
    def AnsiblePlaybookProcessStatus id
        AnsiblePlaybookProcess.new(proc_id:id).status
    end
    # Returns AnsblePlaybook run Process by id as Hash
    # @param [Fixnum] id - Process id
    # @return [Hash]
    def AnsiblePlaybookProcessInfo id
        AnsiblePlaybookProcess.new(proc_id:id).to_hash
    end
    # Returns all AnsiblePlaybook Processes as Array of Hashes
    # @param [Integer] chunks - number of processes per page(chunk)
    # @param [Integer] page - page number(shift)
    # @return [Array<Hash>]
    def ListAnsiblePlaybookProcesses chunks = nil, page = 0
        pool = AnsiblePlaybookProcess.list
        pool.delete_if {|apc| !@client.user!.groups.include?(0) && apc['uid'] != @client.user_id }
        
        return pool if chunks.nil?

        pool.each_slice(chunks).to_a[page]
    end


    # @!endgroup
end
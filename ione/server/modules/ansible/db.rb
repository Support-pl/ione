require 'mysql2'
require 'sequel'

# AnsiblePlaybook model implementation
class AnsiblePlaybook
    # DB Table name
    TABLE = 'ansible_playbook'
    # DB Table columns names
    FIELDS = %w(uid gid name description body extra_data create_time)
    # Creating table if doesn't exists
    begin
        $db.create_table TABLE.to_sym do 
            primary_key :id, :integer, null: false
            Integer :uid, null: false
            Integer :gid, null: false
            Integer :create_time, null: false
            String  :name, size: 128, null: false
            String  :description, size: 2048
            String :body, text: true, null: false
            String :extra_data, text: true
        end
    rescue
        puts "Table #{TABLE.to_sym} already exists, skipping"
    end
    # Getting table object from DB object
    DB = $db[TABLE.to_sym]

    attr_reader :id
    attr_accessor :name, :uid, :gid, :description, :body, :extra_data, :create_time

    # @param [Hash] args
    # @option args [Fixnum] uid - Playbooks owner user ID
    # @option args [Fixnum] gid - Playbooks group ID
    # @option args [String] name - Playbooks name
    # @option args [String] description - Playbooks description(only latin supported)
    # @option args [String] body - Playbooks YAML written body
    # @option args [Hash] extra_data - Any data you want to specify, usually only PERMISSIONS are mandatory
    def initialize **args
        args.to_s!
        if args['id'].nil? then
            @uid, @gid, @name, @description, @body, @extra_data = args.get(*FIELDS)
            @uid, @gid, @extra_data = @uid || 0, @gid || 0, @extra_data || {}

            @extra_data['PERMISSIONS'] = @extra_data['PERMISSIONS'] || {"PERMISSIONS" => "111000000"}

            r, msg = self.class.check_syntax(@body)
            raise RuntimeError.new(msg) unless r

            @create_time = Time.now.to_i
            allocate
        else
            begin
                @id = args['id']
                sync
            rescue NoMethodError
                raise "Object not exists"
            end
        end
        raise "Unhandlable, id is nil" if @id.nil?
    end
    # Synchronizes object from DB
    def sync
        get_me.each do |var, value|
            instance_variable_set('@' + var, value)
        end
    end
    
    # Deletes object from DB
    def delete
        DB.where(id: @id).delete
        nil
    end
    # Writes object to DB
    def update
        r, msg = self.class.check_syntax(@body)
        raise RuntimeError.new(msg) unless r
        
        args = {}
        FIELDS.each do | var |
            next if var == 'create_time'
            value = instance_variable_get(('@' + var).to_sym)
            value = var == 'extra_data' ? JSON.generate(value) : value
            args[var.to_sym] = value.nil? ? '' : value
        end
        DB.where(id: @id).update( **args )

        nil
    end
    # Lists variables from Playbook
    def vars
        sync
        body = YAML.load(@body).first
            body['vars']
    rescue => e
        if e.message.split(':').first == 'TypeError' then
            raise "SyntaxError: Check if here is now hyphens at the playbook beginning. Playbook parse result should be Hash"
        end
    end
    # Checks Playbook Syntax
    # @param [String] body - Playbooks body written in YAML
    # @note Playbook should be written following next rules:
    # 1. It must be written in ruby-yaml parse-able YAML syntax
    # 2. Playbook must be array (body should start from ' - ')
    # 3. hosts must be equal to <%group%>
    # 4. Using of "local_action" key is restricted
    def self.check_syntax body
        body = YAML.load(body)
        raise AnsiblePlaybookSyntaxError.new( "Playbook must be array (body should start from ' - ')" ) unless body.class == Array
        raise AnsiblePlaybookSyntaxError.new( "hosts must be equal to <%group%>" ) unless body.first['hosts'] == "<%group%>"
        raise AnsiblePlaybookSyntaxError.new( "key local_action isn't acceptable" ) if body.first.has_key? 'local_action'
        return true, ""
    rescue Psych::SyntaxError => e
        return false, e.message
    rescue AnsiblePlaybookSyntaxError => e
        return false, e.message
    rescue => e
        return false, 'Unknown error: ' + e.message
    end

    # Creates AnsiblePlaybookProcess with given args
    # @param [Hash] host - host or hosts, whereto Playbook will be deployed, see example
    # @param [Hash] vars - variables for playbook, see example
    # @param [IONe] ione - IONe client
    # @example Params template:
    # host -> {'one_vm_id' => ['IP_Address:ssh_port', 'username:password']}
    # vars -> {'variable_name_from_playbook_vars_section' => 'value'}
    def run host, vars:nil, ione:IONe.new($client)
        r, msg = self.class.check_syntax(@body)
        raise RuntimeError.new(msg) unless r
        
        unless vars.nil? then
            body = YAML.load @body
            body[0]['vars'].merge! vars
            @body = YAML.dump body
        end
        ione.AnsibleController({
            'host' => host,
            'services' => [
                runnable
            ]
        })
    end
    # Returns Playbook body with variables inserted
    def runnable vars={}
        r, msg = self.class.check_syntax(@body)
        raise RuntimeError.new(msg) unless r

        unless vars == {} then
            body = YAML.load @body
            body[0]['vars'].merge! vars
            @body = YAML.dump body
        end
        return { @name => @body }
    end
    # Returns AnsiblePlaybook object as Hash
    def to_hash
        get_me
    end

    # Returns all AnsiblePlaybook objects from DB
    def self.list
        result = DB.all
        result.map{ |pb| pb.to_s! }
        result.size.times do | i |
            result[i]['extra_data'] = JSON.parse result[i]['extra_data']
        end
        result
    end

    # Playbook has wrong syntax Exception
    class AnsiblePlaybookSyntaxError < StandardError
        def initialize msg
            super
            @msg = msg
        end
        # Returns exception message
        def message
            @msg
        end
    end

    private

    # Writes object to DB
    def allocate
        args = {}
        FIELDS.each do | var |
            value = instance_variable_get(('@' + var).to_sym)
            args[var.to_sym] = value.nil? ? '' : value
        end
        args[:extra_data] = JSON.generate(args[:extra_data])
        @id = DB.insert( **args )
    end
    # Gets object from DB
    def get_me id = @id
        me = DB.where(id: @id).to_a.last.to_s!
        me['extra_data'] = JSON.parse me['extra_data']
        me
    end
end

# Ansible Playbook run process implementation
class AnsiblePlaybookProcess
    
    # DB Table name    
    TABLE   = 'ansible_playbook_process'
    
    # DB Table columns names
    FIELDS  = %w(
        uid playbook_id install_id
        create_time start_time end_time
        status log hosts 
        vars playbook_name runnable
        comment codes run_after
    )

    # Creating table if doesn't exists
    begin
        $db.create_table TABLE.to_sym do 
            primary_key :proc_id, :integer, null: false
            Integer :uid, null: false
            Integer :playbook_id, null: false
            String  :install_id, size: 128, null: false, unique: true
            Integer :create_time, null: false
            Integer :start_time
            Integer :end_time
            String  :status, size: 12
            String  :log, text: true, null: false
            String  :hosts, text: true, null: false
            String  :vars, text: true, null: false
            String  :playbook_name, size: 128, null: false
            String  :runnable, text: true, null: false
            String  :comment, text: true
            String  :codes, size: 128, null: false
            String  :run_after, text: true
        end
    rescue
        puts "Table #{TABLE.to_sym} already exists, skipping"
    end

    # Process states dictionary
    STATUS = {
        '0' => 'PENDING',
        '1' => 'RUNNING',
        'ok' => 'SUCCESS',
        'changed' => 'CHANGED',
        'unreachable' => 'UNREACHABLE',
        'failed' => 'FAILED',
        '6' => 'LOST',
        'done' => 'DONE'
    }
    # Getting table object from DB object
    DB = $db[:ansible_playbook_process]

    attr_reader :id, :install_id, :hosts, :start_time, :end_time

    # @param [Fixnum] proc_id - Process will be loaded from DB if given
    # @param [Fixnum] playbook_id - Playbook object ID to use
    # @param [Fixnum] uid - User ID who initiates the process
    # @param [Hash] hosts - see example
    # @param [Hash] vars - Variables that should be inserted in PB
    # @param [String] comment - Anything you want to tell another users or admins about this Process
    # @param [String] auth - auth driver to use, now is only one supported - default, which uses login and password pair
    # @param [Hash] run_after
    # @option run_after [String] method - IONe method name to call after Ansible will end its work
    # @option run_after [Array] params - Params for this method, see example
    # @example Hosts example:
    # hosts: { 'vmid' => [ip:port, credentials]}
    # @example Run After example:
    # {
    #     "method" => "Reboot",
    #     "params" => 777 # vmid
    # } # So VM will be rebooted after
    def initialize proc_id:nil, playbook_id:nil, uid:nil, hosts:{}, vars:{}, comment:'', auth:'default', run_after:{}
        if proc_id.nil? then
            @uid, @playbook_id = uid, playbook_id
            @install_id = SecureRandom.uuid + '-' + Date.today.strftime
            @create_time, @start_time, @end_time = Time.now.to_i, -1, -1
            @status = '0'
            @log = ''
            @comment = comment.to_s
            @hosts = hosts
            @vars = vars
            @playbook = AnsiblePlaybook.new(id: @playbook_id)
            @playbook_name, @runnable = @playbook.runnable(@vars).to_a[0]
            @codes = '—'
            @run_after = run_after
        else
            @id = proc_id
            sync
        end
    rescue
        @playbook = @playbook_name = @runnable = ''
        @status = 'done'
    ensure
        allocate if @id.nil?
    end
    
    # Start Process
    # @param [Boolean] thread - Runs in another Thread and returns its object if true
    def run thread = true
        nil if STATUS.keys.index(@status) > 0
        @start_time, @status = Time.now.to_i, '1'
        
        update

        process = Proc.new do
            begin
                Net::SSH.start( ANSIBLE_HOST, ANSIBLE_HOST_USER, :port => ANSIBLE_HOST_PORT ) do | ssh |
                    # Create local Playbook version
                    File.open("/tmp/#{@install_id}.yml", 'w') do |file|
                        file.write( @runnable.gsub('<%group%>', @install_id) )
                    end
                    # Upload Playbook to Ansible host
                    ssh.sftp.upload!("/tmp/#{@install_id}.yml", "/tmp/#{@install_id}.yml")
                    # Create local Hosts File
                    File.open("/tmp/#{@install_id}.ini", 'w') do |file|
                        file.write("[#{@install_id}]\n")
                        @hosts.values.each do |host|
                            unless host[1].nil? then
                                cred = host[1].split ':'
                                cred = "ansible_user=#{cred[0]} ansible_password=#{cred[1]}"
                            else
                                cred = ''
                            end
                            file.write("#{host[0]} #{cred}\n")
                        end
                    end
                    # Upload Hosts file
                    ssh.sftp.upload!("/tmp/#{@install_id}.ini", "/tmp/#{@install_id}.ini")
                    # Creating run log
                    ssh.exec!("echo 'START' > /tmp/#{@install_id}.runlog")
                    # Run Playbook
                    ssh.exec!(
                        "ansible-playbook /tmp/#{@install_id}.yml -i /tmp/#{@install_id}.ini >> /tmp/#{@install_id}.runlog; echo 'DONE' >> /tmp/#{@install_id}.runlog" )
                
                    @end_time = Time.now.to_i
                end
                clean
                scan
            rescue => e
                @status = 'failed'
                @log = "Internal Error:\n" + e.message + "\n---\n---\nBacktrace:\n" + e.backtrace.join("\n")
            ensure
                update
            end
        end
        if thread then
            Thread.new do
                process.call
            end
        else
            process.call
        end
    ensure
        update
    end
    # Scans Ansible log file after its work end
    # @note Normally it runs automatically, you shouldn't do it by yourself
    def scan
        return nil if STATUS.keys.index(@status) > 1
        Net::SSH.start( ANSIBLE_HOST, ANSIBLE_HOST_USER, :port => ANSIBLE_HOST_PORT ) do | ssh |
            ssh.sftp.download!("/tmp/#{@install_id}.runlog", "/tmp/#{@install_id}.runlog")
            @log = File.read("/tmp/#{@install_id}.runlog")
            if @log.split(/\n/)[-1] == 'DONE' then
                ssh.sftp.remove("/tmp/#{@install_id}.runlog")
                @log.slice!("START\n")
                @log.slice!("\nDONE\n")
            else
                @log = ""
                return
            end
        end if @log == ""

        codes = {}
        
        @log.split('PLAY RECAP').last.split(/\n/).map do | host |
            host = host.split("\n").last.split(" ")
            next if host.size == 1
            codes.store host[0], {}
            host[-4..-1].map do |code|
                code = code.split("=")
                codes[host[0]].store(code.first, code.last.to_i)
            end
        end
        
        if codes.values.inject(0){|sum, vals| sum +=  vals['failed']} != 0 then
            @status = 'failed'
        elsif codes.values.inject(0){|sum, vals| sum +=  vals['unreachable']} != 0 then
            @status = 'unreachable'
        else
            @status = codes.values.last.keys.map do | key |
                { key => codes.values.inject(0){|sum, vals| sum +=  vals[key]} }
            end.sort_by{|attribute| attribute.values.last }.last.keys.last
        end
        
        @codes = codes

        run_after
    rescue => e
        puts e.message, e.backtrace
        @status = '6'
    ensure
        update
    end
    # Sets Process state to Done
    def delete
        @status = 'done'
    ensure
        update
    end
    # Returns humanreadable Process state
    def status
        STATUS[@status]
    end
    # Returns object as is in Hash form
    def to_hash
        get_me
    end
    # Returns object with State to humanreadable replaced in Hash form
    def human
        r = to_hash
        r['status'] = STATUS[r['status']]
        r
    end
    # Runs method from run_after field
    def run_after
        return if @run_after['method'].nil?

        if @run_after['params'].nil? then
            IONe.new($client, $db).send(@run_after['method'])         
        elsif @run_after['params'].class == Array then
            IONe.new($client, $db).send(@run_after['method'], *@run_after['params'])
        else
            IONe.new($client, $db).send(@run_after['method'], @run_after['params'])
        end
    end

    # Lists all Processes from DB
    def self.list
        result = DB.all
        result.map{ |pb| pb.to_s! }
        result.each do |app|
            app['status'] = STATUS[app['status']]
        end
        result
    end
    
    private

    # Removes Playbook, Ansible hosts group and .retry files from host
    def clean
        Net::SSH.start( ANSIBLE_HOST, ANSIBLE_HOST_USER, :port => ANSIBLE_HOST_PORT ) do | ssh |
            ssh.sftp.remove!("/tmp/#{@install_id}.ini")
            File.delete("/tmp/#{@install_id}.ini")
            ssh.sftp.remove!("/tmp/#{@install_id}.yml")
            File.delete("/tmp/#{@install_id}.yml")
            ssh.sftp.remove("/tmp/#{@install_id}.retry")
        end
        nil
    end
    # Updates object in DB
    def update
        args = {}
        FIELDS.each do | var |
            next if var == 'create_time'
            value = instance_variable_get(('@' + var).to_sym)
            value = (['vars', 'hosts', 'codes', 'run_after'].include?(var) && value != '—' ) ? JSON.generate(value) : value
            args[var.to_sym] = value.nil? ? '' : value
        end
        DB.where(proc_id: @id).update( **args )
        nil
    end
    # Writes object to DB
    def allocate
        args = {}
        FIELDS.each do | var |
            value = instance_variable_get(('@' + var).to_sym)
            args[var.to_sym] = value.nil? ? '' : value
        end
        args[:vars] = JSON.generate(args[:vars])
        args[:hosts] = JSON.generate(args[:hosts])
        args[:codes] = args[:codes] == '—' ? args[:codes] : JSON.generate(args[:codes])
        args[:run_after] = JSON.generate(args[:run_after])
        @id = DB.insert( **args )
    end
    # Fills objects properties from DB
    def sync
        get_me.each do |var, value|
            instance_variable_set('@' + var, value)
        end
    end
    # Returns object directly from DB as Hash
    def get_me id = @id
        me = DB.where(proc_id: @id).to_a.last.to_s!
        me['vars'] = JSON.parse me['vars']
        me['hosts'] = JSON.parse me['hosts']
        me['codes'] = me['codes'] == '—' ? me['codes'] : JSON.parse( me['codes'])
        me['run_after'] = JSON.parse me['run_after']
        me
    end
end
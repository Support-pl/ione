require 'zmqjsonrpc'

def r **result # Generates response
   JSON.pretty_generate result
end

def ansible_check_permissions pb, u, uma # Checks permissions for given playbook and action for given user
   u.info!
   perm = pb['extra_data']['PERMISSIONS'].split('')
   mod = perm.values_at( *Array.new(3){ |i| uma + 3 * i }).map{| value | value == '1' ? true : false }
   return (
      (  u.id == pb['uid'] && mod[0]            ) ||
      (  u.groups.include?(pb['gid']) && mod[1] ) ||
      (                 mod[2]                  ) ||
      (          u.groups.include?(0)           )
   )
end

class String
   def is_json? # Checks if this string is JSON parsable
      begin
         JSON.parse self
         true
      rescue
         false
      end
   end
   def is_zmq_error? # Checks if this looks like zmq error
      include? 'Server returned error (32603)'
   end
   def crop_zmq_error! # Crops Zmq backtrace and error code from message
      self.slice! self.split("\n").last
      self.slice! 'Server returned error (32603): '
      self.delete! "\n"
      self
   end
end

class Hash
   def duplicate_with_case! to_case = :up # Duplicates each key and value with key up- or down- cased
      self.clone.each do |key, value|
         self[key.send(to_case.to_s + 'case')] = value
      end
      nil
   end
end

class AnsiblePlaybookModel

   attr_reader    :method, :id
   attr_accessor  :body

   # Each number is corresponds to position at ACTIONS
   RIGHTS = {
      'chown'        => 2,
      'chgrp'        => 2,
      'chmod'        => 2,
      'run'          => 0,
      'update'       => 1,
      'delete'       => 2,
      'vars'         => 0,
      'clone'        => 0,
      'rename'       => 1  }

   ACTIONS = ['USE', 'MANAGE', 'ADMIN']

   def initialize id:nil, data:{'action' => {'params' => {}}}, user:nil
      @user = user # Need this to check permissions later
      @user.info!
      if id.nil? then # If id is not given - new Playbook will be created
         @params = data
         begin
            # Check if mandatory params are not nil
            check =  @params['name'].nil?                      ||
                     @params['body'].nil?                      ||
                     @params['extra_data'].nil?                ||
                     @params['extra_data']['PERMISSIONS'].nil?
         rescue
            raise ParamsError.new @params # Custom error if extra_data is nil
         end
         raise ParamsError.new(@params) if check # Custom error if something is nil
         raise NoAccessError.new(2) unless @user.groups.include? 0 # Custom error if user is not in oneadmin group
         @id = id = AnsiblePlaybook.new(**@params.to_sym!.merge({uid: @user.id, gid: @user.gid})).id # Save id of new playbook
      else # If id is given getting existing playbook
         # Params from OpenNebula are always in {"action" => {"perform" => <%method name%>, "params" => <%method params%>}} form
         # So here initializer saves method and params to object
         @method, @params = data['action']['perform'], data['action']['params']
         @body = IONe.new($client, $db).GetAnsiblePlaybook(@id = id) # Getting Playbook in hash form
         @permissions = Array.new(3) {|uma| ansible_check_permissions(@body, @user, uma) } # Parsing permissions
         
         raise NoAccessError.new(0) unless @permissions[0] # Custom error if user has no USE rights
      end
   end
   def call # Calls API method given to initializer
      access = RIGHTS[method] # Checking access permissions for perform corresponding ACTION
      raise NoAccessError.new(access) unless @permissions[access] # Raising Custom error if no access granted
      send(@method) # Calling method from @method
   end

   def clone # Clones Playbook with given id to a new playbook with given name in params
      args = @body
      args.delete('id')
      IONe.new($client, $db).CreateAnsiblePlaybook(
         args.merge({
            :name => @params["name"], :uid => @user.id, :gid => @user.gid
         })
      )
   end
   def update # Updated Playbook with given keys and values. If params are {"name" => "new_name"}, key "name" will have value "new_name" after Update performed
      @params.each do |key, value| # Changing each key
         @body[key] = value
      end

      IONe.new($client, $db).UpdateAnsiblePlaybook @body # Updating playbook with resulting body
      nil
   end
   def delete # Deletes Playbook with id
      IONe.new($client, $db).DeleteAnsiblePlaybook @id
      nil
   end

   def chown # Changes Playbook owner
      # if chown or chgrp method called OpenNebula always calling chown.
      # And if owner or group is not changing, it sets corresponding key to "-1".
      # So if owner is set to "-1" chown will try to call chgrp 
      IONe.new($client, $db).UpdateAnsiblePlaybook( "id" => @body['id'], "uid" => @params['owner_id'] ) unless @params['owner_id'] == '-1'
      chgrp unless @params['group_id'] == '-1' # But if group is also set to "-1", nothing will be called if so
      nil
   end
   def chgrp # Changes Playbook group
      IONe.new($client, $db).UpdateAnsiblePlaybook( "id" => @body['id'], "gid" => @params['group_id'] )
      nil
   end
   def chmod # Changes Playbook permissions table by changing extra_data => PERMISSIONS
      raise ParamsError.new(@params) if @params.nil? # PERMISSIONS cannot be nil, but database not checking this
      IONe.new($client, $db).UpdateAnsiblePlaybook( "id" => @body['id'], "extra_data" => @body['extra_data'].merge("PERMISSIONS" => @params) )
      nil
   end
   def rename # Renames Playbook
      IONe.new($client, $db).UpdateAnsiblePlaybook( "id" => @body['id'], "name" => @params['name'] )
      nil
   end

   def vars # Returns Variabled defined at Playbook body
      IONe.new($client, $db).GetAnsiblePlaybookVariables @id
   end
   def to_process # Creates install process from given Playbook with given hosts and vars
      IONe.new($client, $db).AnsiblePlaybookToProcess( @body['id'], @params['hosts'], 'default', @params['vars'] )
   end

   class NoAccessError < StandardError # Custom error for no access exceptions. Returns string contain which action is blocked
      def initialize action
         super()
         @action = AnsiblePlaybookModel::ACTIONS[action]
      end
      def message
         "Not enough rights to perform action: #{@action}!"
      end
   end
   class ParamsError < StandardError # Custom error for not valid params, returns given params inside
      def initialize params
         super()
         @params = @params
      end
      def message
         "Some arguments are missing or nil! Params:\n#{@params.inspect}"
      end
   end
end

before do # This actions will be performed before any route 
   begin
      @one_client = $cloud_auth.client(session[:user]) # Saving OpenNebula client for user
      @one_user = OpenNebula::User.new_with_id(session[:user_id], @one_client) # Saving user object
   rescue => e
      @before_exception = e.message
   end
end

get '/ansible' do # Returns full Ansible Playbooks pool in OpenNebula XML-POOL format
   begin
      pool = IONe.new($client, $db).ListAnsiblePlaybooks # Array of playbooks
      pool.delete_if {|pb| !ansible_check_permissions(pb, @one_user, 0) } # Deletes playbooks, which aren't under user access
      pool.map! do | pb | # Adds user and group name to every object
         user, group =  OpenNebula::User.new_with_id( pb['uid'], @one_client),
                        OpenNebula::Group.new_with_id( pb['gid'], @one_client)
         user.info!; group.info!
         pb['vars']  =  IONe.new($client, $db).GetAnsiblePlaybookVariables(pb['id'])
         pb.merge(
            'uname' => user.name, 'gname' => group.name,
            'vars' => pb['vars'].nil? ? {} : pb['vars']  )
      end
      pool.map{|playbook| playbook.duplicate_with_case! } # Duplicates every key with the same but upcase-d
      # Returns in required format
      r(**{
         :ANSIBLE_POOL => {
            :ANSIBLE => pool
         }
      })
   rescue => e
      msg = e.message
      msg.crop_zmq_error! if msg.is_zmq_error? # Crops ZmqJsonRpc backtrace from exception message
      r error: e.message, backtrace: e.backtrace
   end
end

post '/ansible' do # Allocates new playbook
   begin
      data = JSON.parse(@request_body)
      r response: { ANSIBLE: { ID: AnsiblePlaybookModel.new(id:nil, data:data, user:@one_user).id }}
   rescue JSON::ParserError # If JSON.parse fails
      r error: "Broken data received, unable to parse."
   rescue => e
      msg = e.message
      msg.crop_zmq_error! if msg.is_zmq_error? # Crops ZmqJsonRpc backtrace from exception message
      @one_user.info!
      r error: e.message, backtrace: e.backtrace, data:data
   end
end

delete '/ansible/:id' do |id| # Deletes given playbook
   begin
      data = {'action' => {'perform' => 'delete', 'params' => nil}}
      pb = AnsiblePlaybookModel.new(id:id, data:data, user:@one_user)

      r response: pb.call
   rescue JSON::ParserError # If JSON.parse fails
      r error: "Broken data received, unable to parse."
   rescue => e
      msg = e.message
      msg.crop_zmq_error! if msg.is_zmq_error? # Crops ZmqJsonRpc backtrace from exception message
      r error: e.message, backtrace: e.backtrace
   end
end

get '/ansible/:id' do | id | # Returns playbook body in OpenNebula required format
   begin
      pb = AnsiblePlaybookModel.new(id:id, user:@one_user) # Getting playbook
      # Saving user and group to objects
      user, group =  OpenNebula::User.new_with_id( pb.body['uid'], @one_client),
                     OpenNebula::Group.new_with_id( pb.body['gid'], @one_client)
      user.info!; group.info! # Retrieving information about this objects from ONe
      pb.body.merge!('uname' => user.name, 'gname' => group.name, 'vars' => pb.vars.nil? ? {} : pb.vars) # Adding user and group names to playbook body
      pb.body.duplicate_with_case! # Duplicates every key with the same but upcase-d
      r ANSIBLE: pb.body
   rescue => e
      msg = e.message
      msg.crop_zmq_error! if msg.is_zmq_error? # Crops ZmqJsonRpc backtrace from exception message
      r error: e.message, backtrace: e.backtrace
   end
end
get '/ansible/:id/vars' do | id | # I think it's not needed here, rly
   begin
      raise "CustomError for debug proposes" if id.to_i == 31
      pb = AnsiblePlaybookModel.new(id:id, data:{'action' => {'perform' => 'vars'}}, user:@one_user)
      r vars: pb.call
   rescue => e
      msg = e.message
      msg.crop_zmq_error! if msg.is_zmq_error? # Crops ZmqJsonRpc backtrace from exception message
      r error: e.message, backtrace: e.backtrace
   end
end

post '/ansible/:id/action' do | id | # Performs action
   begin
      data = JSON.parse(@request_body)
      pb = AnsiblePlaybookModel.new(id:id, data:data, user:@one_user)

      r response: pb.call
   rescue JSON::ParserError # If JSON.parse fails
      r error: "Broken data received, unable to parse."
   rescue => e
      msg = e.message
      msg.crop_zmq_error! if msg.is_zmq_error? # Crops ZmqJsonRpc backtrace from exception message
      r error: e.message, backtrace: e.backtrace
   end
end

post '/ansible/:action' do | action | # Performs actions, which are defined as def self.method for AnsiblePlaybookModel model
   data = JSON.parse(@request_body)

   begin
      if action == 'check_syntax' then
         r response: IONe.new($client, $db).CheckAnsiblePlaybookSyntax( data['body'])
      else
         r response: "Action is not defined"
      end
   rescue JSON::ParserError # If JSON.parse fails
      r error: "Broken data received, unable to parse."
   rescue => e
      msg = e.message
      msg.crop_zmq_error! if msg.is_zmq_error? # Crops ZmqJsonRpc backtrace from exception message
      r error: e.message, backtrace: e.backtrace
   end
end

class AnsiblePlaybookProcessModel

    RIGHTS = {
       'run' => 1,
       'delete' => 2
    }
 
    attr_reader    :method, :id
    attr_accessor  :body
 
    def initialize id:nil, data:{'action' => {}}, user:nil
       @user = user # Need this to check permissions later
       if id.nil? then # If id is not given - new Playbook will be created
          @params = data
          begin
             # Check if mandatory params are not nil
             check =  @params['playbook_id'].nil? || @params['hosts'].nil?
          rescue
             raise ParamsError.new @params # Custom error if extra_data is nil
          end
          raise ParamsError.new(@params) if check # Custom error if something is nil
 
          raise NoAccessError.new(2) unless user.groups.include? 0 # Custom error if user is not in oneadmin group
          @user.info! # Retrieve object body
          @id =
             id =
                IONe.new($client, $db).AnsiblePlaybookToProcess( @params['playbook_id'], @user.id, @params['hosts'], @params['vars'], @params['comment']) # Save id of new playbook
       else # If id is given getting existing playbook
          # Params from OpenNebula are always in {"action" => {"perform" => <%method name%>, "params" => <%method params%>}} form
          # So here initializer saves method and params to object
          @method, @params = data['action']['perform'], data['action']['params']
          @body = IONe.new($client, $db).GetAnsiblePlaybookProcess(@id = id) # Getting Playbook in hash form
          @permissions = Array.new(3) do |uma|
             ansible_check_permissions( {'uid' => @body['uid'], 'extra_data' => { 'PERMISSIONS' => '111000000' } }, @user, uma  )
          end # Parsing permissions
          raise NoAccessError.new(0) unless @permissions[0] # Custom error if user has no USE rights
 
       end
    end
    def call # Calls API method given to initializer
       access = RIGHTS[method] # Checking access permissions for perform corresponding ACTION
       raise NoAccessError.new(access) unless @permissions[access] # Raising Custom error if no access granted
       send(@method) # Calling method from @method
    end
    def run
       IONe.new($client, $db).RunAnsiblePlaybookProcess(@id)
       nil
    end
    def delete
       IONe.new($client, $db).DeleteAnsiblePlaybookProcess(@id)
    end
 
 
    class NoAccessError < StandardError # Custom error for no access exceptions. Returns string contain which action is blocked
       def initialize action
          super()
          @action = AnsiblePlaybook::ACTIONS[action]
       end
       def message
          "Not enough rights to perform action: #{@action}!"
       end
    end
    class ParamsError < StandardError # Custom error for not valid params, returns given params inside
       def initialize params
          super()
          @params = @params
       end
       def message
          "Some arguments are missing or nil! Params:\n#{@params.inspect}"
       end
    end
 end
 
 before do # This actions will be performed before any route 
    begin
       @one_client = $cloud_auth.client(session[:user]) # Saving OpenNebula client for user
       @one_user = OpenNebula::User.new_with_id(session[:user_id], @one_client) # Saving user object
    rescue => e
       @before_exception = e.message
    end
 end
 
 get '/ansible_process' do
    begin
       pool = IONe.new($client, $db).ListAnsiblePlaybookProcesses
       IONe.new($client, $db).Test(pool.size, 'DEBUG')
       pool.delete_if {|apc| !@one_user.groups.include?(0) && apc['uid'] != @one_user.id }
       IONe.new($client, $db).Test(pool.size, 'DEBUG')
       pool.map! do | apc | # Adds user name to every object
          user =  OpenNebula::User.new_with_id( apc['uid'], @one_client)
          user.info!
          apc.merge('id' => apc['proc_id'], 'uname' => user.name)
       end
       pool.map{|playbook| playbook.duplicate_with_case! } # Duplicates every key with the same but upcase-d
 
       r(**{
          :ANSIBLE_PROCESS_POOL => {
             :ANSIBLE_PROCESS => pool
          }
       })
    rescue => e
       msg = e.message
       msg.crop_zmq_error! if msg.is_zmq_error? # Crops ZmqJsonRpc backtrace from exception message
       r error: e.message, backtrace: e.backtrace
    end
 end
 
 post '/ansible_process' do
    begin
       data = JSON.parse(@request_body)
       r response: { ANSIBLE_PROCESS: { ID: AnsiblePlaybookProcessModel.new(id:nil, data:data, user:@one_user).id }}
    rescue JSON::ParserError # If JSON.parse fails
       r error: "Broken data received, unable to parse."
    rescue => e
       msg = e.message
       msg.crop_zmq_error! if msg.is_zmq_error? # Crops ZmqJsonRpc backtrace from exception message
       @one_user.info!
       r error: e.message, backtrace: e.backtrace, data:data
    end
 end
 
 get '/ansible_process/:id' do |id|
    begin
       apc = AnsiblePlaybookProcessModel.new(id:id, user:@one_user) # Getting playbook
       # Saving user and group to objects
       user =  OpenNebula::User.new_with_id( apc.body['uid'], @one_client)
       user.info!
       apc.body.merge!('id' => apc.body['proc_id'], 'uname' => user.name) # Retrieving information about this objects from ONe
       apc.body.duplicate_with_case! # Duplicates every key with the same but upcase-d
       r ANSIBLE_PROCESS: apc.body
    rescue => e
       msg = e.message
       msg.crop_zmq_error! if msg.is_zmq_error? # Crops ZmqJsonRpc backtrace from exception message
       r error: e.message, backtrace: e.backtrace
    end
 end
 
 delete '/ansible_process/:id' do |id| # Deletes given playbook process
    begin
       data = {'action' => {'perform' => 'delete', 'params' => nil}}
       pb = AnsiblePlaybookProcessModel.new(id:id, data:data, user:@one_user)
 
       r response: pb.call
    rescue JSON::ParserError # If JSON.parse fails
       r error: "Broken data received, unable to parse."
    rescue => e
       msg = e.message
       msg.crop_zmq_error! if msg.is_zmq_error? # Crops ZmqJsonRpc backtrace from exception message
       r error: e.message, backtrace: e.backtrace
    end
 end
 
 post '/ansible_process/:id/action' do | id | # Performs action
    begin
       data = JSON.parse(@request_body)
       pb = AnsiblePlaybookProcessModel.new(id:id, data:data, user:@one_user)
 
       r response: pb.call
    rescue JSON::ParserError # If JSON.parse fails
       r error: "Broken data received, unable to parse."
    rescue => e
       msg = e.message
       msg.crop_zmq_error! if msg.is_zmq_error? # Crops ZmqJsonRpc backtrace from exception message
       r error: e.message, backtrace: e.backtrace
    end
 end
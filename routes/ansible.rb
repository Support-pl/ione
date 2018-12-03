require 'zmqjsonrpc'

IONe = ZmqJsonRpc::Client.new("tcp://localhost:8008")

def r **result
   JSON.pretty_generate result
end

def ansible_check_permissions pb, u, uma
   u.info!
   perm = JSON.parse(pb['extra_data'])['PERMISSIONS'].split('')
   mod = perm.values_at( *Array.new(3){ |i| uma + 3 * i }).map{| value | value == '1' ? true : false }
   return (
      (  u.id == pb['uid'] && mod[0]            ) ||
      (  u.groups.include?(pb['gid']) && mod[1] ) ||
      (                 mod[2]                  ) ||
      (          u.groups.include?(0)           )
   )
end

class String
   def is_json?
      begin
         JSON.parse self
         true
      rescue
         false
      end
   end
end

class AnsiblePlaybook

   attr_reader    :method
   attr_accessor  :body

   RIGHTS = {
      'chown'        => 1,
      'chgrp'        => 1,
      'chmod'        => 1,
      'run'          => 0,
      'update'       => 2,
      'delete'       => 2,
      'vars'         => 0  }

   ACTIONS = ['USE', 'MANAGE', 'ADMIN']

   def initialize id:nil, data:{}, user:nil
      @user, @method, @params = user, data['method'], data['params']
      if id.nil? then
         # Create PB here
      else
         @body = IONe.GetAnsiblePlaybook(id)
      end
      @permissions = Array.new(3) {|uma| ansible_check_permissions(@body, @user, uma) }

      raise AnsiblePlaybook::NoAccessError.new(0) unless @permissions[0]
   end
   def call
      access = RIGHTS[method]
      raise AnsiblePlaybook::NoAccessError.new(access) unless @permissions[access]
      send(@method)
   end
   def chown
      IONe.UpdateAnsiblePlaybook({ "id" => @body['id'], "uid" => @params })
   end
   def chgrp
      IONe.UpdateAnsiblePlaybook({ "id" => @body['id'], "gid" => @params })
   end

   class NoAccessError < StandardError
      def initialize action
         super()
         @action = AnsiblePlaybook::ACTIONS[action]
      end
      def message
         "Not enough rights to perform action: #{@action}"
      end
   end
end

before do
   begin
      @one_client = $cloud_auth.client(session[:user])
      @one_user = OpenNebula::User.new_with_id(session[:user_id], @one_client)
   rescue => e
      @before_exception = e.message
   end
end

get '/ansible' do
   begin
      pool = IONe.ListAnsiblePlaybooks
      pool.delete_if {|pb| !ansible_check_permissions(pb, @one_user, 0) }
      r(**{ 
         :ANSIBLE_POOL => {
            :ANSIBLE => pool
         }
      })
   rescue => e
      r error: e.message, backtrace: e.backtrace
   end
end

get '/ansible/:id' do | id |
   begin
      pb = AnsiblePlaybook.new(id:id, data:{}, user:@one_user)
      r response: pb.body
   rescue => e
      r error: e.message, backtrace: e.backtrace
   end
end

post '/ansible/:id/action' do | id |
   begin
      data = JSON.parse(@request_body)
      pb = AnsiblePlaybook.new(id:id, data:data, user:@one_user)

      r response: pb.call
   rescue JSON::ParserError
      r error: "Broken data received, unable to parse."
   rescue => e
      r error: e.message, backtrace: e.backtrace
   end
end

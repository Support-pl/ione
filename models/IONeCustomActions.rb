require 'zmqjsonrpc'

def r **result
   JSON.pretty_generate result
end

before do
   begin
      @one_client = $cloud_auth.client(session[:user])
      @one_user = OpenNebula::User.new_with_id(session[:user_id], @one_client)
      @one_user.info!
   rescue => e
      @before_exception = e.message
   end
end

post '/vm/:id/reinstall' do | id |
   begin
      data = {'id' => nil, 'template_id' => nil, 'password' => nil, 'ansible' => false, 'ansible_local_id' => -1, 'ansible_vars' => {}}
      body = JSON.parse(request.body.read)
      data.merge!(body['action']['params'])
      vm = IONe.new($client, $db).get_vm_data(id.to_i)

      template = OpenNebula::Template.new_with_id(data['template_id'], @one_client)
      template.info!
      image = OpenNebula::Image.new_with_id(template['/VMTEMPLATE/TEMPLATE/DISK/IMAGE_ID'], @one_client)
      image.info!
      
      if !(@one_user.id == vm['OWNERID'].to_i || @one_user.groups.include?(0)) then
         r error: "User is not OWNER for given VM"
      elsif vm['DRIVE'].to_i < image['/IMAGE/SIZE'].to_i then
         r error: "Drive cannot be smaller then #{image['/IMAGE/SIZE']}"
      else
         r body:body, response:
            IONe.new($client, $db).Reinstall({
               :vmid => id,
               :userid => @one_user.id,
               :login => vm['OWNER'],
               :groupid => vm['GROUPID'],
               :passwd => data['password'],
               :username => data['username'],
               :templateid => data['template_id'],
               :cpu => vm['CPU'],
               :ram => vm['RAM'],
               :units => 'MB',
               :drive => vm['DRIVE'],
               :host => vm['HOST_ID'],
               :ds_type => vm['DS_TYPE'],
               :release => true,
               :ansible => data['ansible'],
               :ansible_local_id => data['ansible_local_id'],
               :ansible_vars => data['ansible_vars']
            })
      end
   rescue => e
      msg = e.message
      msg.crop_zmq_error! if msg.is_zmq_error? # Crops ZmqJsonRpc backtrace from exception message
      r error: e.message, backtrace: e.backtrace
   end
end

post '/vm/:id/revert_zfs_snapshot' do | id |
   begin
      data = {'previous' => nil}
      body = JSON.parse(request.body.read)
      data.merge!(body['action']['params'])

      vm = IONe.new($client, $db).get_vm_data(id.to_i)

      if (@one_user.id != vm['OWNERID'].to_i) && !@one_user.groups.include?(0) then
         r error: "User is not OWNER for given VM", id: @one_user.id, groups: @one_user.groups
      elsif data['previous'].nil? then
         r error: 'Snapshot not given'
      else
         IONe.new($client, $db).RevertZFSSnapshot(id, data['previous']) == true ?
            r(response: "It's ok, #{data['previous'] ? 'yesterdays' : 'todays'} snapshot will be reverted") :
            r(response: "Contact Technical Support to make sure revert process started")
      end
   rescue => e
      msg = e.message
      msg.crop_zmq_error! if msg.is_zmq_error? # Crops ZmqJsonRpc backtrace from exception message
      r error: e.message, backtrace: e.backtrace
   end
end

get '/ione_conf' do
    begin
        r response: $ione_conf, ione: IONe.new($client, $db)
    rescue => e
        r error: e.message
    end
end
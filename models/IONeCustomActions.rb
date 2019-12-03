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
      res = template.info!
      if OpenNebula.is_error? res then
         raise "Access Error, contact support."
      end
      image = OpenNebula::Image.new_with_id(template['/VMTEMPLATE/TEMPLATE/DISK/IMAGE_ID'], @one_client)
      res = image.info!
      if OpenNebula.is_error? res then
         raise "Access Error, contact support."
      end

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
         result = IONe.new($client, $db).RevertZFSSnapshot(id, data['previous'])
         if result.first then
            r(response: "Snapshot revertion process prechecks are initialized", id: result.last)
         else
            r(response: "Contact Technical Support to make sure revert process started")
         end
      end
   rescue => e
      msg = e.message
      r error: e.message, backtrace: e.backtrace
   end
end

get '/zfs_snapshot_revert_status/:id' do | id |
begin
   content_type 'text/event-stream'
   headers['Cache-Control']       = "no-transform"
   process = onblock(:app, id)
   if process.status == "FAILED" then
      begin
          msg = "failed "
          log = process.to_hash['log'].split("\n").reverse
          i = log.index do | line |
              line.include? 'TASK [fail]'
          end - 1
          err = JSON.parse(log[i].slice(/{.+}/))

          if err['msg'].include? "VM has VC snap" then
              msg += "vc"
          elsif err['msg'].include? "zfs snap has VC snap" then
              msg += "zfs"
          end
      rescue
      end
   elsif process.status == "RUNNING"
      msg = "running"
   elsif process.status == "SUCCESS"
      msg = "recovered"
   end
   logger.debug("data: #{msg}\n\n")
   stream do | out |
      out << "data: #{msg}\n\n"
   end
rescue => e
   e.message
end
end

get '/ione_conf' do
    begin
        r response: $ione_conf, ione: IONe.new($client, $db)
    rescue => e
        r error: e.message
    end
end
# !@group Ansible Playbook Process Endpoints

# Returns full Ansible Playbooks Processes pool
get '/ansible_process' do
  begin
    pool = IONe.new(@client, $db).ListAnsiblePlaybookProcesses
    pool.delete_if { |apc| !@one_user.groups.include?(0) && apc['uid'] != @one_user.id }
    pool.map! do | apc | # Adds user name to every object
      user =  OpenNebula::User.new_with_id(apc['uid'], @client)
      user.info!
      apc.merge('id' => apc['proc_id'], 'uname' => user.name)
    end

    r response: pool
  rescue => e
    r error: e.message, backtrace: e.backtrace
  end
end

# Allocates new process
post '/ansible_process' do
  begin
    r response: AnsiblePlaybookProcessModel.new(id: nil, data: @request_hash, user: @one_user).id
  rescue JSON::ParserError # If JSON.parse fails
    r error: "Broken data received, unable to parse."
  rescue => e
    @one_user.info!
    r error: e.message, backtrace: e.backtrace, data: data
  end
end

# Returns playbook process data
get '/ansible_process/:id' do |id|
  begin
    apc = AnsiblePlaybookProcessModel.new(id: id, user: @one_user) # Getting playbook
    # Saving user and group to objects
    user = OpenNebula::User.new_with_id(apc.body['uid'], @client)
    user.info!
    apc.body.merge!('id' => apc.body['proc_id'], 'uname' => user.name) # Retrieving information about this objects from ONe
    r response: apc.body
  rescue => e
    r error: e.message, backtrace: e.backtrace
  end
end

# Deletes given playbook process
delete '/ansible_process/:id' do |id|
  begin
    data = { 'action' => { 'perform' => 'delete', 'params' => nil } }
    pb = AnsiblePlaybookProcessModel.new(id: id, data: data, user: @one_user)

    r response: pb.call
  rescue JSON::ParserError # If JSON.parse fails
    r error: "Broken data received, unable to parse."
  rescue => e
    r error: e.message, backtrace: e.backtrace
  end
end

# Performs action on AnsiblePlaybookProcess
post '/ansible_process/:id/action' do | id |
  begin
    pb = AnsiblePlaybookProcessModel.new(id: id, data: @request_hash, user: @one_user)

    r response: pb.call
  rescue JSON::ParserError # If JSON.parse fails
    r error: "Broken data received, unable to parse."
  rescue => e
    r error: e.message, backtrace: e.backtrace
  end
end
# !@endgroup

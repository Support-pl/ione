# Returns full Ansible Playbooks pool in OpenNebula XML-POOL format
get '/ansible' do
  begin
    pool = IONe.new($client, $db).ListAnsiblePlaybooks # Array of playbooks
    pool.delete_if { |pb| !ansible_check_permissions(pb, @one_user, 0) } # Deletes playbooks, which aren't under user access
    pool.map! do | pb | # Adds user and group name to every object
      user, group = OpenNebula::User.new_with_id(pb['uid'], @client),
                OpenNebula::Group.new_with_id(pb['gid'], @client)
      user.info!; group.info!
      pb['vars'] = IONe.new($client, $db).GetAnsiblePlaybookVariables(pb['id'])
      pb.merge(
        'uname' => user.name, 'gname' => group.name,
        'vars' => pb['vars'].nil? ? {} : pb['vars']
      )
    end
    r response: pool
  rescue => e
    r error: e.message, backtrace: e.backtrace
  end
end

# Allocates new playbook
post '/ansible' do
  begin
    r response: AnsiblePlaybookModel.new(id: nil, data: @request_hash, user: @one_user).id
  rescue JSON::ParserError # If JSON.parse fails
    r error: "Broken data received, unable to parse."
  rescue => e
    @one_user.info!
    r error: e.message, backtrace: e.backtrace, data: data
  end
end

# Deletes given playbook
delete '/ansible/:id' do |id|
  begin
    data = { 'action' => { 'perform' => 'delete', 'params' => nil } }
    pb = AnsiblePlaybookModel.new(id: id, data: data, user: @one_user)

    r response: pb.call
  rescue JSON::ParserError # If JSON.parse fails
    r error: "Broken data received, unable to parse."
  rescue => e
    r error: e.message, backtrace: e.backtrace
  end
end

# Returns playbook body in OpenNebula required format
get '/ansible/:id' do | id |
  begin
    pb = AnsiblePlaybookModel.new(id: id, user: @one_user) # Getting playbook
    # Saving user and group to objects
    user, group = OpenNebula::User.new_with_id(pb.body['uid'], @client),
              OpenNebula::Group.new_with_id(pb.body['gid'], @client)
    user.info!; group.info! # Retrieving information about this objects from ONe
    pb.body.merge!('uname' => user.name, 'gname' => group.name, 'vars' => pb.vars.nil? ? {} : pb.vars) # Adding user and group names to playbook body

    r response: pb.body
  rescue => e
    r error: e.message, backtrace: e.backtrace
  end
end

# I think it's not needed here, rly
get '/ansible/:id/vars' do | id |
  begin
    pb = AnsiblePlaybookModel.new(id: id, data: { 'action' => { 'perform' => 'vars' } }, user: @one_user)
    r vars: pb.call
  rescue => e
    r error: e.message, backtrace: e.backtrace
  end
end

# Performs action on AnsiblePlaybook
post '/ansible/:id/action' do | id |
  begin
    pb = AnsiblePlaybookModel.new(id: id, data: @request_hash, user: @one_user)

    r response: pb.call
  rescue JSON::ParserError # If JSON.parse fails
    r error: "Broken data received, unable to parse."
  rescue => e
    r error: e.message, backtrace: e.backtrace
  end
end

# Performs actions, which are defined as def self.method for AnsiblePlaybookModel model
post '/ansible/:action' do | action |
  begin
    if action == 'check_syntax' then
      r response: IONe.new($client, $db).CheckAnsiblePlaybookSyntax(@request_hash['body'])
    else
      r response: "Action is not defined"
    end
  rescue JSON::ParserError # If JSON.parse fails
    r error: "Broken data received, unable to parse."
  rescue => e
    r error: e.message, backtrace: e.backtrace
  end
end

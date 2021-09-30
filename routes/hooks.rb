# !@group Ansible Playbook Endpoints
if ALPINE then

  require 'open3'

  post '/hooks/:hook' do | hook |
    unless IPAddr.new(request.env['REMOTE_ADDR']).private? then
      halt 403
    end
    p hook
    hook = "#{ROOT_DIR}/hooks/#{hook}"
    p hook
    unless File.exist? hook then
      halt 400, { 'Content-Type': 'application/json' }, { error: "Script doesn't exist" }.to_json
    end

    p @request_hash

    stdout, stderr, status = Open3.capture3(hook + " " + @request_hash['params'].join(' '))
    p stdout, stderr, status

    json hook: hook, stdout: stdout, stderr: stderr, status: status.exitstatus
  end
end
# !@endgroup

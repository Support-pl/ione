# !@group OpenNebula Hooks Endpoints
require 'open3'

post '/hooks/:hook' do | hook |
  addr = IPAddr.new(request.env['REMOTE_ADDR'])
  unless addr.private? || addr.loopback? then
    halt 403
  end
  hook = "#{ROOT_DIR}/hooks/#{hook}"
  unless File.exist? hook then
    halt 400, { 'Content-Type' => 'application/json' }, { error: "Script doesn't exist" }.to_json
  end

  cmd = "#{RbConfig.ruby} #{hook} #{@request_hash['params'].join(' ')}"
  stdout, stderr, status = Open3.capture3(cmd)
  json hook: hook, stdout: stdout, stderr: stderr, status: status.exitstatus
end
# !@endgroup

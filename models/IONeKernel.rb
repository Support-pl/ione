require 'file-tail'
require 'sinatra-websocket'

get '/wss/ione/log/:logfile' do | logfile |
    raise Exception.new("NoAccess") unless @one_user.is_admin?
    backward = params[:backward] || 50

    request.websocket do |ws|
        ws.onopen do
            File.open("/var/log/one/#{logfile}.log") do | log |
                log.extend(File::Tail)
                log.interval = 1
                log.max_interval = 1
                log.backward(backward)
                log.tail do | line |
                    ws.send line
                end
            end
        end
    end
end
require 'net/http'

get '/vonecloud/check_version' do
    Net::HTTP.get('localhost', '/check_version', 8000)
end

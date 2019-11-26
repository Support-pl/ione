# post '/ione_showback' do
#     begin
#         data = JSON.parse(@request_body)
#         uid, stime, etime, group_by_day = data['uid'], data['stime'], data['etime'], data['group_by_day'] || false
#         r response: IONe.new($client, $db).CalculateShowback(uid, stime, etime, group_by_day)
#     rescue => e
#         r error: e.message, trace: e.backtrace
#     end
# end

post '/ione_showback' do
    headers['Cache-Control']       = "no-transform" # Disbles Rack::Deflater

    data = JSON.parse(@request_body)
    uid, stime, etime, group_by_day = data['uid'], data['stime'], data['etime'], data['group_by_day'] || false
    stream do | out |
        out << '{"response":' << "{" << IONe.new($client, $db).CalculateShowback(uid, stime, etime, group_by_day, out) << "}}"
    end
end
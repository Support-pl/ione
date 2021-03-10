post '/ione_showback' do
  headers['Cache-Control'] = "no-transform" # Disables Rack::Deflater

  data = JSON.parse(@request_body)
  uid, stime, etime, group_by_day = data['uid'], data['stime'], data['etime'], data['group_by_day'] || false
  stream do | out |
    out << '{"response":' << "{" << IONe.new($client, $db).CalculateShowback(uid, stime, etime, group_by_day, out) << "}}"
  end
end

post '/ione_showback/v2' do
  headers['Cache-Control'] = "no-transform" # Disables Rack::Deflater

  data = JSON.parse(@request_body)
  uid, stime, etime, group_by_day = data['uid'], data['stime'], data['etime'], data['group_by_day'] || false
  stream do | out |
    out << '{"response":' << "{" << IONe.new($client, $db).calculate_showback(uid, stime, etime, group_by_day, out) << "}}"
  end
end

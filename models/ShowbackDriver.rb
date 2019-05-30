post '/ione_showback' do
    begin
        data = JSON.parse(@request_body)
        uid, stime, etime, group_by_day = data['uid'], data['stime'], data['etime'], data['group_by_day'] || false
        # IONe.Test([uid, stime, etime, group_by_day])
        r response: IONe.new($client, $db).CalculateShowback(uid, stime, etime, group_by_day)
    rescue => e
        r error: e.message, trace: e.backtrace
    end
end
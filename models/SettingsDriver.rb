get '/settings' do
  begin
    begin
      access_level = env[:one_user].admin? ? 1 : 0
    rescue
      access_level = 0
    end
    json response: SETTINGS_TABLE.where(Sequel.lit('access_level <= ?', access_level)).to_a
  rescue => e
    json error: e.message, debug: e.class
  end
end

get '/settings/:key' do | key |
  begin
    begin
      access_level = env[:one_user].admin? ? 1 : 0
    rescue
      access_level = 0
    end
    json response: SETTINGS_TABLE.where(Sequel.lit('access_level <= ?', access_level)).where(name: key).to_a.last
  rescue => e
    json error: e.message
  end
end

post '/settings' do
  begin
    raise StandardError.new("NoAccess") unless env[:one_user].admin?

    data = JSON.parse(@request_body)
    json response: SETTINGS_TABLE.insert(**data.to_sym!)
  rescue => e
    json error: e.message
  end
end

post '/settings/:key' do | key |
  begin
    raise StandardError.new("NoAccess") unless env[:one_user].admin?

    data = JSON.parse(@request_body)
    data = data.to_sym!
    json response: SETTINGS_TABLE.where(name: key).update(name: key, **data)
  rescue => e
    json error: e.message
  end
end

delete '/settings/:key' do | key |
  begin
    raise StandardError.new("NoAccess") unless env[:one_user].admin?

    json response: SETTINGS_TABLE.where(name: key).delete
  rescue => e
    json error: e.message
  end
end

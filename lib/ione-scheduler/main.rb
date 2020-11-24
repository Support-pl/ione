require 'mysql2'

# Generates class from string class-name
def class_from_string(str)
    str.split('::').inject(Object) do |mod, class_name|
      mod.const_get(class_name)
    end
end

@db_client = Mysql2::Client.new(
    :username => $ione_conf['DB']['user'], :password => $ione_conf['DB']['pass'], 
    :host => $ione_conf['DB']['host'], :database => 'ioneschedule'
)

# Schedules action
def Schedule(time, action, *params)
    # action = action.split('.')

    @db_client.query(
        "INSERT INTO action (method, params, time)
         VALUES ('#{action}', '#{JSON.generate(params)}', '#{time}')"
    )
    @db_client.query('SELECT * FROM action').to_a.last['id']
end

# Unschedules action
def Unschedule(id)
    @db_client.query(
        "DELETE FROM action WHERE id=#{id}"
    )
end

# Invokes scheduled action
def Invoke(action)
    Unschedule(action['id'])
    IONe.new($client, $db).send(action['method'], *(JSON.parse(action['params'])))
end

Thread.new do
    LOG 'Scheduler thread started', 'IONeScheduler'
    loop do
        @db_client.query(
            "SELECT * FROM action WHERE time < #{Time.now.to_i}"
            ).to_a.each do | action |
                result = 
                    begin
                       Invoke(action)
                    rescue => e
                       e.message
                    end
                LOG "Calling #{action['method']}(#{JSON.parse(action['params']).to_s}), result:\n#{result.to_s}", 'IONeScheduler'
            end

        sleep(30)
    end
end
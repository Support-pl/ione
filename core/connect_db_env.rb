db_backend = ENV['DB_BACKEND'] # mysql or postgresql
case db_backend
when "mysql"
  adapter = :mysql2
when "postgresql"
  adapter = :postgres
else
  STDERR.puts "OneDB backend(#{db_backend}) is not supported, exiting..."
  exit 1
end

ops = {}
ops[:host]     = ENV['DB_HOST']
ops[:user]     = ENV['DB_USER']
ops[:password] = ENV['DB_PASSWORD']
ops[:database] = ENV['DB_DATABASE']

ops.merge! adapter: adapter

require 'sequel'
begin
  print "Connecting to DB... "
  $db = Sequel.connect(**ops)
rescue => e
  puts "Error connecting to DB: #{e.message}"
  puts "Retrying in 60 sec"
  sleep 60
  puts "Retrying..."
  retry
end
puts "Connected"

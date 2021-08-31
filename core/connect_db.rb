db_backend = ($oned_conf.get('DB/BACKEND') || $oned_conf.get('DB/backend')).delete("\"")
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
ops[:host]     = ($oned_conf.get('DB/SERVER') || $oned_conf.get('DB/server'))
ops[:user]     = ($oned_conf.get('DB/USER') || $oned_conf.get('DB/user'))
ops[:password] = ($oned_conf.get('DB/PASSWD') || $oned_conf.get('DB/passwd'))
ops[:database] = ($oned_conf.get('DB/DB_NAME') || $oned_conf.get('DB/db_name'))

ops.each do |k, v|
  next if !v || !(v.is_a? String)
  ops[k] = v.delete("\"")
end

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

if $oned_conf.get('DB/BACKEND') != "\"mysql\"" then
  STDERR.puts "OneDB backend is not MySQL, exiting..."
  exit 1
end

ops = {}
ops[:host]     = $oned_conf.get('DB/SERVER')
ops[:user]     = $oned_conf.get('DB/USER')
ops[:password] = $oned_conf.get('DB/PASSWD')
ops[:database] = $oned_conf.get('DB/DB_NAME')

ops.each do |k, v|
  next if !v || !(v.is_a? String)

  ops[k] = v.chomp('"').reverse.chomp('"').reverse
end

ops.merge! adapter: :mysql2, encoding: 'utf8mb4'

require 'sequel'
$db = Sequel.connect(**ops)

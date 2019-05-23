`gem install shell`
require 'shell'
sh = Shell.new

#####################################
# Setting ENV
#####################################

src_dir = sh.pwd

#####################################
# Installing packages
#####################################

puts "Installing NPM and zeromq"
sh.system `yum install -y npm make automake gcc gcc-c++ kernel-devel ruby-devel zeromq zeromq-devel`

puts "Installing bower and grunt"
sh.system 'npm install -g bower grunt grunt-cli'

puts "Moving sunstone src files"
sunstone = %w(
    models public routes views ione
)

sunstone.each do | files |
    sh.system "cp -rf #{files} /usr/lib/one/sunstone/"
end
sh.system "cp sunstone-server.rb /usr/lib/one/sunstone/"
sh.system "cp config.ru /usr/lib/one/sunstone/"

sh.cd '/usr/lib/one/sunstone/public'

puts "Installung bower and NPM packages"
sh.system 'npm install && bower install --allow-root'

puts "Building source"
sh.system 'grunt requirejs'

puts "Installing gems for IONe"
sh.system 'gem install zmqjsonrpc colorize nori mysql2 sequel'
sh.system 'gem install net-ssh -v 4.2'
sh.system 'gem install net-sftp'

sh.cd src_dir

sh.system 'cp -f ./sunstone-views.yaml /etc/one/'
sh.system 'cp -rf ./sunstone-views /etc/one/'
# sh.system 'cp -f ./ione/ione.conf /etc/one/'
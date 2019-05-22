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

puts "Installing NPM"
sh.system `yum install -y npm`

puts "Installing bower and grunt"
sh.system 'npm install -g bower grunt grunt-cli'

puts "Moving sunstone src files"
sunstone = %w(
    config.ru models public routes sunstone-server.rb views
)

sunstone.each do | files |
    sh.system "cp -rf ./#{files} /usr/lib/one/sunstone/"
end
    
sh.cd '/usr/lib/one/sunstone/public'

puts "Installung bower and NPM packages"
sh.system 'npm install && bower install --allow-root'

puts "Building source"
sh.system 'grunt requirejs'

sh.cd src_dir


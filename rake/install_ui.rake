@sunstone = %w(
    public routes views sunstone-server.rb config.ru
)

desc "IONe Sunstone Skin Installation"
task :install_ui => [:before, :install_gems] do
    puts "Installing bower and grunt..."
    sh %{sudo npm install -g bower grunt grunt-cli}
    puts

    puts "Moving sunstone src files"
    @sunstone.each do | files |
        cp_r "#{files}", "/usr/lib/one/sunstone/"
    end
    chown_R "oneadmin", "oneadmin", "/usr/lib/one/sunstone/"

    cd '/usr/lib/one/sunstone/public'
    unless system('which npm') then
        puts "No python2 found, installing..."
        sh %{sudo yum install python2}
    end
    puts "Installung bower and NPM packages"
    sh %{sudo npm install && bower install --allow-root}
    puts

    puts "Building UI..."
    chmod "+x", "build.sh"
    sh %{sudo ./build.sh}
    cp "./dist/main-dist.js", "./dist/main.js"

    cd @src_dir

    puts <<-EOF
    Don't forget to configure views at /etc/one.
    You can use configs provided by us.
    Just copy it:
    
        cp -f sunstone-views.yaml /etc/one/
        cp -rf sunstone-views /etc/one/

        sudo chown -R oneadmin:oneadmin /etc/one/
        sudo chmod -R 775 /etc/one/
    EOF
end
task :before do
    whoami = `whoami`.chomp
    if whoami != 'root' then
        puts "You must be root to run this installer."
        exit(-1)
    end
end

desc "Install Gems"
task :install_gems => :before do
    puts "Installing Gems:\n"

    puts "1. Checking distro..."
    lsb_info=`lsb_release -a 2>/dev/null`
    if $?.exitstatus != 0
        sh %{sudo yum install redhat-lsb}
    end
    puts

    puts "2. Appending gems to Gemfile..."

    sh %{sudo chown -R oneadmin:oneadmin /usr/share/one/}
    gems = File.read('Gemfile')
    File.open('/usr/share/one/Gemfile', 'a') do | gemfile |
        gemfile << "\n# Gems for IONe\n"
        gemfile << gems
    end
    puts

    puts "3. Initializing bundler..."
    sh %{/usr/share/one/install_gems --yes}
end

desc "IONe Back-End Installation"
task :install_ione => [:before, :install_gems] do
    puts "back-end installing..."
    puts "done"
end

desc "IONe Sunstone Skin Installation"
task :install_ui => :before do
    puts "ui installing..."
    puts "done"
end

desc "Full IONe Installation"
task :install => [:before, :install_ione, :install_ui] do
    puts "Full installation"
end

task :test do
    sh %{whoami}
end
@sys_packages = %w(npm make automake gcc gcc-c++ kernel-devel ruby-devel zeromq zeromq-devel)

desc "Install Gems"
task :install_gems => :before do
    puts "Installing Gems:\n"

    puts "1. Checking distro..."
    `lsb_release -a 2>/dev/null`
    if $?.exitstatus != 0
        sh %{sudo yum install redhat-lsb}
    end
    puts

    puts "2. Appending gems to Gemfile..."

    chown_R "oneadmin", "oneadmin", "/usr/share/one/"
    gems = File.read('Gemfile')
    File.open('/usr/share/one/Gemfile', 'a') do | gemfile |
        gemfile << "\n# Gems for IONe\n"
        gemfile << gems
    end
    puts

    puts "3. Initializing bundler..."
    sh %{/usr/share/one/install_gems --yes}
    puts

    puts "4. Installing required system libs and tools"
    sh %{sudo yum install -y #{@sys_packages.join(' ')}}
    puts

    puts "Done.\n"
end
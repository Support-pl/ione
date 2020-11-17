@sys_packages = %w(npm make automake gcc gcc-c++ kernel-devel ruby-devel)

desc "Install Gems"
task :install_gems => :before do
    puts "Installing Gems:\n"

    puts "1. Installing gems..."
    sh %{gem install nori}
    sh %{gem install net-ssh -v 6.1.0}
    sh %{gem install net-sftp -v 3.0.0}
    sh %{gem install colorize}
    sh %{gem install sinatra-contrib}
    puts

    puts "2. Installing required system libs and tools"
    begin
        sh %{sudo yum install -y #{@sys_packages.join(' ')}}
    rescue
        puts <<-EOF
        It seems to be, that you aren't using CentOS or yum doesn't work properly, follow next steps:
    
        1. Install this packages manually:
            
            #{@sys_packages.join(' ')}
        
        2. If wanted to install our Sunstone version too, run
            
            rake install
        
        3. If you want to install IONe only, run

            rake install_ione
    
        Thanks, for installation and choosing us!
        EOF
    end
    puts

    puts "Done.\n"
end
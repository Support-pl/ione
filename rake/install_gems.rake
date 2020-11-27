@sys_packages = %w(npm make automake gcc gcc-c++ kernel-devel ruby-devel)

desc "Install Gems"
task :install_gems => :before do
    puts "Installing Gems:\n"

    puts "1. Installing gems..."
    sh %{gem install nori --no-document}
    sh %{gem install net-ssh -v 6.1.0 --no-document}
    sh %{gem install net-sftp -v 3.0.0 --no-document}
    sh %{gem install colorize --no-document}
    sh %{gem install sinatra-contrib --no-document}
    puts

    puts "2. Installing required system libs and tools"
    begin
        sh %{sudo yum install -y #{@sys_packages.join(' ')}}
    rescue
        $messages << <<-EOF
        It seems to be, that you aren't using CentOS or yum doesn't work properly, follow next steps:
    
        1. Install this packages manually:
            
            #{@sys_packages.join(' ')}
        
        2. Install need parts using commands from:

            rake --tasks
    
        Thanks, for installation and choosing us!
        EOF
    end
    puts

    puts "Done.\n"
end
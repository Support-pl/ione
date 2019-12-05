task :before do
    whoami = `whoami`.chomp
    if whoami != 'root' then
        puts "You must be root to run this installer."
        exit(-1)
    end

    @src_dir = pwd
end

load "rake/set_hooks.rake"
load "rake/install_ui.rake"
load "rake/install_gems.rake"
load "rake/install_ione.rake"

desc "Full IONe Installation"
task :install => [:before, :install_ione, :install_ui] do
end

task :test do
    puts <<-EOF
    > If you have one with httpd installed, restart httpd:

        sudo systemctl restart httpd
        
    EOF
end
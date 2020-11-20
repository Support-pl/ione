task :before do
    whoami = `whoami`.chomp
    if whoami != 'root' then
        puts "You must be root to run this installer."
        exit(-1)
    end

    unless system('which nginx') then
        puts "NGINX must be installed before proceeding with IONe"
        exit(-1)
    end

    @src_dir = pwd
end

task :useful_questions do
    @domain = nil
    while @domain.nil?
        print "Please enter your base domain: "
        @domain = STDIN.gets.strip.downcase
        print "You've entered '#{@domain}', is it correct? (y/n) "
        a = STDIN.gets.strip.downcase
        @domain = nil unless a == 'y'
    end
end

load "rake/install_gems.rake"
load "rake/install_ione.rake"
load "rake/install_ui.rake"
# load "rake/set_hooks.rake"
load "rake/test_install.rake"

desc "Full IONe Installation"
task :install => [:before, :install_gems, :install_ione] do
    puts "  Thanks, for installation and choosing us!   "
end
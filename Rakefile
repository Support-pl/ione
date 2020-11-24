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
    puts
    puts "IONe installer is going to overwrite your nginx configuration."
    nginx = nil
    until ['y', 'n'].include? nginx do
        print "Do you want to continue? (y/n) "
        nginx = STDIN.gets.strip.downcase
    end
    if nginx == 'n' then
        puts "Exiting"
        exit 0
    end

    @domain = nil
    while @domain.nil?
        print "Please enter your base domain: "
        @domain = STDIN.gets.strip.downcase

        puts "You've entered '#{@domain}'"
        puts "Nginx going to be configured with following server names:"
        puts "  cloud.#{ @domain }      --> Sunstone"
        puts "  ione-api.#{ @domain }   --> IONe API"
        puts "  ione-admin.#{ @domain } --> IONe UI"
        puts "------------------------------------------------"
        print "Is that correct? (y/n) "

        a = STDIN.gets.strip.downcase
        @domain = nil unless a == 'y'
    end
end

load "rake/install_gems.rake"
load "rake/install_ione.rake"
load "rake/install_ui.rake"
load "rake/set_hooks.rake"
load "rake/configure_nginx.rake"
load "rake/test_install.rake"

desc "Full IONe Installation"
task :install => [:before, :install_gems, :install_ione] do
    puts "  Thanks, for installation and choosing us!   "
end
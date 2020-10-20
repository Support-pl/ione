task :before do
    whoami = `whoami`.chomp
    if whoami != 'root' then
        puts "You must be root to run this installer."
        exit(-1)
    end

    @src_dir = pwd
end

load "rake/install_gems.rake"
load "rake/install_ione.rake"
load "rake/install_ui.rake"
load "rake/set_hooks.rake"

desc "Full IONe Installation"
task :install => [:before, :install_gems, :install_ione, :install_ui] do
    puts "  Thanks, for installation and choosing us!   "
end
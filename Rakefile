$messages = []

task :before, [:packm, :silent, :domain] do | _task, args |
  @packm  = args[:packm] || 'yum'
  @silent = args[:silent]
  @domain = args[:domain]

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
  @version = File.read("#{@src_dir}/meta/version.txt")
  puts "Installing IONe #{@version}"
end

task :useful_questions do
  puts
  puts "IONe installer is would like to overwrite your nginx configuration."
  @nginx = @silent
  until ['y', 'n'].include? @nginx do
    print "Do you want to continue? (y/n) "
    @nginx = STDIN.gets.strip.downcase
  end

  while @domain.nil?
    print "Please enter your base domain: "
    @domain = STDIN.gets.strip.downcase

    puts "You've entered '#{@domain}'"
    puts "Nginx should to be configured with following server names:"
    puts "  cloud.#{@domain}      --> Sunstone"
    puts "  ione-api.#{@domain}   --> IONe API"
    puts "  ione-admin.#{@domain} --> IONe UI"
    puts "------------------------------------------------"
    print "Is that correct? (y/n) "

    a = STDIN.gets.strip.downcase
    @domain = nil unless a == 'y'
  end
  puts "Using '#{@domain}' as base domain."
end

load "rake/install_gems.rake"
load "rake/install_ione.rake"
load "rake/install_ui.rake"
load "rake/configure_nginx.rake"
load "rake/set_hooks.rake"
load "rake/test_install.rake"

desc "Full IONe Installation"
task :install, [:packm, :silent, :domain] => [:before, :useful_questions, :install_gems, :install_ione, :hooks, :install_ui, :configure_nginx] do
  $messages << <<-EOF
    Thanks, for installation and choosing us!
    Configure ione with ione.conf & IONe UI and test install with: rake test_install
  EOF

  for msg in $messages do
    puts msg
  end
end

desc "IONe check update"
task :check_update do
  sh %{git checkout master}
  sh %{git pull}
  current = File.read('./meta/version.txt')
  installed = File.read('/usr/lib/one/ione/meta/version.txt')
  puts "\n" * 5
  if current != installed then
    puts "Update available! \n !!! DANGEROUS!!! Run rake update to install it."
  else
    puts "You are up to date."
  end
end

desc "IONe update"
task :update, [:silent, :domain] => [:before, :useful_questions, :install_gems, :install_ione, :hooks, :install_ui, :configure_nginx] do
  for msg in $messages do
    puts msg
  end
  puts "IONe #{@version} is now installed, you're up to date!"
end

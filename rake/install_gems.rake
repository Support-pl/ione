@sys_packages = %w(npm make automake gcc gcc-c++ kernel-devel ruby-devel mysql-devel)

desc "Install Gems"
task :install_gems => :before do
  puts "Installing Gems:\n"

  puts "1. Installing gems..."
  sh %{bundle install}
  puts

  puts "2. Installing required system libs and tools"
  puts "Following packages are going to be installed:\n\t#{@sys_packages.join(' ')}"
  a = @silent
  until %w(y n).include? a do
    print "Proceed? (y/n) "
    a = STDIN.gets.downcase.strip
  end
  exit 0 if a == 'n'
  puts "Installing..."
  begin
    sh %{sudo yum install -yq #{@sys_packages.join(' ')}}
  rescue
    $messages << <<~EOF
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

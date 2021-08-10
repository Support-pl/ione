@sys_packages = {
  'yum' => %w(npm make automake gcc gcc-c++ kernel-devel ruby-devel mysql-devel),
  'apt' => %w(npm make automake gcc ruby-dev libmariadb-dev)
}

@pack_managers = {
  'yum' => "yum install -yq",
  'apt' => "apt update && apt -yqq install"
}

desc "Install Gems"
task :install_gems, [:packm, :silent] => :before do | _task, args |
  puts "Installing Gems:\n"

  puts "1. Installing required system libs and tools"
  puts "Following packages are going to be installed:\n\t#{@sys_packages[@packm].join(' ')}"

  a = nil
  a = 'y' if @silent == 'y' || args[:silent] == 'y'

  until %w(y n).include? a do
    print "Proceed? (y/n) "
    a = STDIN.gets.downcase.strip
  end
  exit 0 if a == 'n'

  @packm = args[:packm] || 'yum'
  puts "Installing..."
  begin
    sh %{sudo #{@pack_managers[@packm]} #{@sys_packages[@packm].join(' ')}}
  rescue
    $messages << <<~EOF
      It seems to be, that #{@packm} doesn't work properly, follow next steps:
      1. Install this packages manually:
          #{@sys_packages[@packm].join(' ')}
      2. Install need parts using commands from:
          rake --tasks
      Thanks, for installation and choosing us!
    EOF
    exit 1
  end
  puts

  puts "2. Installing gems..."
  sh %{bundle install}
  puts

  puts "Done.\n"
end

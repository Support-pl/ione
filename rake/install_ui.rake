desc "IONe Admin UI Installation"
task :install_ui do
    puts 'Copying UI files'
    cp_r 'ui', '/usr/lib/one/ione/'

    cd '/usr/lib/one/ione/ui/'
    puts "Installing dependencies"
    sh %{sudo npm install}

    puts "Building static UI"
    sh %{sudo npm run build}

    puts "Changing owner"
    chown_R "oneadmin", "oneadmin", "/usr/lib/one/ione/ui/dist"

    puts "Done"
end
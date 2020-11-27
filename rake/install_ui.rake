desc "IONe Admin UI Installation"
task :install_ui => [:useful_questions] do
    puts 'Copying UI files'
    cp_r 'ui', '/usr/lib/one/ione/'

    puts "Installing dependencies"
    cd '/usr/lib/one/ione/ui/'
    sh %{sudo npm install --quiet --no-progress}

    puts "Generating config"
    File.open("/usr/lib/one/ione/ui/src/config/index.js", 'w') do | f |
        f.puts <<-EOF
            module.exports = {
                CLOUD_API_BASE_URL: "https://ione-api.#{@domain}",
            };
        EOF
    end

    puts "Building static UI"
    sh %{sudo npm run build}

    puts "Changing owner"
    chown_R "oneadmin", "oneadmin", "/usr/lib/one/ione/ui/dist"

    puts "Done"
end
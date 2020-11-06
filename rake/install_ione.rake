require 'pathname'

@ione = %w(
    models modules lib scripts service ione_server.rb ione_driver.rb meta
)
@ione_logs = %w(
    ione debug rpc suspend
)

desc "IONe Back-End Installation"
task :install_ione => [:before, :install_gems] do
    puts 'Copying conf'
    cp 'sys/ione.conf', '/etc/one/' unless Pathname.new("/etc/one/ione.conf").exist?

    puts 'Creating log files'
    @ione_logs.each do | file |
        touch "/var/log/one/#{file}.log"
    end
    chown_R "oneadmin", "oneadmin", "/var/log/one/"
    chmod 0750, "/var/log/one/"
    puts "chmod -R 644 /var/log/one/*"
    `chmod -R 644 /var/log/one/*`

    puts 'Creating IONe directory'
    mkdir_p '/usr/lib/one/ione'

    puts 'Copying IONe files'
    @ione.each do | files |
        cp_r "#{files}", "/usr/lib/one/ione/"
    end

    puts 'Creating IONe service'
    cp 'sys/ione.service', '/usr/lib/systemd/system' unless Pathname.new("/usr/lib/systemd/system/ione.service").exist?

    puts <<-EOF
    Fill in DB credentials to /etc/one/ione.conf and start IONe
        systemctl enable ione
        systemctl start ione
    EOF
end

require 'pathname'

@ione = %w(
    models modules lib scripts service ione_server.rb meta
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
    chown_R "oneadmin", "oneadmin", "/usr/lib/one/ione/"

    puts 'Creating IONe service'
    cp 'sys/ione.service', '/usr/lib/systemd/system' unless Pathname.new("/usr/lib/systemd/system/ione.service").exist?

    $messages << <<-EOF
    Fill /etc/one/ione.conf and start IONe
        systemctl enable ione
        systemctl start ione
    
    You can test installation by running
        rake test_install
    EOF
end

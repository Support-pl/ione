@ione = %w(
    models ione debug_lib.rb
)
@ione_logs = %w(
    ione debug rpc suspend
)

desc "IONe Back-End Installation"
task :install_ione => [:before, :install_gems] do
    puts 'Copying conf'
    cp './ione/ione.conf', '/etc/one/'

    puts 'Creating log files'
    @ione_logs.each do | file |
        touch "/var/log/one/#{file}.log"
    end
    chown_R "oneadmin", "oneadmin", "/var/log/one/"
    chmod 0750, "/var/log/one/"
    `chmod -R 644 /var/log/one/*`

    puts 'Copying IONe'
    @ione.each do | files |
        cp_r "#{files}", "/usr/lib/one/sunstone/"
    end

    puts 'Restarting OpenNebula'
    sh %{sudo systemctl restart opennebula && sudo systemctl status opennebula}
    sh %{sudo systemctl restart opennebula-sunstone && sudo systemctl status opennebula-sunstone}

    puts <<-EOF
    > If you have one with httpd installed, restart httpd:

        sudo systemctl restart httpd

    EOF
end

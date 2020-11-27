desc "Generate self signed certificate"
task :generate_certificate => [ :useful_questions ] do
    mkdir_p '/etc/one/ssl'
    sh %{openssl req -x509 -newkey rsa:4096 -keyout  /etc/one/ssl/#{@domain}.key -out /etc/one/ssl/#{@domain}.crt -days 365 -nodes -subj "/C=CA/ST=None/L=NB/O=None/CN=*.#{@domain}"}
    sh %{openssl dhparam -out /etc/one/ssl/dhparam.pem 1024}
end
desc "Configure Nginx"
task :configure_nginx => [ :useful_questions ] do
    cd @src_dir
    
    puts
    print "Do you want installer to generate self-signed cert? (y/n) "
    cert = nil
    until ['y', 'n'].include? cert do
        cert = STDIN.gets.strip.downcase
    end
    if cert == 'y' then
        Rake::Task[:generate_certificate].invoke
    else
        puts "Replace /etc/one/ssl/#{@domain}.key and /etc/one/ssl/#{@domain}.crt with your cert and generate pem with:"
        puts "  openssl dhparam -out /etc/one/ssl/dhparam.pem 1024" 
        puts
    end

    cp '/etc/nginx/nginx.conf', '/etc/nginx/nginx.conf.rake_save'
    sh %{\\rm -f /etc/nginx/conf.d/*}
    cp 'sys/nginx.conf', '/etc/nginx/nginx.conf'

    tmpl = File.read('sys/nginx.host.conf.template')
    File.open("/etc/nginx/conf.d/#{@domain}.conf", 'w') do | conf |
        conf.puts tmpl % { root_domain: @domain } 
    end

    puts
    puts "Test nginx configuration:"
    sh %{nginx -t}

    $messages << <<-EOF
    If nginx conf is okay, restart nginx via:
       systemctl restart nginx"
    
     We highly recommend to change sunstone-server.conf 'bind' from 0.0.0.0 to localhost
    EOF
end
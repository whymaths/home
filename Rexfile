user "root";

public_key "/opt/work/worker/.ssh/id_rsa.pub";

timeout 2;

parallelism 8;

logging to_file => "/tmp/rex.log";

group "bx" => "10.16.11.[21..40]", "10.11.149.[24..35]", "10.11.149.37", "10.11.149.[39..48]", "10.11.152.107", "10.11.152.113", "10.11.152.216", "10.11.152.224", "10.11.152.[33..62]", "10.11.152.[65..87]", "10.11.157.[27..28]", "192.168.12.[173..177]", "192.168.12.[196..197]", "192.168.12.73", "10.10.68.22", "10.10.68.50", "10.10.72.181";

group "pp" => "10.11.149.24";


desc "Get Disk Free";
task "disk_free", group => "bx", sub {
   my $output = run "df -h";
   say $output;
};

desc "Install Apache2";
task "install_apache2", group => "bx", sub {
    install "httpd";
};

task "ps", group => "bx", sub {
    my $server = connection->server;
    for my $process (ps()) {
        if ($process->{"command"} =~ m/puppet/xms) {
            say "{ip => $server, command => $process->{'command'}, pid => $process->{'pid'}}";
        }
    }
};


task "restart_puppet", group => "bx", sub {
    run "/etc/init.d/puppet restart";
};


task "scp_libssh2", sub {
    upload "backup/libssh2-1.4.3.tar.gz", "/root/";

};

use Rex::Commands::Host;

task "add_host", group => "pp", sub {
    create_host "rexify.org", {
        ip      => "88.198.93.110",
        aliases => ["rexify org",]
    };

    delete_host "rexify org";
};

use Rex::Commands::Cron;

task "add_cron", group => "pp", sub {
    cron add => "root", {
        minute => "*/3",
        command => "echo hello"
    };

    use Data::Dumper qw(Dumper);

    my @crons = cron list => "root";
    print Dumper(\@crons);
};



task "test_tpl", group => "pp", sub {
    my @array = ("one", "two", "three");

    my %hash = (
        name => "foo",
        age => 100
    );

    my @nested = (
        {
            name => "bar",
            age => 31,
        },
        {
            name => "baz",
            age => 29,
        },
    );

    file "test_tpl", content => template(
        "test_tpl.tpl",
        name_of_array_inside_template => \@array,
        name_of_hash_inside_template => \%hash,
        name_of_nested => \@nested,
    );
};



group "frontend_nginx" => "10.10.68.22", "10.10.68.50", "10.10.72.181", "192.168.12.177", "192.168.12.174", "192.168.12.73";

use Rex::Commands::Tail;

desc "Tail frontend nginx access logs";

task "tail_frontend_nginx_access_log", group => "frontend_nginx", sub {
    tail "/opt/nginx/logs/access.log", sub {
        my $data = shift @_;
        #chomp $data;
        my $server = connection->server;

        my @items = split (/\s+/, $data);
        my $ip = $items[0];
        my $ip_forwarded = $items[-2];

        print "$data\n";
        print "[$server]: $ip, $ip_forwarded\n";
    };
};



task "regist_nginx", group => "frontend_nginx", sub {
    my $server = connection->server;
    print "{$server\t=>\n", split /\r/, run "tail -n 200000 /opt/nginx/logs/access.log | grep Regist | grep -v downloadRegistrationInfo |  grep -v \" 403 \" | awk '{print \$1,\$NF,\$(NF-1)}' | sort | uniq -c | sort -n | tail -n 2";
    print "\n};\n";
};

task "nginx_topip", group => "frontend_nginx", sub {
    my $server = connection->server;

    print "{$server\t=>\n", split /\r/, run "tail -n 200000 /opt/nginx/logs/access.log |  grep -v \" 403 \" | awk '{print \$1,\$NF,\$(NF-1)}' | sort | uniq -c | sort -n | tail -n 4";

    print "\n};\n";
}

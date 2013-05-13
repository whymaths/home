#!/usr/bin/perl 
use strict;
use warnings;

use Storable;
#use List::MoreUtils qw(any);

my @ignore_ips = qw(
    61.135.151.250
    110.96.178.139
    123.126.48.28
);

my %ignore_ips = map {
    $_ => 1
} @ignore_ips;


use Carp qw(croak carp confess);

#use Smart::Comments;

my %ERRORS=('OK'=>0,'WARNING'=>1,'CRITICAL'=>2,'UNKNOWN'=>3,'DEPENDENT'=>4);

use Data::Dumper;


if (chomp (my $line = <STDIN>)) {
    my $service;
    my $pattern;
    my $group;


    if ($line =~ m/(\w+)\@\@(\w+)\@\@(\w+)/xms) {
        $service = $1;
        $pattern = $2;
        $group = $3;
    }

    unless ($service || $pattern || $group) {
        print "undef\n";
        exit $ERRORS{'OK'};
    }

    #print STDERR "hello\n";
    if ($group eq 'http_server') {
        print "undef\n";
        exit $ERRORS{'OK'};
    }

    elsif ($group eq 'linux') {
        if ($service =~ m/^float_(\d+)$/xms) {
            check_float($1);
            print "ok,|in=0 out=0\n";
            exit $ERRORS{'OK'};
        }
        print "undef|in=0 out=0\n";
        exit $ERRORS{'OK'};
    }
    elsif ($group eq 'main') {
        if ($service eq 'regist' && $pattern eq 'nginx') {
            check_regist_ip();
            print "ok, \n";
            exit $ERRORS{'OK'};
        }
        elsif ($service eq 'topip' && $pattern eq 'nginx') {
            check_topip();
            print "ok, \n";
            exit $ERRORS{'OK'};
        }
        else {
            print "undef\n";
            exit $ERRORS{'OK'};
        }
    }
    elsif ($group eq 'client') {
        if ($service eq 'pic' && $pattern eq 'nginx') {
            check_client_nginx_pic();
            print "ok, 0|timeout=0\n";
            exit $ERRORS{'OK'};
        }

        elsif ($service eq 'pic' && $pattern eq 'resin') {
            check_client_resin_pic();
            print "ok, 0|timeout=0\n";
            exit $ERRORS{'OK'};
        }

        print "undef|timeout=0\n";
        exit $ERRORS{'OK'};
    }


    elsif ($group eq 'java') {
        if ($service eq 'resin_thread') {
            my $threads = `ps  -eLf|grep resin | grep "web_port=$pattern" |grep -v grep|wc -l`;
            if (defined $threads && $threads > 800) {
                print "Error: resin_$pattern has $threads threads\n";
                exit $ERRORS{'OK'};
            }
            elsif (defined $threads) {
                print "ok, resin_$pattern threads: $threads\n";
                exit $ERRORS{'CRITICAL'};
            }
        }

        elsif ($service eq 'dc_jobkeeper') {
            check_dc_jobkeeper();
            print "ok, 0|timeout=0\n";
            exit $ERRORS{'OK'};
        }

        print "undef\n";
        exit $ERRORS{'OK'};
    }

    elsif ($group eq "pattern") {
        eval {
            my $rt;

            if ($service =~ m/800\d+/xms) {
                $rt = `grep $pattern /opt/newtw/log/server/rmi_$service/rmi_$service\_info.log.2013-01-05`;
                print $rt;
                exit $ERRORS{'OK'};
            }

            elsif ($service =~ m/^nginx_access$/xms) {
                $rt = `grep $pattern /opt/nginx/logs/access.log`;
                print $rt;
                exit $ERRORS{'OK'};
            }

            elsif ($service =~ m/^nginx_error$/xms) {
                $rt = `grep $pattern /opt/nginx/logs/error.log`;
                print $rt;
                exit $ERRORS{'OK'};
            }
        };

        print "undef\n";
        exit $ERRORS{'OK'};
    }

    elsif ($group eq 'proc_name') {
        my $proc_count = `ps aux | grep $service | grep -v grep | wc -l`;
        chomp($proc_count);
        print "ok, $service run ok\n" if $proc_count;
        exit $ERRORS{'OK'} if $proc_count;

        print "error, $service die\n" unless $proc_count;
        exit $ERRORS{'CRITICAL'} unless $proc_count;
    }
    elsif ($group eq 'soa_log') {
        eval {
            check_soa_log($service, $pattern);
        };
    }
 
    print "undef\n";
    exit $ERRORS{'OK'};
}

print "undef\n";
exit $ERRORS{'OK'};


sub usage {
    my $format=shift;
    printf($format,@_);
    exit $ERRORS{'UNKNOWN'};
}


sub is_ip_or_hostname {

    my $host = shift;
    return 0 unless defined $host;
    if ($host =~ m/^[\d\.]+$/ && $host !~ /\.$/) {
        if ($host =~ m/^[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+$/) {
            return 1;
        } else {
            return 0;
        }
    } elsif ($host =~
            m/^[a-zA-Z0-9][-a-zA-Z0-9]*(\.[a-zA-Z0-9][-a-zA-Z0-9]*)+$/) {
        return 1;
    } else {
        return 0;
    }
}



sub check_float {
    #check_float: default 80%
    my $check_percent = shift;;

    my $net_in;
    my $net_out;

    my $net_in_old;
    my $net_out_old;


    my $nrpe_host;
    eval {
        open $nrpe_host, "< /tmp/float" or die "cannot open /tmp/float: $!";
    }; 

    print "undef, \n" if $@;
    exit $ERRORS{'OK'} if $@;

    my $in_rate_1 = 0;
    my $out_rate_1 = 0;
    my $error_msg = '';
    my $perf_msg = '';
    my $status = 0;

    while (my $line = <$nrpe_host>) {
        chomp $line;

        my $device_name;

        if ($line =~ m/(\S+)\:\ (\S+)\,\ (\S+)/gxms) {
            $device_name = $1;
            $in_rate_1 = $2;
            $out_rate_1 = $3;

            my $in_rate = sprintf("%0.2f", $in_rate_1);
            my $out_rate = sprintf("%0.2f", $out_rate_1);
    
            if ($in_rate >= $check_percent) {
                $error_msg .= " $device_name input: $in_rate";
                $status = 1;
            }

            if ($out_rate >= $check_percent) {
                $error_msg .= " $device_name output: $in_rate";
                $status = 1;
            }

            $perf_msg .= " $device_name\_in=";
            $perf_msg .= "$in_rate;80;90;";
            $perf_msg .= " $device_name\_out=";
            $perf_msg .= "$out_rate;80;90;";
        }
    }
    print "error,$error_msg|$perf_msg\n" if $status;
    exit $ERRORS{'CRITICAL'} if $status;


    print "ok, |$perf_msg\n";
    exit $ERRORS{'OK'};
}

sub check_soa_log {
    my $service = shift;
    my $port = shift;

    my $st_mysql_stat = "/tmp/soa_log_mysql.$port.stat";
    my $st_mysql_log = "/tmp/soa_log_mysql.$port";

    my $st_memcached_stat = "/tmp/soa_log_memcached.$port.stat";
    my $st_memcached_log = "/tmp/soa_log_memcached.$port";


    if (lc($service eq 'mysql')) {
        open my $mysql, "< $st_mysql_log" or die "cannot open $st_mysql_log: $!";
        while (my $line = <$mysql>) {
            chomp $line;

            if ( defined $line && $line ne "") {
                store \$line, $st_mysql_stat;
                print "$line\n";
                exit $ERRORS{'CRITICAL'};
            }
        }
        my $lineref = retrieve($st_mysql_stat) if -f $st_mysql_stat;

        print "ok,$$lineref\n" if defined $$lineref;

        my $line = "";

        store \$line, $st_mysql_stat;

        exit $ERRORS{'OK'};

    } elsif (lc($service) eq 'memcached') {
        open my $memcached, "< $st_memcached_log" or die "cannot open $st_memcached_log: $!";

        while (my $line = <$memcached>) {
            chomp $line;
            if ( defined $line && $line ne "") {
                store \$line, $st_memcached_stat;
                print "$line\n";
                exit $ERRORS{'CRITICAL'};
            }
        }

        my $lineref = retrieve($st_memcached_stat) if -f $st_memcached_stat;

        print "ok,$$lineref\n" if defined $$lineref;

        my $line = "";

        store \$line, $st_memcached_stat;

        exit $ERRORS{'OK'};
    }
    print "undef\n";
    exit $ERRORS{'OK'};
}


sub check_client_nginx_pic {
    my $timeout_count;
    my $time;
    my $last_mtime;
    my $fd;

    eval {
        open $fd, "</tmp/client_nginx_pic" or croak "open /tmp/client_nginx_pic error: $!\n";
        $last_mtime = (stat($fd))[9];
        $time = time;
    };

    print "$@\n" if $@;
    exit $ERRORS{'OK'} if $@;

    while (my $line = <$fd>) {
        chomp $line;
        $timeout_count = $line;
    }

    if (defined $timeout_count && $timeout_count =~ m/^\d+$/xms && $timeout_count > 9 && ($time - $last_mtime) <= 600) {
        if ($timeout_count < 50) {
            print "error, timeout $timeout_count times in 5m|timeout=$timeout_count\n";
            exit $ERRORS{'WARNING'};
        }
        else {
            print "error, timeout $timeout_count times in 5m|timeout=$timeout_count\n";
            exit $ERRORS{'CRITICAL'};
        }
    }
    else {
        print "ok, $timeout_count\n";
        exit $ERRORS{'OK'};
    };

    print "undef\n";
    exit $ERRORS{'OK'};
}

sub check_client_resin_pic {
    my $timeout_count;
    my $time;
    my $last_mtime;
    my $fd;

    eval {
        open $fd, "</tmp/client_resin_pic" or croak "open /tmp/client_resin_pic error: $!\n";
        $last_mtime = (stat($fd))[9];
        $time = time;
    };

    print "$@\n" if $@;
    exit $ERRORS{'OK'} if $@;

    while (my $line = <$fd>) {
        chomp $line;
        $timeout_count = $line;
    }

    if (defined $timeout_count && $timeout_count =~ m/^\d+$/xms && $timeout_count > 9 && ($time - $last_mtime) <= 600) {
        if ($timeout_count < 50) {
            print "error, timeout $timeout_count times in 5m|timeout=$timeout_count\n";
            exit $ERRORS{'WARNING'};
        }
        else {
            print "error, timeout $timeout_count times in 5m|timeout=$timeout_count\n";
            exit $ERRORS{'CRITICAL'};
        }
    }
    else {
        print "ok, $timeout_count\n";
        exit $ERRORS{'OK'};
    };

    print "undef\n";
    exit $ERRORS{'OK'};
}


sub check_dc_jobkeeper {
    my $timeout_count;
    my $time;
    my $last_mtime;
    my $fd;

    my $status_file = "/tmp/dc_jobkeeper";

    eval {
        open $fd, $status_file or croak "open $status_file error: $!\n";
        $last_mtime = (stat($fd))[9];
        $time = time;
    };

    print "$@\n" if $@;
    exit $ERRORS{'OK'} if $@;

    while (my $line = <$fd>) {
        chomp $line;
        $timeout_count = $line;
    }

    if (defined $timeout_count && $timeout_count =~ m/^\d+$/xms && $timeout_count > 0 && ($time - $last_mtime) <= 600) {
        print "error, timeout $timeout_count times in 5m|timeout=$timeout_count\n";
        exit $ERRORS{'CRITICAL'};
    }
    else {
        print "ok, $timeout_count|timeout=$timeout_count\n";
        exit $ERRORS{'OK'};
    };

    print "undef\n";
    exit $ERRORS{'OK'};
}

sub check_regist_ip {
    my $ret = qx#tail -n 200000 \/opt\/nginx\/logs\/access.log | grep Regist | grep -v downloadRegistrationInfo |  grep -v " 403 " | awk '{print \$1}' | sort | uniq -c | sort -n | tail -n 1#;

    $ret =~ s/^\s+//xms;
    my ($count, $ip) = split (/\s+/, $ret);
    #my $ip_forwarded = substr $ip_forwarded_with_quotes, 1, length($ip_forwarded_with_quotes) - 2;

    if (defined $count && $count > 9 && is_ip_or_hostname($ip)) {
        if (is_ip_or_hostname($ip)) {
            if (exists $ignore_ips{$ip}) {
                print "ok, \n";
                exit $ERRORS{'OK'};
            }
            elsif ($ip =~ m/^(10\.|192\.168\.)/xms) {
                print "ok, \n";
                exit $ERRORS{'OK'};
            }
            else {
                if ($count < 20) {
                    print "warning, $ip Regist too much($count)\n";
                    exit $ERRORS{'WARNING'};
                }
                else {
                    print "error, $ip Regist too much($count)\n";
                    exit $ERRORS{'CRITICAL'};
                }
            }
        }
    }
    else {
        print "ok, \n";
        exit $ERRORS{'OK'};
    }

    print "undef\n";
    exit $ERRORS{'OK'};
}


sub check_topip {
    #use Data::Dumper qw(Dumper);
    #print Dumper %ignore_ips;

    my $topip_db = "/opt/work/topip.db";

    use Storable qw(store retrieve);

    my $topip_ref;
    eval {
        $topip_ref = retrieve($topip_db);
    };

    $topip_ref = {} if $@;

    my $ret = qx#tail -n 200000 /opt/nginx/logs/access.log | grep -v " 403 " | awk '{print \$1, \$(NF-1)}' | sort | uniq -c | sort -n | tail -n 5#;
    my @lines = split (/\n/, $ret);

    my ($suspicious_ip, $suspicious_ip_count) = qw(0 0);
    for my $line (@lines) {
        $line =~ s/^\s+//xms;
        my ($count, $ip, $ip_forwarded_with_quotes) = split (/\s+/, $line);

        next if exists $ignore_ips{$ip};

        my $ip_forwarded = substr $ip_forwarded_with_quotes, 1, length($ip_forwarded_with_quotes) - 2;
        if ($ip =~ m/^10\.|192\.168\./xms) {
            $ip = $ip_forwarded if is_ip_or_hostname($ip_forwarded);
        }
        unless (exists $topip_ref->{$ip}) {
            $suspicious_ip = $ip;
            $suspicious_ip_count = $count;
        }
        # comment two lines below after a few days. try to collect normal topips.
        $topip_ref->{$ip} = $count;
        store $topip_ref, $topip_db;
    }

    if (defined $suspicious_ip_count && $suspicious_ip_count > 99) {
        if (is_ip_or_hostname($suspicious_ip)) {
            if (exists $ignore_ips{$suspicious_ip}) {
                print "ok, \n";
                exit $ERRORS{'OK'};
            }
            elsif ($suspicious_ip =~ m/^(10\.|192\.168\.)/xms) {
                print "ok, \n";
                exit $ERRORS{'OK'};
            }
            else {
                if ($suspicious_ip_count < 200) {
                    print "warning, $suspicious_ip($suspicious_ip_count)\n";
                    #exit $ERRORS{'WARNING'};
                    exit $ERRORS{'OK'};
                }
                else {
                    print "error, $suspicious_ip($suspicious_ip_count)\n";
                    #exit $ERRORS{'CRITICAL'};
                    exit $ERRORS{'OK'};
                }
            }
        }
    }
    else {
        print "ok, \n";
        exit $ERRORS{'OK'};
    }

    print "undef\n";
    exit $ERRORS{'OK'};
}

#!/usr/bin/env perl

#===============================================================================
# fengxiahou@sohu-inc.com (whymaths@gmail.com)
#===============================================================================

use strict;
use warnings;
use utf8;
use diagnostics;
#use Modern::Perl;
use Carp qw(croak carp confess);
#use 5.010000;
#use autodie;

#use Smart::Comments;

use lib "/usr/local/nagios/libexec" ;
use utils qw (%ERRORS &print_revision &support);


use Getopt::Long;

#use Smart::Comments;

my @cared_memcached_stats = (
    'curr_connections',
    'get_hits',
    'cmd_get',
);

my %cared_memcached_stats = map { $_ => 1} @cared_memcached_stats;

my @ignore_memcached_servers = (
);

my %ignore_memcached_servers = map { $_ => 1 } @ignore_memcached_servers;


my %special_memcached_servers = (
);

my (
    $g_server,
    $g_host,
    $g_port,
    $g_warn,
    $g_critical,
    $more,
    $usage,
);


GetOptions (
    's|servers=s'   => \$g_server,
    'p|port=i'      => \$g_port,
    'w|warn=i' => \$g_warn,
    'c|critical=i' => \$g_critical,
    'm|more'    => \$more,
    'h|help'    => \$usage,
);

$g_warn ||= 800;
$g_critical ||= 900;
$g_port ||= 11211;

$g_host = shift @ARGV;

usage() if $usage;

if (defined $g_server && $g_server) {
    if ($g_server =~ m/:/xms) {
        my @tmp = split (/:/, $g_server);
        if ($#tmp) {
            $g_host = $tmp[0] if is_ip_or_hostname($tmp[0]);
            $g_port = $tmp[1] if (defined $tmp[1] && $tmp[1] =~ m/^\d+$/xms);
            $g_warn = $tmp[2] if (defined $tmp[2] && $tmp[2] =~ m/^\d+$/xms);
            $g_critical = $tmp[3] if (defined $tmp[3] && $tmp[3] =~ m/^\d+$/xms);
        }
    }
}

usage() unless (defined $g_host && is_ip_or_hostname($g_host)
                    && defined $g_port && $g_port =~ m/^\d+$/xms
                    && defined $g_warn && $g_warn =~ m/^\d+$/xms
                    && defined $g_critical && $g_critical =~ m/^\d+$/xms
);

use IO::Socket::INET;

my $sock;

eval {
    $sock = IO::Socket::INET->new(
        PeerAddr => $g_host,
        PeerPort => $g_port,
        Proto => 'tcp',
        Timeout => 1,
    ) or die "connection refused: $!\n";
};

print $@ if $@;
exit $ERRORS{'CRITICAL'} if $@;

$sock->autoflush(1);

print $sock "stats\n";

my @memcached_infos;

until ($sock->eof()) {
    if (defined(my $line = $sock->getline())) {
        chomp $line;
        last if $line =~ m/^END\r$/xms;
        push @memcached_infos, $line;
    }
}

print $sock "quit\n";
$sock->close;

# @memcached_infos

my $server = "$g_host:$g_port";

my %cared_memcached_infos;

for my $line (@memcached_infos) {
    if ($line =~ m/STAT\ (\S+)\ (\d+)\r$/gmx) {
        # $line
        my $item_msg = $1;
        my $item_value = $2;
        #save_to_redis("$item_msg\:$server", $item_value);
        print "$item_msg($item_value)\n" if $more;
        next if exists $ignore_memcached_servers{"$server\:$item_msg"};
        next unless exists $cared_memcached_stats{$item_msg};

        $cared_memcached_infos{$item_msg} = $item_value;
    }
}

my $cache_hits;

if (exists $cared_memcached_infos{'get_hits'}
        && $cared_memcached_infos{'get_hits'}
        && exists $cared_memcached_infos{'cmd_get'}
        && $cared_memcached_infos{'cmd_get'}) {

            $cache_hits = $cared_memcached_infos{'get_hits'} / $cared_memcached_infos{'cmd_get'};
            $cache_hits = sprintf("%.04s", $cache_hits);
}
else {
    exit $ERRORS{'UNKNOWN'};
}


my $status_msg = $cared_memcached_infos{'curr_connections'}
                    . "),cache_hits($cache_hits)"
                    . "|curr_conn=" . $cared_memcached_infos{'curr_connections'} . ";$g_warn;$g_critical;0"
                    . " cache_hits=" . $cache_hits . ";0.40;0.50;0"
                    . "\n";

if (exists $cared_memcached_infos{'curr_connections'}) {
    my $server_item = "$server:curr_connections";
    if (exists $special_memcached_servers{$server_item}) {
        if ($cared_memcached_infos{'curr_connections'} > $special_memcached_servers{$server_item}) {
            print "error, curr_conn(" . $status_msg;
            exit $ERRORS{'CRITICAL'};
        }
        else {
            print "ok, curr_conn(" . $status_msg;
            exit $ERRORS{'CRITICAL'};
        }
    }
    else {
        if ($cared_memcached_infos{'curr_connections'} > $g_critical) {
            print "error, curr_conn(" . $status_msg;
            exit $ERRORS{'CRITICAL'};
        }
        elsif ($cared_memcached_infos{'curr_connections'} > $g_warn) {
            print "warning, curr_conn(" . $status_msg;
            exit $ERRORS{'CRITICAL'};
        }
        else {
            print "ok, curr_conn(" . $status_msg;
            exit $ERRORS{'CRITICAL'};
        }
    }
}

print "ok, curr_conn(" . $status_msg;

exit $ERRORS{'OK'};


sub usage {

    print qq{
Usage:
$0 [host] -p 11211 -w 800 -c 900     # for nagios
$0 -s 10.11.149.29:11111:800:900   # for test

p|port t|test
s|servers server lists
h|help  print this help

};

    exit 1;

}


sub save_to_redis {
    my $key = shift @_;
    my $value = shift @_;

    eval {
        use Redis;
        my $redis = Redis->new(server => '127.0.0.1:6379', reconnect => 60) or die;

        $redis->hset('memcached', $key, $value);
    };

    print $@, "\n" if $@;
}


sub is_ip_or_hostname {
    my $str = shift;
    return 0 unless defined $str;
    if ($str =~ m/^[\d\.]+$/ && $str !~ /\.$/) {
        if ($str =~ m/^[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+$/) {
            return 1;
        } else {
            return 0;
        }
    } elsif ($str =~
            m/^[a-zA-Z0-9][-a-zA-Z0-9]*(\.[a-zA-Z0-9][-a-zA-Z0-9]*)+$/) {
        return 1;
    } else {
        return 0;
    }
}

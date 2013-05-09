#!/usr/bin/env perl

#===============================================================================
# fengxiahou@sohu-inc.com (whymaths@gmail.com)
#
# echo delete UserInfo_Receive_0 | nc 10.11.65.19 11213
# /opt/memcached/bin/memcached -u memcache -d -m 2048 -l 0.0.0.0 -p 11211 -U 11211 -P /tmp/memcached_11211.pid
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

use Smart::Comments;

my $saved_status_file = "/opt/work/saved_status";

use Tie::File;

tie my @saved_status_array, "Tie::File", $saved_status_file or die "tie $saved_status_file: $!\n";

my @cared_memcached_stats = (
    'curr_connections',
    'total_connections',
    'get_hits',
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
    $g_unused,
    $more,
    $usage,

    $blocked_servers,
);


GetOptions (
    's|servers=s'   => \$g_server,
    'p|port=i'      => \$g_port,
    't|test=i' => \$g_unused,
    'm|more'    => \$more,
    'h|help'    => \$usage,
);

$g_unused ||= 10000;
$g_port ||= 11211;

$g_host = shift @ARGV;

usage() if $usage;

if (defined $g_server && $g_server) {
    if ($g_server =~ m/:/xms) {
        my @tmp = split (/:/, $g_server);
        if ($#tmp) {
            $g_host = $tmp[0] if is_ip($tmp[0]);
            $g_port = $tmp[1] if (defined $tmp[1] && $tmp[1] =~ m/^\d+$/xms);
            $g_unused = $tmp[2] if (defined $tmp[2] && $tmp[2] =~ m/^\d+$/xms);
        }
    }
}


usage() unless (defined $g_host && is_ip($g_host)
                && defined $g_port && $g_port =~ m/^\d+$/xms
                && defined $g_unused && $g_unused =~ m/^\d+$/xms);


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

exit $ERRORS{'CRITICAL'} if $@;
print $@ if $@;

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


my $server = "$g_host:$g_port";

# @memcached_infos

my $memcached_status = "";

for my $line (@memcached_infos) {
    if ($line =~ m/STAT\ (\S+)\ (\d+)\r$/gmx) {
        #print "$line\n";
        my $item_msg = $1;
        my $item_value = $2;
        #save_to_redis("$item_msg\:$server", $item_value);
        #save_to_status_file("$item_msg\:$server", $item_value);
        print "$item_msg($item_value)\n" if $more;
        next if exists $ignore_memcached_servers{"$server\:$item_msg"};

        my $server_item = "$server:$item_msg";
        if (exists $special_memcached_servers{$server_item}) {
            if ($item_value >= $special_memcached_servers{$server_item}) {
                #
            }
        }
        elsif ($item_value >= $g_unused) {
            #
        }
        else {
            #
        }
        $memcached_status .= "$item_msg:$item_value " if exists $cared_memcached_stats{"$item_msg"};
    }
}

untie @saved_status_array;

exit $ERRORS{'CRITICAL'} if $blocked_servers;

print "memcached ok!|$memcached_status\n" unless $blocked_servers;
exit $ERRORS{'OK'} unless $blocked_servers;



sub usage {

#define command{
#        command_name    check_memcached_pl
#        command_line    $USER1$/check_memcached.pl $HOSTADDRESS$ -p $ARG1$ -t $ARG2$
#}

    print qq{
Usage:
$0 [host] -p 11211 -t 1000     # for nagios
$0 -s 10.11.123.23:11211:1000   # for test

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


sub save_to_status_file {
    my $key = shift @_;
    my $value = shift @_;

    my $key_met = 0;
    my $array_length = $#saved_status_array;
    for my $line (0..$array_length) {
        if ($saved_status_array[$line] =~ m/$key\:\ (\d+)/xms) {
            $saved_status_array[$line] = "$key: $value\n";
            $key_met = 1;
        }
    }

    push @saved_status_array, "$key: $value\n" unless $key_met;
}


sub is_ip {
    my $host1 = shift;
    return 0 unless defined $host1;
    if ($host1 =~ m/^[\d\.]+$/ && $host1 !~ /\.$/) {
        if ($host1 =~ m/^[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+$/) {
            return 1;
        } else {
            return 0;
        }
    } elsif ($host1 =~ m/^[a-zA-Z0-9][-a-zA-Z0-9]*(\.[a-zA-Z0-9][-a-zA-Z0-9]*)*\.?$/) {
        return 1;
    } else {
        return 0;
    }
}

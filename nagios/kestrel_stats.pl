#!/usr/bin/env perl

use strict;
use warnings;

use lib "/usr/local/nagios/libexec" ;
use utils qw (%ERRORS &print_revision &support);

use Getopt::Long;

#use Smart::Comments;

use List::MoreUtils qw(any);

my $saved_status_file = "/opt/work/saved_status";

use Tie::File;

tie my @saved_status_array, "Tie::File", $saved_status_file or die "tie $saved_status_file: $!\n";

my @ignore_queues = (
    '10.11.152.39:22133:timeline_prepare_pull',
    #'10.11.152.76:22133:external_info',
    #'10.11.152.43:22201:timeline',
);

my %ignore_queues = map { $_ => 1 } @ignore_queues;


# special needs
my %special_queues = (
    '10.11.152.43:22201:timeline' =>        => 100,
    '10.11.152.39:22133:timeline_msg_insert' => 200,
    '10.11.152.39:22133:timeline_msg_del' => 200,
    '10.11.152.39:22133:timeline_follow_insert' => 500,
    '10.11.152.39:22133:timeline_follow_del' => 200,
    '10.11.152.105:22133:sohutw_online_uids_segment' => 200,
    '10.11.152.105:22133:big_comet_msg' => 200,
);

my (
    $g_server,
    $g_host,
    $g_port,
    $g_threshold,
    $more,
    $usage,
);


GetOptions (
    's|servers=s'   => \$g_server,
    'p|port=i'      => \$g_port,
    't|threshold=i' => \$g_threshold,
    'm|more'    => \$more,
    'h|help'    => \$usage,
);

$g_threshold ||= 10000;
$g_port ||= 22133;

$g_host = shift @ARGV;

usage() if $usage;

if (defined $g_server && $g_server) {
    if ($g_server =~ m/:/xms) {
        my @tmp = split (/:/, $g_server);
        if ($#tmp) {
            $g_host = $tmp[0] if is_ip($tmp[0]);
            $g_port = $tmp[1] if (defined $tmp[1] && $tmp[1] =~ m/^\d+$/xms);
            $g_threshold = $tmp[2] if (defined $tmp[2] && $tmp[2] =~ m/^\d+$/xms);
        }
    }
}

usage() unless (defined $g_host && is_ip($g_host)
                && defined $g_port && $g_port =~ m/^\d+$/xms
                && defined $g_threshold && $g_threshold =~ m/^\d+$/xms);



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

my @queues_infos;

until ($sock->eof()) {
    if (defined(my $line = $sock->getline())) {
        chomp $line;
        last if $line =~ m/^END\r$/xms;
        push @queues_infos, $line;
    }
}

print $sock "quit\n";
$sock->close;


my $blocked_servers = 0;
my $block_msg = "";
my $server = "$g_host:$g_port";

for my $line (@queues_infos) {
    if ($line =~ m/queue_(.*)_mem_items\ (\d+)\r$/gmx) {
        #print "$line\n";
        my $item_msg = $1;
        my $item_value = $2;
        save_to_redis("$item_msg\@$server", $item_value);
        #save_to_status_file("$item_msg\@$server", $item_value);
        print "$item_msg($item_value)\n" if $more;
        #next if any { $_ eq "$server\:$item_msg" } @ignore_queues;
        next if exists $ignore_queues{"$server\:$item_msg"};
        my $server_item = "$server:$item_msg";
        if (exists $special_queues{$server_item}) {
            if ($item_value >= $special_queues{$server_item}) {
                $block_msg .= "$item_msg($item_value) ";
            }
        }
        elsif ($item_value >= $g_threshold) {
            $block_msg .= "$item_msg($item_value) ";
        }
    }
}

print "$block_msg\n" unless $block_msg eq "";
$blocked_servers++ unless $block_msg eq "";



untie @saved_status_array;

exit $ERRORS{'CRITICAL'} if $blocked_servers;

print "kestrel ok!\n" unless $blocked_servers;
exit $ERRORS{'OK'} unless $blocked_servers;




sub usage {
    my $usage_msg =  <<"EOF";
$0 [host] -p 22133 -t 10000     # for nagios
$0 -s 10.11.123.23:22133:1000   # for test

p|port t|threshold
s|servers server lists
h|help  print this help

EOF
    
    print $usage_msg;
    exit 3;
}

sub save_to_redis {
    my $key = shift @_;
    my $value = shift @_;

    eval {
        use Redis;
        my $redis = Redis->new(server => '127.0.0.1:6379', reconnect => 60) or die;
        
        $redis->hset('kestrel', $key, $value);
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

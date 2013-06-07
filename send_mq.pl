#!/usr/bin/env perl
#-----------------------------
#
# fengxiahou@sohu-inc.com
#
#-----------------------------

use strict;
use warnings;
use utf8;
#use diagnostics;

use Modern::Perl;
use Smart::Comments;
use local::lib "/home/hume/perl5/";

use Carp qw(croak carp confess);

my $host = get_ip_address("eth0");
### $host
my $function = shift @ARGV;
### $function

usage() unless ($host && $function);

# $host:$function
# $hostgroup:$function
# $service:$function
# $servicegroup:$function

my $queue = "$host:$function";

use Cache::Memcached::Fast;

my $memd = new Cache::Memcached::Fast({
        servers => [
            { address => "10.16.11.27:22133", weight => 2.5 },
            { address => "10.16.11.28:22133", weight => 2.5 },
            { address => "10.16.12.29:22133", weight => 2.5 },
        ],
        namespace => "nagios:",
        connect_timeout => 0.2,
        io_timeout => 0.5,
        close_on_error => 1,
        max_failures => 3,
        failure_timeout => 1,
        nowait => 1,
        hash_namespace => 1,
        serialize_methods => [ \&Storable::freeze, \&Storable::thaw ],
        utf8 => 1,
        max_size => 512 * 1024,
        ketama_points => 100,
});

my ($status_code, $status_msg) = try_do_job();
my $time = time;

### $status_code
### $status_msg

my $rt = $memd->set($queue, "$time:$status_code:$status_msg")
    if (defined $status_code && defined $status_msg && $status_msg);

### $rt

sub usage {
    print << "USAGE";
Usage: $0 \$function\$
USAGE
    exit (1);
}

sub get_ip_address {
    my $device = shift;

    open my $device_info, "/sbin/ifconfig $device |" or die "$!\n";

    while (<$device_info>) {
        if ($_ =~ m/(\d+\.\d+\.\d+\.\d+)/xms) {
            return $1;
        }
    };
    return;
};


sub try_do_job {
    return (1, "ok");
}

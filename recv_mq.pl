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

my $locks_dir = "/usr/local/nagios/var/locks";

print "directory /usr/local/nagios/var/locks don't exists\n" and exit(1)
    unless (-e $locks_dir && -d $locks_dir);

my $host = shift @ARGV;
my $function = shift @ARGV;

usage() unless ($host && $function);

# $host:$function
# $hostgroup:$function
# $service:$function
# $servicegroup:$function

my $queue = "$host:$function";
my $queue_lock = "$locks_dir/$queue.lock";

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

my $item = $memd->get($queue);

### $item

if ($item) {
    if (-e $queue_lock && -f $queue_lock) {
        unlink $queue_lock;
    }
} else {
    if (-e $queue_lock && -f $queue_lock) {
        print "$queue is empty";
        exit(2);
    } else {
        use POSIX qw(creat close);
        my $fd = creat("$queue_lock", 0644);
        close($fd);
    }
}


sub usage {
    print << "USAGE";
Usage: $0 \$IPADDRESS\$ \$function\$
USAGE
    exit (1);
}

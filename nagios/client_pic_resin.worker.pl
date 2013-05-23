#!/usr/bin/env perl

use strict;
use warnings;

use POSIX qw(strftime getpid fork setsid);
use Carp qw(croak confess);

use Fcntl ':flock';

my $log_file = "/opt/work/worker.log";

#use Modern::Perl;
use JSON::PP;

use Getopt::Long;

$SIG{INT} = sub {
    #unlink $log_file;
    exit 1;
};

my (
    $daemonize,
);

GetOptions(
    "d|daemonize"    => \$daemonize,
);

daemonize() if $daemonize;

my $function;

if ($0 =~ m/(\w+)\.worker\.pl/xms) {
    $function = $1;
}

use Gearman::Worker;

my $worker = Gearman::Worker->new;
$worker->job_servers('10.11.6.204:4730', "10.11.6.205:4730", "192.168.1.59:4730");

open my $ip_fd, "</opt/work/me.ip" or die "open ip file error: $!";
chomp (my $ip = <$ip_fd>);

my $time = currenttime();
$worker->register_function($function => sub {
        open my $log, ">>$log_file" or die "open ip file error: $!";

        flock($log, LOCK_EX) or die "Could not lock '$log' - $!";

        my $search_string = $_[0]->arg;
        my $hash_ref = decode_json($search_string);
        print $log currenttime() , "\@$0: ", $hash_ref->{"ctime"}, "\n";

        close $log or confess "Could not close file $!";;
    }
);

$worker->work while 1;

sub currenttime {
    my @now_time = localtime(time);

    my $year = $now_time[5] + 1900;
    my $month = sprintf("%02d", $now_time[4] + 1);
    my $day = sprintf("%02d", $now_time[3]);

    my $hour = sprintf("%02d", $now_time[2]);
    my $minute = sprintf("%02d", $now_time[1]);
    my $second = sprintf("%02d", $now_time[0]);

    my $now_time = "$year/$month/$day\_$hour:$minute:$second";

    return $now_time;
}


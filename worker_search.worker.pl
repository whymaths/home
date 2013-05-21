#!/usr/bin/env perl

use strict;
use warnings;

use Gearman::Worker;

use POSIX qw(strftime getpid fork setsid);
use Carp qw(croak confess);

use Fcntl ':flock';

my $log_file = "/opt/work/worker.log";

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

open my $ip_fd, "</opt/work/worker/me.ip" or die "open ip file error: $!";

my $ip;

while(<$ip_fd>) {
    $ip = $_;
    chomp $ip;
}

my $worker = Gearman::Worker->new;
$worker->job_servers('10.11.6.204:4730', "10.11.6.205:4730", "192.168.1.59:4730");

$worker->register_function( worker_search => sub {
        open my $log, ">>$log_file" or die "open ip file error: $!";

        flock($log, LOCK_EX) or die "Could not lock '$log' - $!";

        my $search_string = $_[0]->arg;
        print $log currenttime() , "\@$0: $search_string\n";

        close $log or confess "Could not close file $!";;
    }
);


$worker->work while 1;

sub daemonize {
    my ($pid, $sess_id, $i);

    ## Fork and exit parent
    if ($pid = fork) { exit 0; }

    ## Detach ourselves from the terminal
    croak "Cannot detach from controlling terminal"
        unless $sess_id = POSIX::setsid();

    ## Prevent possibility of acquiring a controling terminal
    $SIG{'HUP'} = 'IGNORE';
    if ($pid = fork) { exit 0; }

    ## Change working directory
    chdir "/";

    ## Clear file creation mask
    umask 0;

    ## Close open file descriptors
    close(STDIN);
    close(STDOUT);
    close(STDERR);

    ## Reopen stderr, stdout, stdin to /dev/null
    open(STDIN,  "+>/dev/null");
    open(STDOUT, "+>&STDIN");
    open(STDERR, "+>&STDIN");
}

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

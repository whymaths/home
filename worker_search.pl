#!/usr/bin/env perl

use strict;
use warnings;

use Gearman::Client;

use Parallel::ForkManager;

my $MAX_PROCESSES = 10000;

my $pm = Parallel::ForkManager->new($MAX_PROCESSES);

$pm->run_on_finish( sub {
    my ($pid, $exit_code, $ident, $exit_signal, $core_dump, $data_structure_reference) = @_;
    print "$ident just got out of the pool ".
        "with exit code: $exit_code and data: @$data_structure_reference\n";
});

$pm->run_on_start( sub {
    my ($pid,$ident)=@_;
    print "$ident started\n";
});

$pm->run_on_wait(
    sub {
        print "** Have to wait for one children ...\n"
    },
    0.5,
);

#######################################
#use FindBin;
#
#my $dir = $FindBin::Bin;
#
#use File::Basename;
#
#my $bin = basename($0, ".pl");
#
#my $dfs_saved = "$dir/$bin.save";
#######################################

my $client = Gearman::Client->new;
$client->job_servers('10.11.6.204:4730', "10.11.6.205:4730", "192.168.1.59:4730");

open my $ip_fd, "</opt/work/me.ip" or die "open ip file error: $!";
chomp (my $ip = <$ip_fd>);

for my $wd (1..1000000) {
    my $pid;

    $pid  = $pm->start($wd) and next;

    my $time = time;
    $time .= "_$wd: $pid";
    my $task = Gearman::Task->new('worker_search' , \$time, {
            uniq => '-',
            #on_complete => sub { print "df success\n"; },
            #on_fail => sub { print "df failed\n"; },
            timeout => 2,
        }
    );
    
    my $resultref = $client->dispatch_background($task);
    
    my $is_dfs_finished = $task->is_finished();

    $pm->finish(1);
};

#print "Waiting for Children...\n";
$pm->wait_all_children;
print "Everybody is out of the pool!\n";


sub currenttime {
    my @now_time = localtime(time);

    my $year = $now_time[5] + 1900;
    my $month = $now_time[4] + 1;
    my $day = $now_time[3];

    my $now_time = "$year" . "_" . "$month"."_"."$day"."_"
        ."$now_time[2]" . "_" . "$now_time[1]"."_"."$now_time[0]";

    return $now_time;
}

#!/usr/bin/env perl

use strict;
use warnings;

use Modern::Perl;

use JSON::PP;

my $function;

if ($0 =~ m/(\w+)\.pl/xms) {
    $function = $1;
}

use Gearman::Client;

my $client = Gearman::Client->new;
$client->job_servers('10.11.6.204:4730', "10.11.6.205:4730", "192.168.1.59:4730");

open my $ip_fd, "</opt/work/me.ip" or die "open ip file error: $!";
chomp (my $ip = <$ip_fd>);

my $time = currenttime();

my $json_text = encode_json({ ctime => $time });
my $task = Gearman::Task->new($function ,\$json_text, {
        uniq => '-',
        #on_complete => sub { print "work success\n"; },
        #on_fail => sub { print "work failed\n"; },
        timeout => 2,
    }
);

my $resultref = $client->do_task($task);
#my $resultref = $client->dispatch_background($task);

my $is_function_finished = $task->is_finished();

say "$function done." if $is_function_finished;

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


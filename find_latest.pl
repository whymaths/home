#!/usr/bin/env perl
#-----------------------------
#
# fengxiahou@sohu-inc.com
#
#-----------------------------

use strict;
use warnings;
use utf8;
use diagnostics;
use Modern::Perl;
use Carp qw(croak carp confess);
#use 5.010000;
#use autodie;

use Smart::Comments;

my $dir = shift @ARGV;

$dir = substr $dir, 0, length($dir) - 1
    if index $dir, '/';

map {
    my $currenttime = currenttime();
    `mkdir -p $dir/$currenttime`;
    sleep 1;
} 1..5;

usage() unless defined $dir && -e $dir;

find_latest($dir);

sub find_latest {
    my $dir = shift;

    my @sub_dirs;

    my $contents = `ls $dir`;

    my @contents = split /\n/, $contents;

    for my $line (@contents) {
        push @sub_dirs, "$line" if -d "$dir/$line";
    }

    my $latest = 0;
    my $latest_str = 0;
    for my $line (@sub_dirs) {
        next unless $line =~ m/\d{4}_\d{2}_\d{2}_\d{2}_\d{2}_\d{2}/xms;
        my $line_str = $line;
        $line =~ s/_//gxms;
        if ($line > $latest) {
            $latest = $line;
            $latest_str = $line_str;
        }
    }
    say "$dir/$latest_str";
}

sub currenttime {
    my @now_time = localtime(time);

    my $year = $now_time[5] + 1900;
    my $month = sprintf("%02d", $now_time[4] + 1);
    my $day = sprintf("%02d", $now_time[3]);

    my $hour = sprintf("%02d", $now_time[2]);
    my $minute = sprintf("%02d", $now_time[1]);
    my $second = sprintf("%02d", $now_time[0]);

    my $now_time = "$year\_$month\_$day\_$hour\_$minute\_$second";

    return $now_time;
}


sub usage {
    print <<"EOL";
$0 directory_name
EOL

}

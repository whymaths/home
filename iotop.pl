#!/usr/bin/env perl
use strict;
use warnings;
use diagnostics;
use Carp qw(croak confess carp);
use File::Glob ':glob';

my %io_stat;
my %io_stat_last;

print "=======================================\n";

my $g_count = 0;

while (1) {
    my $top_io_read_bytes = 0;
    my $top_io_read_pid = 1;
    my $top_io_read_user;
    my $top_io_read_cmd = '';

    my $top_io_write_bytes = 0;
    my $top_io_write_pid = 1;
    my $top_io_write_user;
    my $top_io_write_cmd = '';

    %io_stat = ();

    my @list = bsd_glob('/proc/*/io');

    map {
        iostat($_);
    } @list;

    $g_count++;
    next unless $g_count > 1;

    eval {
        map {
            my $pid = $_;
            # $pid
            my $read_bytes = $io_stat{$pid}{'read_bytes'};
            my $write_bytes = $io_stat{$pid}{'write_bytes'};
    
            $top_io_read_pid = $pid
                if ($top_io_read_bytes < $read_bytes);
            $top_io_read_bytes = $read_bytes
                if ($top_io_read_bytes < $read_bytes);
    
            $top_io_write_pid = $pid
                if ($top_io_write_bytes < $write_bytes);
            $top_io_write_bytes = $write_bytes
                if ($top_io_write_bytes < $write_bytes);
    
        } sort {$a cmp $b} keys %io_stat;

        my @sb = stat("/proc/$top_io_read_pid/");
        my $uid = $sb[4];

        $top_io_read_user = getpwuid($uid) if defined $uid;
        $top_io_read_user ||= 'died';

        my $cmd;
    
        open $cmd, "</proc/$top_io_read_pid/status"
            or croak "open /proc/$top_io_read_pid/status error: $!\n";
        if (<$cmd> =~ m/^Name:\s+(\w+)\n/xms) {
            $top_io_read_cmd = $1;
        };
        close $cmd if $cmd;

        @sb = stat("/proc/$top_io_write_pid/");
        $uid = $sb[4];
        $top_io_write_user = getpwuid($uid) if defined $uid;


        $top_io_write_user ||= 'died';
    
        open $cmd, "</proc/$top_io_write_pid/status"
            or croak "open /proc/$top_io_write_pid/status error: $!\n";

        if (<$cmd> =~ m/^Name:\s+(\w+)\n/xms) {
            $top_io_write_cmd = $1;
        };
        close $cmd if $cmd;
    };

    $top_io_read_cmd = 'died'
        if ($top_io_read_cmd =~ m/^\s*$/xms);
    $top_io_write_cmd  = 'died'
        if ($top_io_write_cmd =~ m/^\s*$/xms);

    print "read\n";
    print "    user: $top_io_read_user\n    pid: $top_io_read_pid\n    read bytes: " . $top_io_read_bytes/1024 . " kb/s\n"
            if $top_io_read_bytes;
    print "    cmd: $top_io_read_cmd\n"
            if ($top_io_read_cmd && $top_io_read_bytes);

    print "write\n";
    print "    user: $top_io_write_user\n    pid: $top_io_write_pid\n    write bytes: " . $top_io_write_bytes/1024 . " kb/s\n"
            if $top_io_write_bytes;
    print "    cmd: $top_io_write_cmd\n"
            if ($top_io_write_cmd && $top_io_write_bytes);

    print "=======================================\n";
    sleep 1;
}

sub iostat {
    my $fullpath = shift;
    return 0 unless ($fullpath =~ m/^\/proc\/(\d+)\/io$/xms);
    # $fullpath
    if ($fullpath =~ m/^\/proc\/(\d+)\/io$/xms) {
        my $pid = $1;

        # $pid
        eval {
            open my $io, "<$fullpath" or croak "\n";
            while (my $line = <$io>) {
                next unless (defined $line && $line);
                chomp($line);
                if ($line =~ m/(\w+):\ (\d+)/xms) {
                    $io_stat_last{$pid}{$1} ||= 0;
                    $io_stat{$pid}{$1} = $2 - $io_stat_last{$pid}{$1};
                    $io_stat_last{$pid}{$1} = $2;
                }
            }
        };

        #print $@ if $@;

        return 1;
    }
    return 0;
}

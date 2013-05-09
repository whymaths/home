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
#use Modern::Perl;
use Carp qw(croak carp confess);
#use 5.010000;
#use autodie;

#use Smart::Comments;

use Tie::File;

my $MAX_LENGTH = 1024*1024;

my $saved_status_file = "/opt/work/saved_status";
my $error_log_file = "/opt/log/picerr.log";
my $saved_file = "/tmp/client_resin_pic";

open my $error_log_fd, "<$error_log_file" or die "open $error_log_file: $!\n";

my $error_log_file_offset_last_check = 0;
my $error_log_file_inode_changed = 0;
my $error_log_file_inode_last_check;


tie my @saved_status_array, "Tie::File", $saved_status_file or die "tie $saved_status_file: $!\n";


my @stat = stat($error_log_fd);
my $error_log_file_inode = $stat[1];
my $error_log_file_size = $stat[7];


# exists in $saved_status_file?
my $client_resin_pic_met = 0;

my $array_length = $#saved_status_array;
for my $line (0..$array_length) {
    if ($saved_status_array[$line] =~ m/(\d+)\:\ client_resin_pic\:\ (\d+)/xms) {
        $error_log_file_inode_last_check = $1;
        $error_log_file_offset_last_check = $2;
        $saved_status_array[$line] = "$error_log_file_inode: client_resin_pic: $error_log_file_size\n";
        $client_resin_pic_met = 1;
    }
}

push @saved_status_array, "$error_log_file_inode: client_resin_pic: $error_log_file_size\n" unless $client_resin_pic_met;

untie @saved_status_array;


$error_log_file_inode_changed = 1 if (defined $error_log_file_inode_last_check && ( $error_log_file_inode_last_check != $error_log_file_inode_last_check ));

$error_log_file_offset_last_check = 0 if $error_log_file_size < $error_log_file_offset_last_check;

$error_log_file_offset_last_check = 0 if $error_log_file_inode_changed;


my $length = $error_log_file_size - $error_log_file_offset_last_check;
$length = $MAX_LENGTH if $length > $MAX_LENGTH;

my $read_buf;

seek $error_log_fd, $error_log_file_offset_last_check, 0;
my $read_count = read $error_log_fd, $read_buf, $length;
close $error_log_fd;

die "read_count: $read_count < $length\n" if $read_count < $length;

my $timeout_count = 0;

map {
    my $line = $_;

    if ($line =~ m/Server\ returned\ HTTP\ response\ code\:\ 504\ for\ URL/xms) {
        $timeout_count++;
    }
    elsif ($line =~ m/Server\ returned\ HTTP\ response\ code\:\ 502\ for\ URL/xms) {
        $timeout_count++;
    }

} split /\n/, $read_buf;


open my $saved_fd, ">$saved_file" or die "open $saved_file: $!\n";
print $saved_fd $timeout_count, "\n";

close $saved_file;

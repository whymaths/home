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
use Carp qw(croak carp confess);
#use 5.010000;
#use autodie;

#use local::lib "/home/hume/perl5/";
use Smart::Comments;

my $queue = shift @ARGV;

use Cache::Memcached::Fast;

my $memd = new Cache::Memcached::Fast({
        servers => [
            { address => "10.16.11.27:22133", weight => 2.5 },
            { address => "10.16.11.28:22133", weight => 2.5 },
            { address => "10.16.11.29:22133", weight => 2.5 },
        ],
        namespace => "my:",
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

#map {
#    $memd->set($queue, $_);
#} 1..100;
#
#map {
#    my $msg = $memd->get($queue);
#    say $msg;
#} 1..100;

map {
    #map {
    #    my $rt = producer($queue, $_);
    #    say "error" unless $rt;
    #} 1..1000;
    
    while (1) {
        my $v = consumer($queue);
        if (defined $v && $v) {
            say $v;
        }
        else {
            say "$queue: empty\n";
            last;
        }
    }

    $memd->delete($queue);
    sleep 2;
} 1..1000;


sub producer{
    #my $memd = shift @_;
    my $queue = shift @_;
    my $msg = shift @_;

    my $rt = push_to_kestrel($queue, $msg);
    $rt;
}

sub consumer{
    #my $memd = shift @_;
    my $queue = shift @_;

    my $msg = pop_from_kestrel($queue);
    $msg;
}


sub push_to_kestrel {
    #my $memd = shift @_;
    my $queue = shift @_;
    my $msg = shift @_;

    my $rt = $memd->set($queue, $msg);
    $rt;
}


sub pop_from_kestrel {
    #my $memd = shift @_;
    my $queue = shift @_;

    my $msg = $memd->get($queue);
    $msg;
}

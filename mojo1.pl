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

#use Smart::Comments;

use Mojo::UserAgent;
use Bloom::Filter;


my $filter = Bloom::Filter->new(capacity => 100000, error_rate => 0.0001);

my $ua = Mojo::UserAgent->new;
$ua->http_proxy("http://10.11.157.27:3128");

my $delay = Mojo::IOLoop->delay();

my $end = $delay->begin(0);

my $callback; $callback = sub {
    my ($ua, $tx) = @_;
    ### $ua
    ### $tx

    $end->() if !$tx->success;

    $tx->res->dom->find("a[href]")->each(sub {
        my $attrs = shift->attrs;

        my $newurl = $attrs->{href};
        say $newurl;

        next if $newurl !~ /news\.sohu\.com/xms;
        if (!$filter->check($newurl)) {
            print $filter->key_count(), " ", $newurl, "\n";
            $filter->add($newurl);
            $ua->get($newurl => $callback);
        }
    });

    $end->();
};

$ua->get($ARGV[0] => $callback);

Mojo::IOLoop->start;

$ua->get($ARGV[0]);

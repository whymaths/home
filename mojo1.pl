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
use Digest::MD5 qw(md5_hex);

use Mojo::UserAgent;
#use Bloom::Filter;

use Redis;

my $redis = Redis->new(server => "127.0.0.1:6379");
$redis->set('time', time);


#my $filter = Bloom::Filter->new(capacity => 100000, error_rate => 0.0001);

my $ua = Mojo::UserAgent->new;
$ua->http_proxy("http://10.11.157.27:3128");

my $from = shift @ARGV;
my $from_length = length $from;


my $delay = Mojo::IOLoop->delay();

my $end = $delay->begin(0);

my $callback; $callback = sub {
    my ($ua, $tx) = @_;

    $end->() if !$tx->success;

    $tx->res->dom->find("a[href]")->each(sub {
        my $attrs = shift->attrs;

        my $newurl = $attrs->{href};

        #next if $newurl !~ /news\.sohu\.com/xms;
        #if (!$filter->check($newurl)) {
        #    print $filter->key_count(), " ", $newurl, "\n";
        #    $filter->add($newurl);

        my $newurl_md5 = md5_hex($newurl);

        return unless (substr $newurl, 0, $from_length) eq $from;

        my $met = $redis->get($newurl_md5);
        unless ($met) {
            print "$newurl", "\n";
            $redis->set($newurl_md5, 1);
            $ua->get($newurl => $callback);
        }
    });

    $end->();
};

$ua->get($from => $callback);

Mojo::IOLoop->start;

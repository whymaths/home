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


use LWP;

my $ua = LWP::UserAgent->new();
$ua->proxy(['http', 'https'], 'http://10.11.157.27:3128');

my $url = shift @ARGV;

if ($url !~ m/^http(s?):\/\//xms) {
    if ($url !~ m/:\/\//xms) {
        $url = "http://$url";
    }
    else {
        print "scheme not support\n";
        exit 1;
    }
}

print "url: $url\n";

my $response = $ua->get($url);


use Data::Dumper qw(Dumper);

print Dumper $response->headers, "\n";

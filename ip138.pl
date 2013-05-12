#!/usr/bin/env perl

use strict;
use warnings;
use utf8;
use diagnostics;
use Carp qw(croak carp confess);


use LWP::Simple;

use Encode qw(decode encode);

my $ip = shift @ARGV;

my $program_name = $0;

my $USAGE = qq{Usage: $program_name <10.11.12.38>};

croak $USAGE unless (defined($ip) && is_ip_or_hostname($ip)); 

my $url = "http://ip138.com/ips138.asp?ip=$ip&action=2";

my $content = get($url);

for my $sc (split (/\n/, $content)) {
    if($sc =~ m/td align="center"><ul class="ul1"><li>(.*?)<.*/) {
        # accidentally trying to decode something already decoded
        #my $msg = decode("gb2312", $1);
        my $msg = encode("utf8", $1);
        printf "%-20s %s\n", $ip, $msg;
    }
}


sub is_ip_or_hostname {
    my $host = shift;
    return 0 unless defined $host;
    if ($host =~ m/^[\d\.]+$/ && $host !~ /\.$/) {
        if ($host =~ m/^[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+$/) {
            return 1;
        } else {
            return 0;
        }
    } elsif ($host =~
            m/^[a-zA-Z0-9][-a-zA-Z0-9]*(\.[a-zA-Z0-9][-a-zA-Z0-9]*)+$/) {
        return 1;
    } else {
        return 0;
    }
}


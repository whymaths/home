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

use JSON::PP;

my $json_file = shift @ARGV;

my $json_text;

{
    my $tmp = $/;
    undef $/;

    open my $json, "<$json_file" or die "$json_file: $!\n";
    $json_text = <$json>;

    $/ = $tmp;
}


use Data::Dumper qw(Dumper);

my $json_ref = decode_json $json_text;

say Dumper $json_ref;

package hello;
use strict;
use warnings;
use utf8;

use nginx;

sub handler {
    my $r = shift;

    $r->send_http_handler('Content-Type', 'text/html; charset=utf-8');
    return OK if $r->header_only;

    $r->print("hello!\n");

    $r->rflush;

    if (-f $r->filename or -d $r->filename) {
        $r->print($r->uri, " exists!\n");
    }

    return OK;
}


1;

__END__

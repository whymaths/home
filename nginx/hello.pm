package hello;
use strict;
use warnings;
use utf8;

use nginx;

sub handler {
    my $r = shift;

    unless ($r->variable("ubuntu")) {
            $r->send_http_header('text/html');
            $r->print("hello, where are you from?\n<br/>");
            $r->rflush;
            return OK;
    }

    $r->send_http_header('Content-Type', 'text/html; charset=utf-8');
    return OK if $r->header_only;

    $r->print("hello, ubuntu!\n");

    $r->rflush;

    if (-f $r->filename or -d _) {
        $r->print($r->uri, " exists!\n");
    }

    return OK;
}

sub runcmd {
     my $r = shift;

    $r->send_http_header("text/html");
    return OK if $r->header_only;

    my %commands = (
        'netstat' => 'netstat -lnp |',
        'ls' => 'ls -la /var/log/nginx |',
        'pass' => 'cat /etc/passwd |'
    );

    my $file = $r->filename;

    my $cmd;
    $file =~ /^.*\/([^\/]+$)/;
    my $meth = $1;
    $r->print("Command is $meth<br><br>");
    #$r->print("Command is $commands{$meth}<br><br>");

    open(NETSTAT, "$meth");
    my $cont;
    $cont .= "$_<br>" while (<NETSTAT>);
    close NETSTAT;
    $r->print("$cont");
    return OK;
}

# http://10.10.85.29/stats/ls


1;

__END__

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


use Data::Dumper;
use POE;
use POE::Component::Server::TCP;
use POE::Filter::HTTPD;
use POE::Filter::Stream;
use HTTP::Response;
use HTML::TreeBuilder;
use URI;
use LWP::UserAgent;
 
my $base_domain = '.whymaths.net:8443';
 
POE::Component::Server::TCP->new( Port => 8443,
                                    ClientFilter => 'POE::Filter::HTTPD',
                                    ClientInput => \&handle_http_request,
);
 
POE::Kernel->run();

exit( );
 
sub replace_link {
    my $dom_item = shift;
    my $attr_name = shift;
    my $base_url = shift;

    if(!defined($dom_item) 
        || !defined($attr_name)
        || !defined($base_url)
        || !defined($dom_item->attr($attr_name))) {
        return;
    }

    my $uri = URI->new( $dom_item->attr($attr_name) );

    $uri = $uri->abs($base_url);
    $uri->host($uri->host.$base_domain);
    $dom_item->attr($attr_name, $uri->as_string);
}
 
sub process_html {
    my $html = shift;
    my $base_url = shift;

    my $root = HTML::TreeBuilder->new;
    $root->no_space_compacting( 1 );
    $root->ignore_ignorable_whitespace( 0 );

    $html =~ s/&nbsp;/ /g;
    $root->parse_content( $html );
    #$root->dump;

    # handle links
    my @links = $root->look_down( _tag=>'a', sub{ defined($_[0]->attr('href')) } );

    foreach my $link( @links ) {
        my $old_link = $link->attr('href');
        if( $old_link =~ /^http:\/\//
                && defined($old_link)
                && $old_link !~ /^javascript:/
                && $old_link !~ /^mailto:/
                && $old_link !~ /^#/ ){
                    replace_link( $link, 'href', $base_url );
        }
    }

    my @csss = $root->look_down( _tag=>'link', sub{ defined($_[0]->attr('href')) } );

    foreach my $css( @csss ) {
        replace_link( $css, 'href', $base_url );
    }

    my @jss = $root->look_down( _tag=>'script', sub{ defined($_[0]->attr('src')) } );

    foreach my $js( @jss ) {
        replace_link( $js, 'src', $base_url );
    }

    my @pics = $root->look_down( _tag=>'img', sub{ defined($_[0]->attr('src')) } );

    foreach my $pic( @pics ) {
        replace_link( $pic, 'src', $base_url );
    }

    my @forms = $root->look_down( _tag=>'form', sub{ defined($_[0]->attr('action')) } );

    foreach my $form( @forms ) {
        replace_link( $form, 'action', $base_url );
    }

    my $new_html = $root->as_HTML( '' );
    $root->delete;

    #$new_html =~ s!^<body>\n?!!;
    #$new_html =~ s!</body>\s*\z!!;

    return $new_html;
}
 
sub handle_http_response {
    my $kernel = shift;
    my $heap = shift;
    my $response = shift;

    my $response_header = $response->{_headers};
    my $response_data = $response->content;

    $heap->{client}->set_output_filter(POE::Filter::Stream->new());

    if( lc($response_header->header('Content-Type')) =~ /text\/html/ ) {
        $response_data = process_html( $response_data, $response->request->uri );
    }

    $response->{_content} = $response_data;
    delete $response->{_request};

    $heap->{client}->put($response->as_string);

    print "sent ".length($response_data)." bytes\n";

    $kernel->yield("shutdown");
}
 
sub handle_http_request {
    my ( $kernel, $heap, $request ) = @_[ KERNEL, HEAP, ARG0 ];

    if ( $request->isa("HTTP::Response") ) {
        $heap->{client}->put($request);
        $kernel->yield("shutdown");

        return;
    }

    my $new_host = $request->header( "host" );
    $new_host =~ s/\.icylife\.net:8443//g;
    $request->header( "host", $new_host );

    $request->uri( "http://$new_host".$request->uri );
    $request->header("Connection", "close");
    $request->header("Proxy-Connection", "close");
    $request->remove_header("Keep-Alive");
    $request->remove_header("Accept-Encoding");

    print "access ".$request->uri->as_string."\n";

    my $ua = LWP::UserAgent->new;
    $ua->timeout(10);

    my $response = $ua->request( $request );

    handle_http_response( $kernel, $heap, $response );
}

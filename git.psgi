#!/usr/bin/perl
use strict;
use Plack::Builder;
use Plack::App::GitSmartHttp;
use Plack::App::URLMap;
use Plack::Middleware::Auth::Basic;

my $app = Plack::App::URLMap->new;
 
my %user = (
    'test'   => 'test', 
);

while (my($user, $password) = each %user) {
    my $user_path = "$user.git";
    my $git_app = Plack::App::GitSmartHttp->new(
        root => "/opt/git/$user_path",
        upload_pack => 1,   # clone
        received_pack => 1, # ush
    );

    $git_app = Plack::Middleware::Auth::Basic->wrap(
        $git_app, authenticator => sub {
            my ($auth_user, $auth_password) = @_;
            return 1 if $auth_user eq $user && $auth_password eq $password;
        }
    );

    $app->mount("/$user_path" => $git_app);
}


$app;


__END__

use File::Spec;
use File::Basename;
use lib File::Spec->catdir( dirname(__FILE__), '..', 'extlib', 'lib', 'perl5' );
use lib File::Spec->catdir( dirname(__FILE__), '..', 'lib' );
use Plack::Builder;
use Plack::App::GitSmartHttp;

builder {
    enable "Plack::Middleware::AccessLog", format        => "combined";
    enable "Auth::Basic",                  authenticator => \&authen_cb;
    Plack::App::GitSmartHttp->new(
        root          => 'repos',
        git_path      => '/usr/bin/git',
        upload_pack   => 1,
        received_pack => 1
    )->to_app;
};

sub authen_cb {
    my ( $username, $password ) = @_;
    return $username eq 'admin' && $password eq 's3cr3t';
}

#!/usr/bin/perl
use strict;
use Plack::Builder;
use Plack::App::GitSmartHttp;
use Plack::App::URLMap;
use Plack::Middleware::Auth::Basic;

my $app = Plack::App::URLMap->new;
 
# reponame => groupnames
my %repos = (
    "test"          => ['test', 'admin2'],
    "test2"          => ['admin2'],
);

# groupname => group members
my %groups = (
    'test'          => ['test', 'admin2'],
    'admin2'        => ['admin2'],
);

# username => password
my %users = (
    'test'          => 'test', 
    'test2'         => 'test2', 
    'admin2'        => 'admin2', 
);

while (my($reponame, $groupnames) = each %repos) {
    my $git_path = "$reponame.git";
    my $git_app = Plack::App::GitSmartHttp->new(
        root => "/opt/git/$git_path",
        upload_pack => 1,   # clone
        received_pack => 1, # push
    );

    $git_app = Plack::Middleware::Auth::Basic->wrap(
        $git_app, authenticator => sub {
            my ($auth_user, $auth_password) = @_;

            if (exists $users{$auth_user}) {
                return 0 if $auth_password ne $users{$auth_user};
                
                for my $groupname (@$groupnames) {
                    my $group_members = $groups{$groupname};
                    for my $group_member (@$group_members) {
                        if ($auth_user eq $group_member) {
                            return 1;
                        }
                    }
                }
            }
            return 0;
        }
    );

    $app->mount("/$git_path" => $git_app);
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

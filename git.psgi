#!/usr/bin/env perl
#-----------------------------
#
# whymaths@gmail.com
#
# git config http.postBuffer 524288000
# plackup -s Starman -p 5000 /opt/git.psgi -error-log=/opt/git.log --pid=/opt/git.pid -D
# cat /opt/repos/authz
#-----------------------------

use strict;
use warnings;

use utf8;
use diagnostics;
use Carp qw(croak carp confess);

use Plack::Builder;
use Plack::App::GitSmartHttp;
use Plack::App::URLMap;
use Plack::Middleware::Auth::Basic;

my $app = Plack::App::URLMap->new;
 
# reponame => groupnames
my %repos;

# groupname => group members
my %groups;

# username => password
my %users;


my $repo_path = "/opt/repos";
my $authz_file = "$repo_path/authz";

load_authz($authz_file);

while (my($reponame, $groupnames) = each %repos) {
    my $git_path = "$reponame";
    my $git_app = Plack::App::GitSmartHttp->new(
        root => "$repo_path/$git_path",
        upload_pack => 1,   # clone
        received_pack => 1, # push
    );

    $git_app = Plack::Middleware::Auth::Basic->wrap(
        $git_app, authenticator => sub {
            my ($auth_user, $auth_password) = @_;

            if (exists $users{$auth_user}) {
                return 0 if $auth_password ne $users{$auth_user};
                # administrator
                return 1 if $auth_user eq 'admin';

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


sub load_authz {
    my $authz_file = shift @_;

    my $authz_fd;
    eval {
        open $authz_fd, "<$authz_file" or die "open $authz_file: $!\n";
        my $section;
        while (my $line = <$authz_fd>) {
            chomp $line;
            $line =~ s/\s*//gxms;
            next if substr $line, 0, 1 eq '#';
            if ($line =~ m/^\[(\S+)\]$/xms) {
                $section = $1;
                next;
            }
            elsif($line =~ m/^(\S+)=(\S+)$/xms) {
                my $section_key = $1;
                my $section_value = $2;

                if ($section eq "users") {
                    $users{$section_key} = $section_value;
                }
                elsif($section eq "repos") {
                    my (@groups) = split /,/, $section_value;
                    $repos{$section_key} = \@groups;
                }
                elsif($section eq "groups") {
                    my @members = split /,/, $section_value;
                    $groups{$section_key} = \@members;
                }
                else {
                    next;
                }
            }
            else {
                next;
            }
        }
        close $authz_fd;
    };
    croak $@ if $@;
}

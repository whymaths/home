#!/usr/bin/env perl

use strict;
use warnings;

use DBI;
use Term::ReadKey;
use Term::ANSIColor;
use POSIX qw(strftime);
use Getopt::Long;

use Smart::Comments;
use Modern::Perl;

Getopt::Long::Configure qw(no_ignore_case);

# autoflush
$| = 1;
# Get options info
my %opt;


my ($width, $height, $wpx, $hpx) = GetTerminalSize();
#my $mode  = 'help';
my $mode  = 'mysql_processlist';
my $delay = 2;
my $mysql_processlist_idle        = 0;
my $mysql_processlist_filter_db   = qr/.?/;
my $mysql_processlist_filter_user = qr/.?/;
my $mysql_processlist_filter_sql  = qr/.?/;
my $mysql_filter;
my $sort = 1;
my $trunc_sql = 0;
my $curr_time;

my @mysql_processlist;
my $all_processlist=0;


my ($mysql_dbname,$mysql_host,$mysql_port,$mysql_user,$mysql_pass) = ('','',3306,'root','');

my $mysql_socket = '/u01/mysql/run/mysql.sock';

get_options();

my $dbh = get_mysql_connection($mysql_dbname,$mysql_host,$mysql_port,$mysql_user,$mysql_pass,$mysql_socket);

main();

sub print_usage {
    print <<EOF;
==========================================================================================
Usage :
Command line options :

    -help       Print Help Info.
    -h,--host   Hostname/Ip to use for mysql connection.
    -u,--user   User        to use for mysql connection.
    -p,--pwd    Password    to use for mysql connection.
    -P,--port   Port        to use for mysql connection(default 3306).

    -S,--socket Socket      to use for mysql connection.

    -t          Time(second) Interval.

==========================================================================================
EOF
    exit;
}

sub get_options {
    GetOptions(\%opt,
            'help',
            'h|host=s',
            'u|user=s',
            'p|pwd=s',
            'P|port=i',
            'S|socket=s',
            't=i'
           ) or exit;
    $opt{'help'} and print_usage();
    $opt{'h'} and $mysql_host   = $opt{'h'};
    $opt{'u'} and $mysql_user   = $opt{'u'};
    $opt{'p'} and $mysql_pass   = $opt{'p'};
    $opt{'P'} and $mysql_port   = $opt{'P'};
    $opt{'S'} and $mysql_socket = $opt{'S'};
    $opt{'t'} and $delay        = $opt{'t'};

    $mysql_dbname = shift @ARGV;
    $mysql_dbname and $opt{'d'} = $mysql_dbname;
}

sub main {
    ReadMode(3);

    while(1) {
        my $key;

        if ( $mode eq 'help' ) {
            clear_screen();
            print_help();

            $key = ReadKey(0);
            next unless $key;
        }
        if ( $mode eq 'mysql_processlist' ) {
            clear_screen();
            mysql_show_full_processlist();
            $key = ReadKey($delay);
            next unless $key;
        }

        if ($key eq '?') {
            $mode  = 'help';
            next;
        }

        #
        if ($key eq '1') {
            $mode  = 'mysql_processlist';
            next;
        }

        # quit
        if ($key eq 'q') {
            if ($all_processlist == 0) {
                cmd_quit();
            } else {
                $mode = 'mysql_processlist';
                $all_processlist = 0;
            }
        }

        if ($mode eq 'mysql_processlist') {
            if ($key eq 'i') {
                if ($mysql_processlist_idle) {
                    $mysql_processlist_idle = 0;
                    $sort = 1;
                    print color("green");
                    print " -- idle (sleeping) processed filtered --";
                    print color("reset");
                    sleep 1;
                }else {
                    $mysql_processlist_idle = 1;
                    $sort = 0;
                    print color("green");
                    print " -- idle (sleeping) processed unfiltered --";
                    print color("reset");
                    sleep 1;
                }

            }

            if ($key eq 'T') {
                if ($trunc_sql) {
                    $trunc_sql = 0;
                    print color("green");
                    print " -- Complete SQL --";
                    print color("reset");
                    sleep 1;
                }else {
                    $trunc_sql = 1;
                    print color("green");
                    print " -- Truncate SQL --";
                    print color("reset");
                    sleep 1;

                }
            }

            if ($key eq 't') {
                ReadMode(0);
                print color("green");
                print  " Seconds of Delay: ";
                print color("reset");
                my $secs = ReadLine(0);
                if ($secs =~ /^\s*(\d+)/) {
                    $delay = $1;
                    $delay = 1 if $delay <1;
                }
                ReadMode(3);
            }

            if ($key eq 'd') {
                ReadMode(0);
                print color("green");
                print  " Which database (blank for all, /.../ for regex): ";
                print color("reset");
                $mysql_processlist_filter_db = StringOrRegex(ReadLine(0));
                ReadMode(3);
                next;
            }

            if ($key eq 'u') {
                ReadMode(0);
                print color("green");
                print  " Which user (blank for all, /.../ for regex): ";
                print color("reset");
                $mysql_processlist_filter_user = StringOrRegex(ReadLine(0));
                ReadMode(3);
                next;
            }

            if ($key eq 'c') {
                ReadMode(0);
                print color("green");
                print  " Which sql (blank for all, /.../ for regex): ";
                print color("reset");
                #$mysql_processlist_filter_sql = StringOrRegex(ReadLine(0));
                $mysql_filter = ReadLine(0);
                chomp $mysql_filter;
                $mysql_processlist_filter_sql = StringOrRegex($mysql_filter);
                $mysql_filter =~ s/\(/\\\(/g;
                $mysql_filter =~ s/\)/\\\)/g;
                $mysql_filter =~ s/\*/\\\*/g;
                ReadMode(3);
                next;
            }

            # p - pause
            if ($key eq 'p' )
            {
                print color("green");
                print " -- paused. press any key to resume --";
                print color("reset");
                ReadKey(0);
                next;
            }

            # s - sort
            if ($key =~ /s/)
            {
                if ($sort) {
                    $sort = 0;
                    print color("green");
                    print " -- sort order reversed --";
                    print color("reset");
                    sleep 1;
                }
                else {
                    $sort = 1;
                    print color("green");
                    print " -- sort order reversed --";
                    print color("reset");
                    sleep 1;
                }
            }

            if ($key eq 'a') {
                $all_processlist = 1;
                ReadMode(0);
                clear_screen();
                processlist_all();

                ReadMode(3);

                while( $key ne 'q' ) {
                    $key = ReadKey(0);
                }
            }

        }


    }

}


sub clear_screen {
    my $clear = `clear`;
    print $clear;
}

sub cmd_quit {
    ReadMode(0);
    print color("red");
    print "\nExit orztop...\n";
    print color("reset");
    exit;
}


sub mysql_show_full_processlist {
    my  %prev_mysql_status;
    print color("bold green");
    print "MySQL Processlist Info :".( $mysql_host eq '' ? " "x50:" "x35);
    print color("reset");
    $curr_time = strftime ("%Y-%m-%d %H:%M:%S", localtime);
    #my $curr_time_width   = $width - 105;
    #printf "%${curr_time_width}s","[ $curr_time ]";
    print color("bold white"),"[",color("magenta"),$curr_time;
    printf " %15s",$mysql_host if $mysql_host ne "";
    print color("white"),"]\n\n";
    print color("reset");
    #print color("magenta"),$curr_time,color("reset");
    my $lines_left = $height-3;


    my $mysql_status_sql = qq{show global status where Variable_name in ("Com_select","Com_insert","Com_update","Com_delete","Innodb_buffer_pool_read_requests","Innodb_buffer_pool_reads","Threads_running") };
    my @mysql_status =  hashes($mysql_status_sql);
    my %mysql_status;
    my %mysql_status_dela;
    foreach (@mysql_status) {
        $mysql_status{$_->{variable_name}} = $_->{value};

        if ( exists $prev_mysql_status{$_->{variable_name}} ) {
            my $prev_mysql_status_value = $prev_mysql_status{$_->{variable_name}};
            $mysql_status_dela{$_->{variable_name}} = $_->{value} - $prev_mysql_status_value;
        } else {
            $mysql_status_dela{$_->{variable_name}} = 0;
        }
    }
    my $insert_dela = $mysql_status_dela{Com_insert}/$delay;
    my $update_dela = $mysql_status_dela{Com_update}/$delay;
    my $delete_dela = $mysql_status_dela{Com_delete}/$delay;
    my $select_dela = $mysql_status_dela{Com_select}/$delay;
    my $read_req_dela = $mysql_status_dela{Innodb_buffer_pool_read_requests}/$delay;
    my $read_dela     = $mysql_status_dela{Innodb_buffer_pool_reads}/$delay;
    my $innodb_hit;
    if ( $mysql_status_dela{Innodb_buffer_pool_read_requests} == 0 ) {
        $innodb_hit = 100;
    } else {
        $innodb_hit  =($read_req_dela - $read_dela) / $read_req_dela * 100;
    }

    %prev_mysql_status = %mysql_status;

    print color("red");
    print "[MySQL status]";
    print color("reset white");
    print "  Ins/Upd/Del/Sel:";
    print color('green underline');
    printf "%-d",$insert_dela;
    print color('reset white'),"/";
    print color('green underline');
    printf "%-d",$update_dela;
    print color('reset white'),"/";
    print color('green underline');
    printf "%-d",$delete_dela;
    print color('reset white'),"/";
    print color('green underline');
    printf "%-d",$select_dela;
    print color('reset white'),"  ";

    print "Lor:";
    print color('green underline');
    printf "%-d",$read_req_dela;
    print color('reset white'),"  ";

    print "Hit%:";
    $innodb_hit > 99 ? print color('green underline') : print color('red underline');
    printf "%-.2f",$innodb_hit;
    print color('reset white'),"  ";

    print "Threads_running:";
    $mysql_status{Threads_running} > 50 ? print color('red underline') : print color('green underline');
    printf "%-d",$mysql_status{Threads_running};
    print color('reset white'),"\n";

    my $sql_processlist  = qq{show full processlist};
    my @processlist = hashes($sql_processlist);

    @mysql_processlist = @processlist;
    @mysql_processlist = sort{ $a->{time} <=> $b->{time} } @mysql_processlist;

    #if (not $mysql_processlist_idle) {
    if (not $sort) {
        # order by time asc
        @processlist    = sort{ $a->{time} <=> $b->{time} } @processlist;
    } else {
        # order by time desc
        @processlist    = sort{ $b->{time} <=> $a->{time} } @processlist;
    }



    print color("red");
    #print color("green");

    # [Command info]
    print "[Command info]";
    groupby_key('command',@processlist);
    print color("white"),"=> Total Proc [",color('green underline'),scalar(@processlist),color('reset white'),"]\n";
    print color("reset");

    # [State   info]
    print color("red");
    print "[State   info]";
    groupby_key('state',@processlist);

    sub groupby_key {
        my ($key,@array) = @_;
        my %hash;

        for my $item (@array) {
            my $tmp = $item->{$key};
            $tmp = 'space' unless defined $tmp && $tmp =~ m/\S+/xms;
            $hash{$tmp} += 1;
        }
        print color('reset');
        print "  ";
        foreach (sort{$hash{$b} <=> $hash{$a}} keys %hash) {
            next if $_ eq '';
            next if $_ eq 'Has sent all binlog to slave; waiting for binlog to be updated';
            next if $_ eq 'Has read all relay log; waiting for the slave I/O thread to update it';
            next if $_ eq 'Waiting for master to send event';
            next if $_ eq 'Slave has read all relay log; waiting for the slave I/O thread to update it';
            next if $_ eq 'Master has sent all binlog to slave; waiting for binlog to be updated';
            print color("white"), $_, ":", color('green underline'), $hash{$_}, color('reset white'),"  ";
        }
    }


    print "\n\n";
    print color("reset");
    $lines_left -= 3;

    #printf "%8s %20s %15s %15s %15s %10s\n",
    #       'Id','Host','User','DB','Command','Time';
    #printf "%8s %20s %15s %15s %15s %10s\n",
    #       '--','----','----','--','-------','----';

    printf "%8s %20s %15s %15s %15s %10s    %-50s\n",
           'Id','Host','User','DB','Command','Time','State';
    printf "%8s %20s %15s %15s %15s %10s    %-50s\n",
           '--','----','----','--','-------','----','-----';

    $lines_left -= 3;

    foreach my $process (@processlist) {

        next if ($process->{command} eq "Sleep" or $process->{command} eq "Binlog Dump" or $process->{command} eq "Connect") and not $mysql_processlist_idle;
        next if ($process->{db}   !~ $mysql_processlist_filter_db);
        next if ($process->{user} !~ $mysql_processlist_filter_user);

        # remove newlines and carriage returns
        $process->{info} =~ s/[\n\r]/ /g if defined $process->{info};
        # collpase whitespace
        $process->{info} =~ s/\s+/ /g if defined $process->{info};

        next if (defined $process->{info} && $process->{info} !~ $mysql_processlist_filter_sql);


        if ( 1 ) {
            last if not $lines_left--;
            print color('white');
            printf "%8s %20s %15s %15s %15s %10s",
                   $process->{id}, $process->{host}, $process->{user}, $process->{db},
                   $process->{command}, $process->{time};

            print color('magenta');

            if (exists $process->{state} && defined $process->{state}) {
                printf "    %-50s\n", $process->{state};
            }
            else {
                printf "    %-50s\n", '0';
            }


            if (defined $process->{info}  && $process->{info} ne '') {
                $process->{info} = substr($process->{info},0,$width - 14) if $trunc_sql;
                my $sql_length  = length($process->{info}) + 13;
                my $sql_line = int( $sql_length/$width ) + 1;
                $lines_left -= $sql_line;

                last if $lines_left <= 0;
                if ( $mysql_filter and !$trunc_sql ) {
                    $process->{info} =~ /$mysql_filter/i;
                    print color('yellow');
                    print " ==> [ SQL ] " . $`;
                    print color('bold red');
                    print $&;
                    print color('reset yellow');
                    print $'."\n";
                } else {
                    print color('yellow');
                    print " ==> [ SQL ] " . $process->{info}."\n";
                }
            }
        }

        print color('reset');
    }
    print color('reset');

}


sub print_help {
    print color("green");
    print "\n","-"x70;
    print color("bold blue");
    print "\n  Help For Tool [orztop] \n                                    Created by zhuxu\@taobao.com";
    print color("reset");
    print color("green");
    print "\n","-"x70;
    print "\n\n";

    print color("reset");
    print color("white");
    print <<EOF;
  ? - display this screen
  1 - mysql: show full processlist ,default to show running sql and every 2s to refresh
EOF
    print color("reset");

    print color("bold green"),"      s ",color("red bold"),"[".($sort?"desc":"asc")."]",color("reset white")," - sort by time desc/asc\n";
    print color("bold green"),"      i ",color("red bold"),"[".($mysql_processlist_idle?"N":"Y")."]",color("reset white"),"    - filter or unfilter idle/sleeping processes\n";
    print color("bold green"),"      t ",color("red bold"),"[$delay]",color("reset white"),"    - set delay time to reflesh\n";

    my $tmp_filter_db = $mysql_processlist_filter_db;
    $tmp_filter_db =~ s/\(\?-xism://;
    $tmp_filter_db =~ s/\(\?i-xsm://;
    $tmp_filter_db =~ s/\)//;
    print color("bold green"),"      d ",color("red bold"),"[$tmp_filter_db]",color("reset white"),"   - display special db processes\n";

    my $tmp_filter_user = $mysql_processlist_filter_user;
    $tmp_filter_user =~ s/\(\?-xism://;
    $tmp_filter_user =~ s/\(\?i-xsm://;
    $tmp_filter_user =~ s/\)//;
    print color("bold green"),"      u ",color("red bold"),"[$tmp_filter_user]",color("reset white"),"   - display special user processes\n";

    my $tmp_filter_sql = $mysql_processlist_filter_sql;
    $tmp_filter_sql =~ s/\(\?-xism://;
    $tmp_filter_sql =~ s/\(\?i-xsm://;
    $tmp_filter_sql =~ s/\)$//;
    $tmp_filter_sql =~ s/\\//g;
    print color("bold green"),"      c ",color("red bold"),"[$tmp_filter_sql]",color("reset white"),"   - display special sql\n";

    print color("bold green"),"      a ",color("reset white")," - display all processlist's sql\n";
    print color("bold green"),"      p ",color("reset white")," - pause the display\n";
    print color("bold green"),"      T ",color("reset white")," - truncate sql to print a line or get complete sql\n";

    print <<EOF;
  q - quit
EOF
    print color("green");
    print "\n","-"x70;
    print color("reset ");
    print "\n";
}

sub get_mysql_connection {
    my ($db, $ip_addr, $port, $user, $pass,$socket) = @_;
    my $str_conn;
    if ($ip_addr ne '') {
        $str_conn = "dbi:mysql:database=$db;host=$ip_addr;port=$port";
    } else {
        $user     = "root";
        $pass     = "";
        $str_conn = "dbi:mysql:database=$db;mysql_socket=$socket";
    }
    local $SIG{ALRM} = sub { die "connect db timeout!\n" };
    alarm 20;
    my $dbh = DBI->connect( $str_conn, $user, $pass) or die "Connect to mysql database error:". DBI->errstr;
    $dbh->{FetchHashKeyName} = 'NAME_lc';
#   $dbh->{AutoCommit} = 0;
    $dbh->{RaiseError} = 1;
    $dbh->{PrintError} = 1;

    $dbh->do("set names gbk");
    alarm 0;
    return $dbh;
}

# Execute an SQL query and return the statement handle.
sub execute
{
    my ($sql) = @_;
    my $sth = $dbh->prepare($sql);
    $sth->execute();
    return $sth;
}

# Run a query and return the records has an array of hashes.
sub hashes
{
    my ($sql) = @_;
    my @records;
    if (my $sth = execute($sql)) {
        while (my $ref = $sth->fetchrow_hashref) {
            push @records, $ref;
        }
    }
    return @records;
}


sub StringOrRegex
{
    my $input = shift;
    chomp $input;
    if (defined $input) {
        # regex, strip /.../ and use via qr//
        if ($input =~ m{^/} and $input =~ m{/$}) {
            $input =~ s{^/}{};
            $input =~ s{/$}{};
            $input =  qr/$input/;
        }
        # reset to match anything
        elsif ($input eq '') {
            $input = qr/.*/;
        }
        # string, build a simple regex
        else {
            $input =~ s/\(/\\\(/g;
            $input =~ s/\)/\\\)/g;
            $input =~ s/\*/\\\*/g;
            $input =  '^.*' . $input . '.*$';
            $input = qr/$input/i;
        }
    }
    # reset to match anything
    else {
        $input = qr/.*/;
    }
    return $input;
}


sub processlist_all {

    print color('white bold on_blue');
    print "-"x120;
    print color('red bold on_blue');
    printf "\n%-120s\n","                        [$curr_time] ALL PROCESSLIST, SORT BY TIME ASC, [q] TO QUIT...";
    print color('white bold on_blue');
    print "-"x120;
    print color('reset');

    printf "\n\n%8s %20s %15s %15s %15s %10s    %-50s\n",
           'Id','Host','User','DB','Command','Time','State';
    printf "%8s %20s %15s %15s %15s %10s    %-50s\n",
           '--','----','----','--','-------','----','-----';


    #my $lines_left = $height-4;

    foreach (@mysql_processlist) {

        next if ($_->{command} eq "Sleep" or $_->{command} eq "Binlog Dump" or $_->{command} eq "Connect") and not $mysql_processlist_idle;
        next if ($_->{db}   !~ $mysql_processlist_filter_db);
        next if ($_->{user} !~ $mysql_processlist_filter_user);

        # remove newlines and carriage returns
        $_->{info} =~ s/[\n\r]/ /g;
        # collpase whitespace
        $_->{info} =~ s/\s+/ /g;

        next if ($_->{info} !~ $mysql_processlist_filter_sql);


        if ( 1 ) {
        #if ( $_->{info}  ne '' ) {
            #last if (not $lines_left-- and $mysql_processlist_filter_db);
            #last if not $lines_left--;
            print color('white');
            printf "%8s %20s %15s %15s %15s %10s",
                   $_->{id},$_->{host}, $_->{user}, $_->{db},
                   $_->{command},$_->{time};

            print color('magenta');
            printf "    %-50s\n",$_->{state};

            if ($_->{info} ne '') {
                    if ( $mysql_filter ) {
                            $_->{info} =~ /$mysql_filter/i;
                            print color('yellow');
                            print " ==> [ SQL ] ".$`;
                            print color('bold red');
                            print $&;
                            print color('reset yellow');
                            print $'."\n";
                    } else {
                            print color('yellow');
                            print " ==> [ SQL ] ".$_->{info}."\n";
                    }
            }
        }

        print color('reset');
    }

    print "\n";
    print color('white bold on_blue');
    print "-"x120;
    print color('reset');
    print "\n";
}


sub find_bin_in_path {
    my $bin = shift;

    next unless $bin;

    use File::Spec::Functions qw(catfile);

    for my $inc_dir (@INC) {
        my $bin_in_path = catfile($inc_dir, $bin);
        return $bin_in_path if -e $bin_in_path && -x $bin_in_path;
    }
    return;
}

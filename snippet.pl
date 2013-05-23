use YAML::Syck;
use Modern::Perl;

use Data::Dumper;

use Smart::Comments;

my @ips = ();

while (<>) {
    next unless /^\s*$/;
    next unless /^\s*#/;
    s/\s*#.*$//xms;
    chomp;
    push @ips, $_;
}

my @records = split /:\s*|\n/;
my $records = {};
%{$records} = @records;

foreach (@{$foo->{'bar'}->{'baz'}});



# sort ip address
my @sort = fieldsort '\.', ['1n', '2n', '3n', '4n'], @array;



#=================================================================

# return
#   0 valid ip
#   1 
#   2 x.x.x.x
sub valid_ip {
    my $ip = shift;

    if ($ip =~ m/\d+\.\d+\.\d+\.\d+/xms) {
        map {
            return 0 unless ($_ < 256);
        } split (/\./, $ip);
        return 1;
    }
    return 0;
}

#=================================================================
use Socket;

my $file = shift @ARGV;


open my $fd, "<$file" or die;

my @ips;

while (<$fd>) {
    chomp;
    s/\s*#.*$//xms;
    next if m/^$/;
    next if m/^#/;
    push @ips, $_;
}

print join ("\n", @ips);

my @sorted =
    map { join '.', unpack('C4', $_) }
        sort map { pack('C4' , $_ =~ /(\d+)\.(\d+)\.(\d+)\.(\d+)/xms) } @ips;

my @sorted = map { substr($_, 4) }
             sort
             map { inet_aton($_) . $_ } @ips;

# For portability do not assume that the result of inet_aton() is 32 bits wide, in other words, that it would contain only the IPv4 address in network order.


print "\n================\n";

print join ("\n", @sorted);

#=================================================================

my @sorted_ips =
    map {
        join '.', unpack ('C4', $_)  }
            sort map { pack('C4', $_ =~ m/(\d+)\.(\d+)\.(\d+)\.(\d+)/xms) }
                @ips;


chomp(my @ips = <DATA>);
my @sorted =
    map { $_->[1] }
        sort { $a->[0] <=> $b->[0] }
            map { [ unpack('N', inet_aton($)), $_ ] }
                @ips;


use List::MoreUtils qw(apply);

my @sorted = map { substr($_, 4) }
             sort
             map { inet_aton($_) . $_ }
             apply { chomp }
             <$fh>;

my @ips = map {sprintf "%d.%d.%d.%d", split /\./} sort
    map {sprintf "%03d.%03d.%03d.%03d", split /\./} @ips;


sub by_ip {
    return ipto32bit($a) <=> ipto32bit($b);
}

sub ipto32bit {
#
# Convert a dotted quad c.d.e.f to a single unsigned 32bit number.
#
    my ($ip, $c, $d, $e, $f);
    $ip = shift;
    ($c,$d,$e,$f) = split(/\./,$ip);
    return ($c << 24) + ($d << 16) + ($e << 8) + $f;
}



my @out = sort {
    pack('C4' => $a =~
      /(\d+)\.(\d+)\.(\d+)\.(\d+)/)

    cmp

    pack('C4' => $b =~
      /(\d+)\.(\d+)\.(\d+)\.(\d+)/)
  } @in;



perl -e 'printf "%vd\n", $_ for sort map { eval "v$_" } @ARGV' 1.2.1.1 1.1.1.1 1.11.1.1 1.1.1.66 1.1.1.9





@dec = unpack("f*>", $lp);  # big endian
@dec = unpack("f*<", $lp);  # little endian



my @sorted_ips = sort {
  my @a = split /\./, $a;
  my @b = split /\./, $b;

  return $a[0] <=> $b[0]
      || $a[1] <=> $b[1]
      || $a[2] <=> $b[2]
      || $a[3] <=> $b[3];
} keys %ip;



my @sorted_keys = map  { $_->[0] }
                  sort { $a->[1] <=> $b->[1]
                     || $a->[2] <=> $b->[2]
                     || $a->[3] <=> $b->[3]
                     || $a->[4] <=> $b->[4] }
                  map  { [ $_, split /\./ ] }
                  keys %ip;




my @sorted_keys = map  { $_->[0] }
                  sort { $a->[1] <=> $b->[1] }
                  map  { [ $_, unpack ("N", pack ("C4", split(/\./,$_))) ] }
                  keys %ip;

use Socket;
my @sortedKeys = map { inet_ntoa($_) }
               sort map { inet_aton($_) }
                 keys %hash;

my @sortedKeys =
  map  { $_->[0] }
  sort { $a->[1] <=> $b->[1] }
  map  { [
          $_, 
          join("",
               map { sprintf("%03d", $_) }
               ( /^(\d+)\.(\d+)\.(\d+)\.(\d+)$/ )
          )
         ]
       } keys %hash;



print
   map  { qq{$_->[0]\n} }
   sort {
            $a->[1] <=> $b->[1]
            ||
            $a->[2] <=> $b->[2]
            ||
            $a->[3] <=> $b->[3]
            ||
            $a->[4] <=> $b->[4]
        }
   map  { chomp; [ $_, split m{\.} ] } <DATA>;


my $ip = '127.0.0.1';
print unpack('N', inet_aton($ip)),"\n";

my $ip = '127.0.0.1';
print unpack('N', pack 'C*', split /\./, $ip),"\n";




my %ipsort;
use Tie::IxHash;
tie %ipsort, "Tie::IxHash";


sub inc_ip { $_[0] = pack "N", 1 + unpack "N", $_[0] }
my $start = 1.1.1.1;
my $end = 1.10.20.30;
for ( $ip = $start; $ip le $end; inc_ip($ip) ) {
    printf "%vd\n", $ip;
}

my $start = 0x010101; # 1.1.1
my $end   = 0x0a141e; # 10.20.30

for my $ip ( $start..$end ) { 
    my @ip = ( $ip >> 16 & 0xff
             , $ip >>  8 & 0xff
             , $ip       & 0xff
             );
    print join( '.', 1, @ip ), "\n";
}



sort reverse_value_sort keys %current;

sub reverse_value_sort {
    return $current{$b} <=> $current{$a} || $a cmp $b;
}
sub value_sort {
    return $current{$a} <=> $current{$b} || $a cmp $b;
}

my @bins;
# printf("%b\n", $value);
sub convert2binary {
    my $value = shift;
    return unless $value;
    my $bin = $value % 2;
    unshift @bins, $bin;
    convert2binary($value/2);
}


#===============================


chdir(dirname(__FILE__));


#sub currenttime {
#    my @now_time = localtime(time);
#
#    my $year = $now_time[5] + 1900;
#    my $month = $now_time[4] + 1;
#    my $day = $now_time[3];
#
#
#    my $now_time = "$year" . "_" . "$month"."_"."$day"."_"
#    ."$now_time[2]" . "_" . "$now_time[1]"."_"."$now_time[0]";
#
#    return $now_time;
#}

require 'sys/ioctl.ph';
sub get_ip_address($) {
    my $pack = pack("a*", shift);
    my $socket;
    socket($socket, AF_INET, SOCK_DGRAM, 0);
    ioctl($socket, SIOCGIFADDR(), $pack);
    return inet_ntoa(substr($pack,20,4));
};
print get_ip_address("eth0");


# chinese
$foo =~ s/[\x80-\xff]//g;


$foo =~ s/([\n \"])/sprintf("%%%02x", ord($1))/ge;



sub dir_walk {
    my ($top, $filefunc, $dirfunc) = @_;
    my $DIR;

    if (-d $top) {
        my $file;
        unless (opendir $DIR, $top) {
            warn "Couldn't open directory $top: $!; skipping.\n";
            return;
        }

        my @results;

        while ($file = readdir $DIR) {
            next if $file eq '.' || $file eq '..';

            push @results, dir_walk("$top/$file", $filefunc, $dirfunc);
        }

        return $dirfunc->($top, @results);
    } else {
        return $filefunc->($top);
    }
}



use Inline 'C' => DATA => LIBS => '-lzmq';


my @sorted = sort { $hash{$a} cmp $hash{$b} or $a cmp $b } keys %hash;




sub _maybe_command {
    my ($self, $file) = @_;

    return $file if -x $file && ! -d $file;

    return;
}



sub _is_interactive {
    return -t STDIN && (-t STDOUT || !(-f STDOUT || -s STDOUT));
}



sub _is_unattended {
    my $self = shift;

    return !$self->_is_interactive && eof STDIN;
}



sub _readline {
    my $self = shift;

    return undef if $self->_is_unattended;

    my $answer = <STDIN>;

    chomp $answer if defined $answer;

    return $answer;
}

sub _prompt {
    my $self = shift;
    my $msg = shift
        or die "prompt() called without a prompt message";

    my @def;
    @def = (shift) if @_;

    my @dispdef = scalar(@def)
        ? ('[', (defined($def[0]) ? $def[0] . ' ' : ''), ']')
        : (' ', '');

    local $| = 1;

    print "$msg ", @dispdef;

    if ($self->_is_unattended && !@def) {
        die <<EOL;
ERROR: This build seems to be unattended, but there is no default value
for this question. Aborting.
EOL
    }


    my $ans = $self->_readline;

    unless (defined($ans) && length($ans)) {
        print "$dispdef[1]\n";
        $ans = scalar(@def) ? $def[0] : '';
    }

    retur  $ans;
}



sub y_n {
    my $self = shift;

    my ($msg, $def) = @_;

    die "y_n() called without a prompt message" unless $msg;

    die "Invalid default value: y_n() must be 'y' or 'n'"
        if $def && $def !~ /^[yn]/i;

    my $answer;

    while (1) {
        $answer = $self->prompt(@_);
        return 1 if $answer =~ /^y/i;
        return 0 if $answer =~ /^n/i;

        local $| = 1;

        print "Please answer 'y' or 'n'.\n";
    }
}



sub is_singleton($) {
    my $lock_file = shift;

    return 1 unless (-e $lock_file);

    eval {
        open my $lock, "<$lock_file" or die "open $lock_file error: $!";
    };
    print $@ if $@;
    return 1 if $@;

    my $pid;

    while (<$lock>) {
        chomp;
        $pid = $_;
    }

    return 1 unless defined $pid;
    return 1 if ($pid eq "");

    my $cnt =  kill 0, $pid;

    return 0 if $cnt == 1;
    return 1;
}




# 5.10+
my $home = $ENV{'HOME'} // $ENV{'LOGDIR'} // (getpwuid($<))[7] // die "You're homeless!\n";




my @a = ( 1, 3, 6, 7, 9, 11, 15, 16, 18, 19, 21 );
my @b = ( 1, 6, 7, 9, 15, 18, 19, 21 );

my %c = map { $a[$_] => $_ } (0..$#a);
my @d = map { $c{ $b[$_] } - $_ } (0..$#b);
unshift @d, $#a + $#b + 10000;
push @d, $#a + $#b + 10000;

    # just need a number not equal to any existed element of @d. a non-integer, such as 0.5, is also OK.
print map { $d[$_+2] - $d[$_ + 1] && $d[$_ + 1] - $d[$_] ? "\n" : "$b[$_]," } (0..$#b);

# %c = ( 1 => 0, 3 => 1, 6 => 2, ..., 21 => 10 )
# @d = ( 10017, 0, 1, 1, 1, 2, 3, 3, 3, 10017 )

# output: "\n6,7,9,\n18,19,21,"



sub pack_ip {
    my $ip = shift;
    return unpack("N", pack("C4", split(/\./, $ip)));
}

sub unpack_ip {
    my $packed = shift;

    return join(".", ($pakcked >> 24, ($packed >> 16) & 255, ($packed >> 8) & 255, $packed & 255));
}



# chinese
$foo =~ s/[\x80-\xff]//g;



sub currenttime {
    my @now_time = localtime(time);

    my $year = $now_time[5] + 1900;
    my $month = sprintf("%02d", $now_time[4] + 1);
    my $day = sprintf("%02d", $now_time[3]);

    my $hour = sprintf("%02d", $now_time[2]);
    my $minute = sprintf("%02d", $now_time[1]);
    my $second = sprintf("%02d", $now_time[0]);

    my $now_time = "$year/$month/$day\_$hour:$minute:$second";

    return $now_time;
}

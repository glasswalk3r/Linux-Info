package Linux::Info::SysInfo::CPU::S390;
use strict;
use warnings;
use Carp qw(confess);
use Class::XSAccessor getters => {
    get_threads   => 'threads',
    get_frequency => 'frequency',
    get_cache     => 'cache'
};

use parent 'Linux::Info::SysInfo::CPU';

# VERSION

# ABSTRACT: Collects s390 based CPU information from /proc/cpuinfo

# vendor_id       : IBM/S390
my $vendor_regex = qr/^vendor_id\s+\:\s(.*)/;

sub processor_regex {
    return $vendor_regex;
}

sub _set_proc_bits {
    my $self = shift;

    if ( $self->has_flag('64bit') ) {
        $self->{architecture} = 64;
    }
    else {
        $self->{architecture} = 32;
    }
}

sub _set_hyperthread {
    my $self = shift;

    if ( $self->{threads} > 0 ) {
        $self->{multithread} = 1;
    }
    else {
        $self->{multithread} = 0;
    }
}

sub has_multithread {
    return shift->{multithread};
}

sub get_cores {
    return 0;
}

sub _custom_attribs {
    my $self = shift;
    $self->{multithread} = 0;
    $self->{cores}       = 0;
    $self->{threads}     = 0;
    $self->{facilities}  = Set::Tiny->new;
    $self->{frequency}   = undef;
    $self->{cache}       = undef;
}

sub _parse_facilities {
    my $self  = shift;
    my $value = $self->_parse_list;
    $self->{facilities}->insert( split( /\s/, $value ) );
    $self->{line} = undef;
}

sub get_facilities {
    my $self       = shift;
    my @facilities = sort { $a <=> $b } $self->{facilities}->members;
    return \@facilities;
}

# cache0 : level=1 type=Data scope=Private size=128K line_size=256 associativity=8
# cache1 : level=1 type=Instruction scope=Private size=96K line_size=256 associativity=6
# cache2 : level=2 type=Data scope=Private size=2048K line_size=256 associativity=8
# cache3 : level=2 type=Instruction scope=Private size=2048K line_size=256 associativity=8
# cache4 : level=3 type=Unified scope=Shared size=65536K line_size=256 associativity=16
# cache5 : level=4 type=Unified scope=Shared size=491520K line_size=256 associativity=30

sub _parse_cache {
    my ( $self, $line ) = @_;
    $self->{cache} = {} unless ( defined $self->{cache} );
    my @line       = split( /\s\:\s/, $line );
    my $cache_name = $line[0];
    my @values     = split( /\s/, $line[1] );
    $self->{cache}->{$cache_name} = {};

    foreach my $attribute (@values) {
        my ( $k, $v ) = split( '=', $attribute );
        $self->{cache}->{$cache_name}->{$k} = $v;
    }
}

sub _parse {
    my $self = shift;
    my $file = $self->{source_file};

    # bogomips per cpu: 3033.00
    my $bogo_regex = qr/^bogomips\sper\scpu\:\s(\d+\.\d+)/;

# features : esan3 zarch stfle msa ldisp eimm dfp edat etf3eh highgprs te vx sie
    my $flags_regex = qr/^features\s\:\s(.*)/;

    # processors    : 4
    my $processors_regex = qr/^processors\s+\:\s(\d+)/;

    # cpu MHz static : 5000
    my $cpu_mhz_regex = qr/^cpu\sMHz\sstatic\s\:\s(\d+)/;

    # max thread id : 0
    my $threads_regex = qr/^max\sthread\sid\s:\s(\d+)/;

    # cpu MHz static : 5000
    my $frequency_regex = qr/^cpu\s(\wHz)\sstatic\s\:\s(\d+)/;

    # facilities : 0 1 2 3 4
    my $facilities_regex = qr/^facilities\s\:\s/;
    my $cache_regex      = qr/cache\d\s\:\slevel/;

    # processor 0: version = FF, identification = 0133E8, machine = 2964
    my $model_regex  = qr/^processor\s\d\:\s(.*)/;
    my $flags_parsed = 0;
    open( my $fh, '<', $file ) or confess "Cannot read $file: $!";

  LINE: while ( my $line = <$fh> ) {
        chomp($line);
        next LINE if ( $line eq '' );

        if ( $line =~ $model_regex ) {
            next LINE if ( defined $self->{model} );
            $self->{model} = $1;
            $self->{model} =~ tr/=//d;
            $self->{model} =~ s/\s{2,}/ /g;
            next LINE;
        }

        if ( $line =~ $cache_regex ) {
            $self->_parse_cache($line);
        }

        if ( $line =~ $flags_regex ) {
            next LINE if ($flags_parsed);
            $self->_parse_flags($line);
            $flags_parsed = 1;
        }

        if ( $line =~ $vendor_regex ) {
            $self->{vendor} = $1;
            next LINE;
        }

        if ( $line =~ $bogo_regex ) {
            $self->{bogomips} = $1 + 0;
            next LINE;
        }

        if ( $line =~ $processors_regex ) {
            $self->{processors} = $1;
            next LINE;
        }

        if ( $line =~ $threads_regex ) {
            $self->{threads} = $1;
            next LINE;
        }

        if ( $line =~ $facilities_regex ) {
            $self->{line} = $line;
            $self->_parse_facilities;
            next LINE;
        }

        if ( $line =~ $frequency_regex ) {
            $self->{frequency} = "$2 $1";
            last LINE;
        }
    }

    close($fh);
}

1;

package Linux::Info::SysInfo::CPU::Intel;
use strict;
use warnings;
use Carp qw(confess);
use Set::Tiny 0.04;
use Class::XSAccessor
  getters => {
    get_cores   => 'cores',
    get_threads => 'threads',
    get_bugs    => 'bugs',
  },
  exists_predicates => { has_multithread => 'multithread', };

use parent 'Linux::Info::SysInfo::CPU';

# VERSION

# ABSTRACT: Collects Intel based CPU information from /proc/cpuinfo

# vendor_id       : GenuineIntel
my $vendor_regex = qr/^vendor_id\s+\:\s(\w+)/;

sub processor_regex {
    return $vendor_regex;
}

sub _custom_attribs {
    my $self = shift;
    $self->{multithread} = 0;
    $self->{cores}       = 0;
    $self->{threads}     = 0;
    $self->{bugs}        = Set::Tiny->new;
}

sub _parse {
    my $self = shift;
    my $file = $self->{source_file};

    # model name      : Intel(R) Core(TM) i5-4300M CPU @ 2.60GHz
    my $model_regex     = qr/^model\sname\s+\:\s(.*)/;
    my $processor_regex = qr/^physical\s+id\s*:\s*(\d+)/;
    my $core_regex      = qr/^core\s+id\s*:\s*(\d+)/;
    my $thread_regex    = qr/^processor\s*:\s*\d+/;
    my $flags_regex     = qr/^flags\s+\:/;

    # bogomips        : 4784.43
    my $bogo_regex = qr/^bogomips\s+\:\s(\d+\.\d+)/;

    # bugs            : apic_c1e spectre_v1 spectre_v2 spec_store_bypass
    my $bugs_regex = qr/^bugs\s+\:\s/;
    my %processors;
    my $threads       = 0;
    my $flags_defined = 0;
    my $bugs_defined  = 0;
    my $phyid;
    open( my $fh, '<', $file ) or confess "Cannot read $file: $!";

  LINE: while ( my $line = <$fh> ) {
        chomp($line);

        if ( $line =~ $model_regex ) {
            $self->{model} = $1;
            next LINE;
        }

        if ( $line =~ $bogo_regex ) {
            $self->{bogomips} = $1;
            next LINE;
        }

        if ( $line =~ $vendor_regex ) {
            $self->{vendor} = $1;
            next LINE;
        }

        if ( $line =~ $processor_regex ) {

            # in order for this to work, it is expected that the physical line
            # comes first than the core
            $phyid = $1;
            $processors{$phyid}->{count}++;
            next LINE;
        }

        if ( $line =~ $core_regex ) {
            $processors{$phyid}->{cores}{$1}++;
            next LINE;
        }

        if ( $line =~ $thread_regex ) {
            $threads++;
            next LINE;
        }

        if ( $line =~ $bugs_regex ) {
            next LINE if ($bugs_defined);
            $self->_parse_bugs($line);
            $bugs_defined = 1;
        }

        if ( $line =~ $flags_regex ) {
            next LINE if ($flags_defined);
            $self->_parse_flags($line);
            $flags_defined = 1;
        }
    }

    close($fh);

    if ( ( scalar( keys %processors ) == 0 ) and ( $threads == 1 ) ) {
        $self->{processors} = 1;
        $self->{cores}      = 0;
        $self->{threads}    = 0;
    }
    else {
        $self->{processors} = scalar( keys(%processors) );
        $self->{cores}      = $processors{0}->{cores}->{0};
        $self->{threads}    = $threads;
    }

}

sub _set_proc_bits {
    my $self = shift;

    if ( $self->has_flag('lm') ) {
        $self->{architecture} = 64;
    }
    else {
        $self->{architecture} = 32;
    }
}

sub _set_hyperthread {
    my $self = shift;

    if ( $self->has_flag('ht') ) {
        $self->{multithread} = 1;
    }
    else {
        $self->{multithread} = 0;
    }
}

sub new {
    my $class = shift;
    my $self  = $class->SUPER::new(@_);

}

1;

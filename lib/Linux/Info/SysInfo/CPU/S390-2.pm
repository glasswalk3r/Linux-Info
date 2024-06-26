package Linux::Info::SysInfo::CPU::S390;
use strict;
use warnings;
use Carp qw(confess);
use Class::XSAccessor getters => {
    get_threads   => 'threads',
    get_frequency => 'frequency',
    get_cache     => 'cache'
};
use List::Util qw(first);

use base 'Linux::Info::SysInfo::CPU';

# VERSION

# ABSTRACT: Collects s390 based CPU information from /proc/cpuinfo

=head1 SYNOPSIS

See L<Linux::Info::SysInfo> C<get_cpu> method.

=head1 DESCRIPTION

This is a subclass of L<Linux::Info::SysInfo::CPU>, with specific code to parse
the IBM s390 processor format of L</proc/cpuinfo>.

=head1 METHODS

=head2 processor_regex

Returns a regular expression that identifies the processor that is being read.

=cut

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

=head2 has_multithread

Returns "true" (1) or "false" (0) if the CPU has multithreading.

=cut

sub has_multithread {
    return shift->{multithread};
}

=head2 get_cores

Returns an integer of the number of cores available in the CPU.

=cut

sub get_cores {
    return 0;
}

=head2 get_threads

Returns an integer of the number of threads available per core in the CPU.

=head2 get_frequency

Returns a string with the maximum value of frequency of the CPU.

=head2 get_cache

Returns a hash reference.

Each key is the name of a cache, and the value is also a hash reference with
the attributes of each cache.

=head2 get_facilities

Returns an array reference with the list of the facilities the processor has.

=cut

sub get_facilities {
    my $self       = shift;
    my @facilities = sort { $a <=> $b } $self->{facilities}->members;
    return \@facilities;
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

    foreach my $line (<$fh>) {
        chomp($line);
        next if $line eq '';

        # Define an array of conditions and actions
        my @conditions = (
            {
                regex  => $serial_regex,
                action => sub { $self->{serial} ||= $1 }
            },
            {
                regex  => $hardware_regex,
                action => sub { $self->{hardware} ||= $1 }
            },
        );

        # Find the first condition that matches
        my $match =
          first { $line =~ $_->{regex} && !defined $self->{ $_->{field} } }
          @conditions;

        if ($match) {
            $match->{action}->();    # Execute the corresponding action
        }
    }
}

1;

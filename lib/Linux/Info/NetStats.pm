package Linux::Info::NetStats;
use strict;
use warnings;
use Carp qw(croak);
use Time::HiRes 1.9725;
use YAML::XS 0.88;

# VERSION

=head1 NAME

Linux::Info::NetStats - Collect linux net statistics.

=head1 SYNOPSIS

    use Linux::Info::NetStats;

    my $lxs = Linux::Info::NetStats->new;
    $lxs->init;
    sleep 1;
    my $stat = $lxs->get;

Or

    my $lxs = Linux::Info::NetStats->new(initfile => $file);
    $lxs->init;
    my $stat = $lxs->get;

=head1 DESCRIPTION

Linux::Info::NetStats gathers net statistics from the virtual F</proc> filesystem (procfs).

For more information read the documentation of the front-end module L<Linux::Info>.

=head1 NET STATISTICS

Generated by F</proc/net/dev>.

    rxbyt    -  Number of bytes received per second.
    rxpcks   -  Number of packets received per second.
    rxerrs   -  Number of errors that happend while received packets per second.
    rxdrop   -  Number of packets that were dropped per second.
    rxfifo   -  Number of FIFO overruns that happend on received packets per second.
    rxframe  -  Number of carrier errors that happend on received packets per second.
    rxcompr  -  Number of compressed packets received per second.
    rxmulti  -  Number of multicast packets received per second.
    txbyt    -  Number of bytes transmitted per second.
    txpcks   -  Number of packets transmitted per second.
    txerrs   -  Number of errors that happend while transmitting packets per second.
    txdrop   -  Number of packets that were dropped per second.
    txfifo   -  Number of FIFO overruns that happend on transmitted packets per second.
    txcolls  -  Number of collisions that were detected per second.
    txcarr   -  Number of carrier errors that happend on transmitted packets per second.
    txcompr  -  Number of compressed packets transmitted per second.
    ttpcks   -  Number of total packets (received + transmitted) per second.
    ttbyt    -  Number of total bytes (received + transmitted) per second.

=head1 METHODS

=head2 new()

Call C<new()> to create a new object.

    my $lxs = Linux::Info::NetStats->new;

Maybe you want to store/load the initial statistics to/from a file:

    my $lxs = Linux::Info::NetStats->new(initfile => '/tmp/netstats.yml');

If you set C<initfile> it's not necessary to call sleep before C<get()>.

It's also possible to set the path to the proc filesystem.

     Linux::Info::NetStats->new(
        files => {
            # This is the default
            path   => '/proc',
            netdev => 'net/dev',
        }
    );

=head2 init()

Call C<init()> to initialize the statistics.

    $lxs->init;

=head2 get()

Call C<get()> to get the statistics. C<get()> returns the statistics as a hash reference.

    my $stat = $lxs->get;

=head2 raw()

The same as get_raw() but it's not necessary to call init() first.

=head2 get_raw()

Call C<get_raw()> to get the raw data - no deltas.

=head1 EXPORTS

Nothing.

=head1 SEE ALSO

=over

=item *

B<proc(5)>

=item *

L<Linux::Info>

=back

=head1 AUTHOR

Alceu Rodrigues de Freitas Junior, E<lt>glasswalk3r@yahoo.com.brE<gt>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2015 of Alceu Rodrigues de Freitas Junior, E<lt>glasswalk3r@yahoo.com.brE<gt>

This file is part of Linux Info project.

Linux-Info is free software: you can redistribute it and/or modify
it under the terms of the GNU General Public License as published by
the Free Software Foundation, either version 3 of the License, or
(at your option) any later version.

Linux-Info is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
GNU General Public License for more details.

You should have received a copy of the GNU General Public License
along with Linux Info.  If not, see <http://www.gnu.org/licenses/>.

=cut

sub new {
    my $class = shift;
    my $opts  = ref( $_[0] ) ? shift : {@_};

    my %self = (
        files => {
            path   => '/proc',
            netdev => 'net/dev',
        }
    );

    if ( defined $opts->{initfile} ) {
        $self{initfile} = $opts->{initfile};
    }

    foreach my $file ( keys %{ $opts->{files} } ) {
        $self{files}{$file} = $opts->{files}->{$file};
    }

    return bless \%self, $class;
}

sub init {
    my $self = shift;

    if ( $self->{initfile} && -r $self->{initfile} ) {
        $self->{init} = YAML::XS::LoadFile( $self->{initfile} );
        $self->{time} = delete $self->{init}->{time};
    }
    else {
        $self->{time} = Time::HiRes::gettimeofday();
        $self->{init} = $self->_load;
    }
}

sub get {
    my $self  = shift;
    my $class = ref $self;

    if ( !exists $self->{init} ) {
        croak "$class: there are no initial statistics defined";
    }

    $self->{stats} = $self->_load;
    $self->_deltas;

    if ( $self->{initfile} ) {
        $self->{init}->{time} = $self->{time};
        YAML::XS::DumpFile( $self->{initfile}, $self->{init} );
    }

    return $self->{stats};
}

sub raw {
    my $self = shift;
    my $stat = $self->_load;

    return $stat;
}

sub get_raw {
    my $self = shift;
    my %raw  = %{ $self->{init} };
    delete $raw{time};
    return \%raw;
}

#
# private stuff
#

sub _load {
    my $self  = shift;
    my $class = ref $self;
    my $file  = $self->{files};
    my %stats = ();

    my $filename =
      $file->{path} ? "$file->{path}/$file->{netdev}" : $file->{netdev};
    open my $fh, '<', $filename
      or croak "$class: unable to open $filename ($!)";

    while ( my $line = <$fh> ) {
        next unless $line =~ /^\s*(.+?):\s*(.*)/;
        @{ $stats{$1} }{
            qw(
              rxbyt rxpcks rxerrs rxdrop rxfifo rxframe rxcompr rxmulti
              txbyt txpcks txerrs txdrop txfifo txcolls txcarr txcompr
            )
        } = split /\s+/, $2;
        $stats{$1}{ttbyt}  = $stats{$1}{rxbyt} + $stats{$1}{txbyt};
        $stats{$1}{ttpcks} = $stats{$1}{rxpcks} + $stats{$1}{txpcks};
    }

    close($fh);
    return \%stats;
}

sub _deltas {
    my $self  = shift;
    my $class = ref $self;
    my $istat = $self->{init};
    my $lstat = $self->{stats};
    my $time  = Time::HiRes::gettimeofday();
    my $delta = sprintf( '%.2f', $time - $self->{time} );
    $self->{time} = $time;

    foreach my $dev ( keys %{$lstat} ) {
        if ( !exists $istat->{$dev} ) {
            delete $lstat->{$dev};
            next;
        }

        my $idev = $istat->{$dev};
        my $ldev = $lstat->{$dev};

        while ( my ( $k, $v ) = each %{$ldev} ) {
            if ( !defined $idev->{$k} ) {
                croak "$class: not defined key found '$k'";
            }

            if ( $v !~ /^\d+\z/ || $ldev->{$k} !~ /^\d+\z/ ) {
                croak "$class: invalid value for key '$k'";
            }

            if ( $ldev->{$k} == $idev->{$k} || $idev->{$k} > $ldev->{$k} ) {
                $ldev->{$k} = sprintf( '%.2f', 0 );
            }
            elsif ( $delta > 0 ) {
                $ldev->{$k} =
                  sprintf( '%.2f', ( $ldev->{$k} - $idev->{$k} ) / $delta );
            }
            else {
                $ldev->{$k} = sprintf( '%.2f', $ldev->{$k} - $idev->{$k} );
            }

            $idev->{$k} = $v;
        }
    }
}

1;

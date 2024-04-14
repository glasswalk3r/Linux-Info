package Linux::Info::CpuStats;
use strict;
use warnings;
use Carp qw(croak);
use YAML::XS 0.41;

# VERSION

=head1 NAME

Linux::Info::CpuStats - Collect linux cpu statistics.

=head1 SYNOPSIS

    use Linux::Info::CpuStats;

    my $lxs = Linux::Info::CpuStats->new;
    $lxs->init;
    sleep 1;
    my $stats = $lxs->get;

Or

    my $lxs = Linux::Info::CpuStats->new(initfile => $file);
    $lxs->init;
    my $stats = $lxs->get;

=head1 DESCRIPTION

Linux::Info::CpuStats gathers cpu statistics from the virtual
F</proc> filesystem (procfs).

For more information read the documentation of the front-end module
L<Linux::Info>.

=head1 CPU STATISTICS

Generated by F</proc/stat> for each cpu (cpu0, cpu1 ...). F<cpu> without
a number is the summary.

    user    -  Percentage of CPU utilization at the user level.
    nice    -  Percentage of CPU utilization at the user level with nice priority.
    system  -  Percentage of CPU utilization at the system level.
    idle    -  Percentage of time the CPU is in idle state.
    total   -  Total percentage of CPU utilization.

Statistics with kernels >= 2.6.

    iowait  -  Percentage of time the CPU is in idle state because an I/O operation
               is waiting to complete.
    irq     -  Percentage of time the CPU is servicing interrupts.
    softirq -  Percentage of time the CPU is servicing softirqs.
    steal   -  Percentage of stolen CPU time, which is the time spent in other
               operating systems when running in a virtualized environment (>=2.6.11).

=head1 METHODS

=head2 new()

Call C<new()> to create a new object.

    my $lxs = Linux::Info::CpuStats->new;

Maybe you want to store/load the initial statistics to/from a file:

    my $lxs = Linux::Info::CpuStats->new(initfile => '/tmp/cpustats.yml');

If you set C<initfile> it's not necessary to call sleep before C<get()>.

It's also possible to set the path to the proc filesystem.

     Linux::Info::CpuStats->new(
        files => {
            # This is the default
            path => '/proc'
            stat => 'stat',
        }
    );

=head2 init()

Call C<init()> to initialize the statistics.

    $lxs->init;

=head2 get()

Call C<get()> to get the statistics. C<get()> returns the statistics as a hash reference.

    my $stats = $lxs->get;

=head2 raw()

Get raw values.

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
            path => '/proc',
            stat => 'stat',
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

sub raw {
    my $self = shift;
    my $stat = $self->_load;
    return $stat;
}

sub init {
    my $self = shift;

    if ( $self->{initfile} && -r $self->{initfile} ) {
        $self->{init} = YAML::XS::LoadFile( $self->{initfile} );
    }
    else {
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
        YAML::XS::DumpFile( $self->{initfile}, $self->{init} );
    }

    return $self->{stats};
}

#
# private stuff
#

sub _load {
    my $self  = shift;
    my $class = ref $self;
    my $file  = $self->{files};
    my ( %stats, $iowait, $irq, $softirq, $steal );

    my $filename =
      $file->{path} ? "$file->{path}/$file->{stat}" : $file->{stat};
    open my $fh, '<', $filename
      or croak "$class: unable to open $filename ($!)";

    while ( my $line = <$fh> ) {
        if ( $line =~ /^(cpu.*?)\s+(.*)$/ ) {
            my $cpu = \%{ $stats{$1} };
            (
                @{$cpu}{qw(user nice system idle)},
                $iowait, $irq, $softirq, $steal
            ) = split /\s+/, $2;

            # iowait, irq and softirq are only set
            # by kernel versions higher than 2.4.
            # steal is available since 2.6.11.
            $cpu->{iowait}  = $iowait  if defined $iowait;
            $cpu->{irq}     = $irq     if defined $irq;
            $cpu->{softirq} = $softirq if defined $softirq;
            $cpu->{steal}   = $steal   if defined $steal;
        }
    }

    close($fh);
    return \%stats;
}

sub _deltas {
    my $self  = shift;
    my $class = ref $self;
    my $istat = $self->{init};
    my $lstat = $self->{stats};

    foreach my $cpu ( keys %{$lstat} ) {
        my $icpu = $istat->{$cpu};
        my $dcpu = $lstat->{$cpu};
        my $uptime;

        while ( my ( $k, $v ) = each %{$dcpu} ) {
            if ( !defined $icpu->{$k} ) {
                croak "$class: not defined key found '$k'";
            }

            if ( $v !~ /^\d+\z/ || $dcpu->{$k} !~ /^\d+\z/ ) {
                croak "$class: invalid value for key '$k'";
            }

            $dcpu->{$k} -= $icpu->{$k};
            $icpu->{$k} = $v;
            $uptime += $dcpu->{$k};
        }

        foreach my $k ( keys %{$dcpu} ) {
            if ( $dcpu->{$k} > 0 ) {
                $dcpu->{$k} = sprintf( '%.2f', 100 * $dcpu->{$k} / $uptime );
            }
            elsif ( $dcpu->{$k} < 0 ) {
                $dcpu->{$k} = sprintf( '%.2f', 0 );
            }
            else {
                $dcpu->{$k} = sprintf( '%.2f', $dcpu->{$k} );
            }
        }

        $dcpu->{total} = sprintf( '%.2f', 100 - $dcpu->{idle} );
    }
}

1;

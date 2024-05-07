package Linux::Info::DiskStats;
use strict;
use warnings;
use Carp qw(confess carp);
use Time::HiRes 1.9764;
use YAML::XS 0.88;
use Hash::Util qw(lock_keys);

use Linux::Info::SysInfo;
use Linux::Info::KernelRelease;

# VERSION

use constant SPACES_REGEX => qr/\s+/;

=head1 NAME

Linux::Info::DiskStats - Collect Linux disks statistics.

=head1 SYNOPSIS

    use Linux::Info::DiskStats;

    my $config = Linux::Info::DiskStats::Options->new({backwards_compatibility => 0});
    my $lxs = Linux::Info::DiskStats->new($config);
    $lxs->init;
    sleep 1;
    my $stat = $lxs->get;

Or

    my $config = Linux::Info::DiskStats::Options->new({backwards_compatibility => 1,
                                                       global_block_size => 4096});
    my $lxs = Linux::Info::DiskStats->new($config);
    $lxs->init;
    my $stat = $lxs->get;

=head1 DESCRIPTION

C<Linux::Info::DiskStats> gathers disk statistics from the virtual F</proc>
filesystem (procfs).

For more information read the documentation of the front-end module
L<Linux::Info>.

=head1 DISK STATISTICS

The disk statics will depend on the kernel version that is running in the host.
See the L<Linux::Info::DiskStats/"SEE ALSO"> section for more details on that.

Also, this module produces two types of statistics:

=over

=item *

Backwards compatible with C<Linux::Info> versions 1.5 and lower.

=item *

New fields since version 1.6 and higher. These fields are also incompatible
with those produced by L<Sys::Statistics::Linux>.

=back

=head2 Backwards compatible fields

Those fields are generated from F</proc/diskstats> or F</proc/partitions>,
depending on the kernel version.

Not necessarily those fields will have a direct correlation with the fields
on the F</proc> directory, some of them are basically calculations and
others are not even statistics (C<major> and C<minor>).

These fields are kept only to provide compatibility, but it is
B<highly recommended> to not use compatibility mode since some statistics won't
be exposed and you can always execute the calculations yourself with that set.

=over

=item *

major: The mayor number of the disk

=item *

minor: The minor number of the disk

=item *

rdreq: Number of read requests that were made to physical disk per second.

=item *

rdbyt: Number of bytes that were read from physical disk per second.

=item *

wrtreq: Number of write requests that were made to physical disk per second.

=item *

wrtbyt: Number of bytes that were written to physical disk per second.

=item *

ttreq: Total number of requests were made from/to physical disk per second.

=item *

ttbyt: Total number of bytes transmitted from/to physical disk per second.

=back

=head2 The "new" fields

Actually, those fields are not really new: they are the almost exact
representation of those available on the respective F</proc> file, with small
differences in the fields naming in this module in order to make it easier to
type in.

These are the fields you want to use, if possible. It is also possible to have
the calculated fields by using the module
L<Linux::Info::DiskStats::Calculated>.

=cut

sub _block_size {
    my ( $self, $device_name ) = @_;

    return $self->{global_block_size}
      if ( defined $self->{global_block_size} );

    if ( defined $self->{block_sizes} ) {
        if ( exists $self->{block_sizes}->{$device_name} ) {
            return $self->{block_sizes}->{$device_name};
        }
        else {
            confess
              "There is no configured block size for the device $device_name!";
        }
    }
    else {
        confess 'No block size available!';
    }
}

sub _shift_fields {
    my $fields_ref = shift;
    confess 'Must receive an array reference as parameter'
      unless ( ( defined($fields_ref) ) and ( ref $fields_ref eq 'ARRAY' ) );
    shift( @{$fields_ref} );    # nothing, really
    my %non_stats;
    $non_stats{major}       = shift( @{$fields_ref} );
    $non_stats{minor}       = shift( @{$fields_ref} );
    $non_stats{device_name} = shift( @{$fields_ref} );
    return \%non_stats;
}

sub _backwards_fields {
    my ( $size, $non_stats_ref, $stats_ref, $fields_ref ) = @_;
    my $device_name = $non_stats_ref->{device_name};

    $stats_ref->{$device_name} = {
        major  => $non_stats_ref->{major},
        minor  => $non_stats_ref->{minor},
        rdreq  => $fields_ref->[4],
        rdbyt  => ( $fields_ref->[5] * $size ),
        wrtreq => $fields_ref->[6],
        wrtbyt => ( $fields_ref->[7] * $size ),
        ttreq  => ( $fields_ref->[4] + $fields_ref->[6] ),
    };

    $stats_ref->{$device_name}->{ttbyt} =
      $stats_ref->{$device_name}->{rdbyt} +
      $stats_ref->{$device_name}->{wrtbyt};
}

sub _parse_ssd {
    my $self        = shift;
    my $source_file = $self->{source_file};

    open my $fh, '<', $source_file or confess "Cannot read $source_file: $!";
    my %stats;

    while ( my $line = <$fh> ) {
        chomp $line;
        my @fields           = split( SPACES_REGEX, $line );
        my $available_fields = scalar(@fields);

        if (    ( $self->{fields} > 0 )
            and ( $self->{fields} != $available_fields ) )
        {
            carp 'Inconsistent number of fields, had '
              . $self->{fields}
              . ", now have $available_fields";
        }

        $self->{fields} = $available_fields;
        my $non_stats_ref = _shift_fields( \@fields );

        if ( $self->{backwards_compatible} ) {
            _backwards_fields(
                $self->_block_size( $non_stats_ref->{device_name} ),
                $non_stats_ref, \%stats, \@fields );
        }
        else {
            my @name_position = (
                'read_completed',   'read_merged',
                'sectors_read',     'read_time',
                'write_completed',  'write_merged',
                'sectors_written',  'write_time',
                'io_in_progress',   'io_time',
                'weighted_io_time', 'discards_completed',
                'discards_merged',  'sectors_discarded',
                'discard_time',     'flush_completed',
                'flush_time'
            );

            my $field_counter = 0;
            for my $field_name (@name_position) {
                $stats{ $non_stats_ref->{device_name} }->{$field_name} =
                  $fields[$field_counter];
                $field_counter++;
            }
        }
    }

    close($fh) or confess "Cannot close $source_file: $!";
    confess "Failed to fetch statistics from $source_file"
      unless ( ( scalar( keys(%stats) ) ) > 0 );
    return \%stats;
}

sub _parse_disk_stats {
    my $self        = shift;
    my $source_file = $self->{source_file};

    open my $fh, '<', $source_file or confess "Cannot read $source_file: $!";
    my %stats;

    while ( my $line = <$fh> ) {
        chomp $line;
        my @fields           = split( SPACES_REGEX, $line );
        my $available_fields = scalar(@fields);

        if (    ( $self->{fields} > 0 )
            and ( $self->{fields} != $available_fields ) )
        {
            carp 'Inconsistent number of fields, had '
              . $self->{fields}
              . ", now have $available_fields";
        }

        $self->{fields} = $available_fields;
        my $non_stats_ref = _shift_fields( \@fields );

        if ( $self->{backwards_compatible} ) {
            _backwards_fields(
                $self->_block_size( $non_stats_ref->{device_name} ),
                $non_stats_ref, \%stats, \@fields );
        }
        else {
            # 4 - reads completed successfully
            # 5 - reads merged
            # 6 - sectors read
            # 7 - time spent reading (ms)
            # 8 - writes completed
            # 9 - writes merged
            # 10 - sectors written
            # 11 - time spent writing (ms)
            # 12 - I/Os currently in progress
            # 13 - time spent doing I/Os (ms)
            # 14 - weighted time spent doing I/Os (ms)
            my @name_position = (
                'read_completed',  'read_merged',
                'sectors_read',    'read_time',
                'write_completed', 'write_merged',
                'sectors_written', 'write_time',
                'io_in_progress',  'io_time',
                'weighted_io_time',
            );

            my $field_counter = 0;
            for my $field_name (@name_position) {
                $stats{ $non_stats_ref->{device_name} }->{$field_name} =
                  $fields[$field_counter];
                $field_counter++;
            }
        }
    }

    close($fh) or confess "Cannot close $source_file: $!";
    confess "Failed to fetch statistics from $source_file"
      unless ( ( scalar( keys(%stats) ) ) > 0 );
    return \%stats;
}

sub _parse_partitions {

}

=head1 METHODS

=head2 new

Call C<new> to create a new object.

    my $lxs = Linux::Info::DiskStats->new($opts);

Where C<$opts> is a L<Linux::Info::DiskStats::Options>.

=cut

sub new {
    my ( $class, $opts ) = @_;
    my $config_class = 'Linux::Info::DiskStats::Options';
    confess "Must receive as parameter a instance of $config_class"
      unless ( ( ref $opts ne '' ) and ( $opts->isa($config_class) ) );

    my $self = {
        fields      => 0,
        time        => undef,
        source_file => undef,
        init        => undef,
        stats       => undef,
    };

    if ( defined( $opts->get_current_kernel ) ) {
        $self->{current} = $opts->get_current_kernel;
    }
    else {
        $self->{current} =
          Linux::Info::KernelRelease->new(
            Linux::Info::SysInfo->new->get_release );
    }

    $self->{backwards_compatible} = $opts->get_backwards_compatible;
    warn
'Instance created in backward compatibility, this feature will be deprecated in the future'
      if ( $self->{backwards_compatible} );

    $self->{source_file}       = $opts->get_source_file;
    $self->{init_file}         = $opts->get_init_file;
    $self->{global_block_size} = $opts->get_global_block_size;
    $self->{block_sizes}       = $opts->get_block_sizes;

    unless ( defined $self->{source_file} ) {

        # not a real value, but should be enough accurate
        if ( $self->{current} <
            Linux::Info::KernelRelease->new('2.4.20-0-generic') )
        {
            $self->{source_file}  = '/proc/partitions';
            $self->{parse_method} = \&_parse_partitions;
        }
        else {
            $self->{source_file} = '/proc/diskstats';
        }
    }

    unless ( exists $self->{parse_method} ) {
        if ( $self->{current} >=
            Linux::Info::KernelRelease->new('2.6.18-0-generic') )
        {
            $self->{parse_method} = \&_parse_ssd;
        }
        else {
            $self->{parse_method} = \&_parse_disk_stats;
        }
    }

    bless $self, $class;
    lock_keys( %{$self} );
    return $self;
}

=head2 init

Call C<init> to initialize the statistics.

    $lxs->init;

=cut

sub init {
    my $self = shift;

    # TODO: properly test for not finding the file
    if ( $self->{init_file} && -r $self->{init_file} ) {
        $self->{init}   = YAML::XS::LoadFile( $self->{init_file} );
        $self->{'time'} = delete $self->{init}->{time};
    }
    else {
        $self->{time} = Time::HiRes::gettimeofday();
        $self->{init} = $self->_load;
    }

    return 1;
}

=head2 get

Call C<get> to get the statistics. C<get()> returns the statistics as a hash reference.

    my $stat = $lxs->get;

=cut

sub get {
    my $self  = shift;
    my $class = ref $self;

    confess "$class: there are no initial statistics defined"
      unless ( ( exists $self->{init} ) and ( $self->{init} ) );

    $self->{stats} = $self->_load;
    $self->_deltas if ( $self->{backwards_compatible} );

    if ( $self->{init_file} ) {
        $self->{init}->{time} = $self->{time};
        YAML::XS::DumpFile( $self->{init_file}, $self->{init} );
    }

    return $self->{stats};
}

=head2 raw

Get raw values, retuned as an hash reference.

=cut

sub raw {
    my $self = shift;
    return $self->_load;
}

sub _load {
    my $self = shift;
    $self->{parse_method}($self);

# 2.4 series
# In the Linux kernel version 2.4, the /proc/diskstats file provides statistics for block devices (disks) in the system. The format of this
# file is as follows:
# 1 - major number
# 2 - minor mumber
# 3 - device name
# 4 - reads completed successfully
# 5 - reads merged
# 6 - sectors read
# 7 - time spent reading (ms)
# 8 - writes completed
# 9 - writes merged
# 10 - sectors written
# 11 - time spent writing (ms)
# 12 - I/Os currently in progress
# 13 - time spent doing I/Os (ms)
# 14 - weighted time spent doing I/Os (ms)

 # -----------------------------------------------------------------------------
 # Field  1 -- # of reads issued
 #     This is the total number of reads issued to this partition.
 # Field  2 -- # of sectors read
 #     This is the total number of sectors requested to be read from this
 #     partition.
 # Field  3 -- # of writes issued
 #     This is the total number of writes issued to this partition.
 # Field  4 -- # of sectors written
 #     This is the total number of sectors requested to be written to
 #     this partition.
 # -----------------------------------------------------------------------------
 #                      --      --      --      F1      F2      F3      F4
 #                      $1      $2      $3      $4      $5      $6      $7
 #     elsif ( $line =~
 #         /^\s+(\d+)\s+(\d+)\s+(.+?)\s+(\d+)\s+(\d+)\s+(\d+)\s+(\d+)$/ )
 #     {
 #         for my $x ( $stats{$3} ) {    # $3 -> the device name
 #             $x->{major}  = $1;
 #             $x->{minor}  = $2;
 #             $x->{rdreq}  = $4;            # Field 1
 #             $x->{rdbyt}  = $5 * $bksz;    # Field 2
 #             $x->{wrtreq} = $6;            # Field 3
 #             $x->{wrtbyt} = $7 * $bksz;    # Field 4
 #             $x->{ttreq} += $x->{rdreq} + $x->{wrtreq};
 #             $x->{ttbyt} += $x->{rdbyt} + $x->{wrtbyt};
 #         }
 #     }
 # }

    #     elsif ( open $fh, '<', $self->{source} ) {
    #         while ( my $line = <$fh> ) {

# #                           --      --     --     --      F1     F2     F3     F4     F5     F6     F7     F8    F9    F10   F11
# #                           $1      $2     --     $3      $4     --     $5     --     $6     --     $7     --    --    --    --
#             next
#               unless $line =~
# /^\s+(\d+)\s+(\d+)\s+\d+\s+(.+?)\s+(\d+)\s+\d+\s+(\d+)\s+\d+\s+(\d+)\s+\d+\s+(\d+)\s+\d+\s+\d+\s+\d+\s+\d+$/;
#             for my $x ( $stats{$3} ) {    # $3 -> the device name
#                 $x->{major}  = $1;
#                 $x->{minor}  = $2;
#                 $x->{rdreq}  = $4;            # Field 1
#                 $x->{rdbyt}  = $5 * $bksz;    # Field 3
#                 $x->{wrtreq} = $6;            # Field 5
#                 $x->{wrtbyt} = $7 * $bksz;    # Field 7
#                 $x->{ttreq} += $x->{rdreq} + $x->{wrtreq};
#                 $x->{ttbyt} += $x->{rdbyt} + $x->{wrtbyt};
#             }
#         }
#         close($fh);
#     }

#     if ( !-e $file_diskstats || !scalar %stats ) {
#         confess
# "$class: no diskstats found! your system seems not to be compiled with CONFIG_BLK_STATS=y";
#     }
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
            next if $k =~ /^major\z|^minor\z/;

            if ( !defined $idev->{$k} ) {
                confess "$class: not defined key found '$k'";
            }

            if ( $v !~ /^\d+\z/ || $ldev->{$k} !~ /^\d+\z/ ) {
                confess "$class: invalid value for key '$k'";
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

=head2 fields_read

Returns an integer telling the number of fields process in each line from the
source file.

=cut

sub fields_read() {
    my $self = shift;
    return $self->{fields};
}

=head1 EXPORTS

Nothing.

=head1 SEE ALSO

=over

=item *

L<Linux::Info::DiskStats::Options>

=item *

B<proc(5)>

=item *

https://docs.kernel.org/admin-guide/iostats.html

=item *

L<Linux::Info>

=back

=head1 AUTHOR

Alceu Rodrigues de Freitas Junior, E<lt>glasswalk3r@yahoo.com.brE<gt>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2015 of Alceu Rodrigues de Freitas Junior,
E<lt>glasswalk3r@yahoo.com.brE<gt>

This file is part of Linux Info project.

Linux-Info is free software: you can redistribute it and/or modify
it under the terms of the GNU General Public License as published by
the Free Software Foundation, either version 3 of the License, or
(at your option) any later version.

Linux-Info is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
GNU General Public License for more details.

You should have received a copy of the GNU General Public License
along with Linux Info. If not, see <http://www.gnu.org/licenses/>.

=cut

1;

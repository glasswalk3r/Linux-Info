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

=head1 NAME

Linux::Info::DiskStats - Collect Linux disks statistics.

=head1 SYNOPSIS

    use Linux::Info::DiskStats;

    my $lxs = Linux::Info::DiskStats->new;
    $lxs->init;
    sleep 1;
    my $stat = $lxs->get;

Or

    my $lxs = Linux::Info::DiskStats->new({init_file => $file});
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

=head1 METHODS

=cut

sub _parse_ssd {
    my $self        = shift;
    my $source_file = $self->{source_file};

    open my $fh, '<', $source_file or confess "Cannot read $source_file: $!";
    my %stats;

    while ( my $line = <$fh> ) {
        chomp $line;
        my @fields           = split( $self->{spaces_regex}, $line );
        my $available_fields = scalar(@fields);

        if (    ( $self->{fields} > 0 )
            and ( $self->{fields} != $available_fields ) )
        {
            carp 'Inconsistent number of fields, had '
              . $self->{fields}
              . ", now have $available_fields";
        }

        $self->{fields} = $available_fields;
        shift(@fields);    # nothing, really
        my $major       = shift(@fields);
        my $minor       = shift(@fields);
        my $device_name = shift(@fields);

        # TODO: make this another method, for reusing
        if ( $self->{backwards_compatible} ) {
            $stats{$device_name} = {
                major  => $major,
                minor  => $minor,
                rdreq  => $fields[4],
                rdbyt  => ( $fields[5] * $self->{block_size} ),
                wrtreq => $fields[6],
                wrtbyt => ( $fields[7] * $self->{block_size} ),
                ttreq  => ( $fields[4] + $fields[6] ),
            };

            $stats{$device_name}->{ttbyt} =
              $stats{$device_name}->{rdbyt} + $stats{$device_name}->{wrtbyt};
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
                $stats{$device_name}->{$field_name} = $fields[$field_counter];
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

}

sub _parse_partitions {

}

=head2 new

Call C<new> to create a new object.

    my $lxs = Linux::Info::DiskStats->new($opts);

Where C<$opts> is a hash reference with additional configuration.

The optional keys:

=over

=item *

C<backwards_compatible>: if true (1), the returned statistics will be those
provided by backwards compatibility. Also, it defines that block size
information is required.

If false (0), the new set of fields will be available.

Defaults to true.

=item *

C<source_file>: if provided, that will be the source file were the statistics
will be read from. Otherwise, the default location (based on Linux kernel
version) will be used instead.

=item *

C<init_file>: if set, you may to store/load the initial statistics to/from a
file:

    my $lxs = Linux::Info::DiskStats->new({init_file => '/tmp/diskstats.yml'});

If you set C<init_file> it's not necessary to call C<sleep> before C<get>.

=item *

C<global_block_size>: with an integer as the value, all attached disks will
have calculated statistics based on this value. You may use this if all the
disks are using the same file system type.

It is checked only if C<backwards_compatible> is true.

=item *

C<block_sizes>: if there are different file systems mounted, you will need
to resort to a more complex configuration setting:

    my $opts_ref = {
        block_sizes => {
            deviceA => 512,
            deviceB => 4096,
        }
    };

It is checked only if C<backwards_compatible> is true.

=back

Regarding block sizes, you must choose one key or the other if
C<backwards_compatible> is true. If both are absent, instances will C<die>
during creation by invoking C<new>.

=cut

sub new {
    my $class = shift;

    # TODO: add validations to opts
    my $opts_ref = ref( $_[0] ) ? shift : {@_};
    my $self     = {
        block_size =>
          512,  # TODO: must be defined by reading the superblock of each volume
        fields               => 0,
        spaces_regex         => qr/\s+/,
        backwards_compatible => 0,
        time                 => undef,
        source_file          => undef,
        init                 => undef,
        stats                => undef,
    };

    # required by the _load method
    $self->{current} =
      Linux::Info::KernelRelease->new( Linux::Info::SysInfo->new->get_release );

    if (    ( exists $opts_ref->{backwards_compatible} )
        and ( defined $opts_ref->{backwards_compatible} ) )
    {
        $self->{backwards_compatible} = $opts_ref->{backwards_compatible};
    }
    else {
        $self->{backwards_compatible} = 1;
        warn
'Instance created in backward compatibility, this feature will be deprecated in the future';
    }

    if (    ( exists( $opts_ref->{source_file} ) )
        and ( $opts_ref->{source_file} ) )
    {
        confess 'The file '
          . $opts_ref->{source}
          . ' does not exist or is not readable'
          unless ( -r $opts_ref->{source_file} );

        $self->{source_file} = $opts_ref->{source_file};
    }
    else {

        # not a real value, but should be enough accurated
        my $disk_stats_rel =
          Linux::Info::KernelRelease->new('2.4.20-0-generic');

        $self->{source} =
          ( $self->{current} < $disk_stats_rel )
          ? $self->{source_file} = '/proc/partitions'
          : $self->{source_file} = '/proc/diskstats';
    }

    if ( $opts_ref->{init_file} ) {
        $self->{init_file} = $opts_ref->{init_file};
    }
    else {
        $self->{init_file} = undef;
    }

    if ( $opts_ref->{block_size} ) {
        $self->{block_size} = $opts_ref->{block_size};
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

# private stuff

sub _load {
    my $self = shift;
    return $self->_parse_partitions
      if ( $self->{source_file} eq '/proc/partitions' );

    # not a real value, but should be enough accurate
    return $self->_parse_ssd
      if ( $self->{current} >=
        Linux::Info::KernelRelease->new('2.6.18-0-generic') );

    return $self->_parse_disk_stats;

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

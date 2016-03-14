package Linux::Info::DiskUsage;

use strict;
use warnings;
use Carp qw(croak);
use Set::Tiny 0.01;
use Filesys::Df 0.92;
use Hash::Util 'lock_keys';

=head1 NAME

Linux::Info::DiskUsage - Collect linux disk usage.

=head1 SYNOPSIS

    use Linux::Info::DiskUsage;

    my $lxs  = Linux::Info::DiskUsage->new;
    my $stat = $lxs->get;

=head1 DESCRIPTION

Linux::Info::DiskUsage gathers the disk usage. Previous versions of this module used the C<df> command to retrieve
such information. Since release 0.08, C<df> was deprecated to avoid doing additional syscalls and potencially dangerous
environment variables manipulations. See B<SEE ALSO> section for references about the new implementation.

General output should be the same as generated by C<df>, but output is filtered based on "valid" file systems that are
mounted (to avoid what C<df> defines as "dummy" file systems). See the C<new> and C<default_fs> methods for more details.

For more information read the documentation of the front-end module L<Linux::Info>.

=head1 DISK USAGE INFORMATIONS

=over

=item *

total - The total size of the disk.

=item *

usage - The used disk space in kilobytes.

=item *

free - The free disk space in kilobytes.

=item *

usageper - The used disk space in percent.

=item *

mountpoint - The moint point of the disk.

=back

In the event that the mount point doesn't have some or all this information (for example, AUFS mount points used by Docker), the values will
be automatically assigned as "-" (without quotes).

Optionally this class might also include inodes information as defined in L<Filesys::Df>. Check the C<new> method description for more details.

=head1 METHODS

=head2 new()

Call C<new()> to create a new object.

    my $lxs = Linux::Info::DiskUsage->new;

Optionally it accepts two positional parameters as well.

It's possible to pass additional file system names (as available on C</proc/mounts>) so
you can see more mounted file systems in the returned value of C<get> method. The expected
parameter for that must be an array reference, as shown below:

    Linux::Info::DiskUsage->new([qw(reiserfs xfs)]);

Additional values given like that will be B<added> to the default set of accepted values.

This class also accepts a second parameter that defines if the instance will also provide inode information
from the file systems as well. This extends and breaks compatibility with L<Sys::Statistics::Linux::FileStats>
interface. To enable that, just pass one to enabled it, for example:

    Linux::Info::DiskUsage->new([qw(reiserfs xfs)], 1);

The interface of L<Linux::Info> also remains the same, so you can't use these extended options from it. This might change
in future implementations, but for now you need to create an instance from Linux::Info::DiskUsage directly from C<new>.

=cut

sub new {
    my ( $class, $opts_ref, $has_inode ) = @_;
    my $valids_ref = Linux::Info::DiskUsage->default_fs;
    if ( defined($opts_ref) ) {
        croak 'Additional file system names must be given as an array reference'
          unless ( ref($opts_ref) eq 'ARRAY' );
        foreach my $type ( @{$opts_ref} ) {
            push( @{$valids_ref}, $type );
        }
    }
    my %self = (
        fstypes   => Set::Tiny->new( @{$valids_ref} ),
        has_inode => $has_inode || 0
    );
    my $self = bless \%self, $class;
    return lock_keys( %{$self} );
}

=head2 get()

Call C<get()> to get the statistics. C<get()> returns the statistics as a hash reference.

    my $stat = $lxs->get;

The hash reference will have keys and values as described in B<DISK USAGE INFORMATIONS> section.

=cut

sub get {
    my $self          = shift;
    my $mount_entries = $self->_read;
    my %disk_usage;
    foreach my $entry ( @{$mount_entries} ) {
        my $ref  = df( $entry->[1] );
        my %info = (
            total      => $ref->{user_blocks} || '-',
            usage      => $ref->{used}        || '-',
            mountpoint => $entry->[1]         || '-',
            free       => $ref->{bfree}       || '-',
            usageper   => $ref->{per}         || '-'
        );
        if ( $self->{has_inode} ) {
            my @inode_keys = (qw(files ffree favail fused fper));
            if ( exists( $ref->{files} ) ) {
                foreach my $key (@inode_keys) {
                    $info{$key} = $ref->{$key};
                }
            }
            else {
                foreach my $key (@inode_keys) {
                    $info{$key} = '-';
                }
            }
            $disk_usage{ $entry->[0] } = \%info;
        }
    }
    return \%disk_usage;
}

=head2 default_fs

Returns and array reference with the file systems that are mounted and will have their storage
space checked by default.

This method can be invoke both directly from the class and from instances of it.

=cut

sub default_fs {

    return [qw(devtmpfs tmpfs ext2 ext3 ext4 fuseblk)];

}

sub _is_valid {
    my ( $self, $fs_type ) = @_;
    croak 'file system type must be defined' unless ( defined($fs_type) );
    return $self->{fstypes}->has($fs_type);
}

# strongly based on Linux::Proc::Mounts module, but much more restricted
# in terms of information accepted and provided
sub _read {
    my $self = shift;
    my $mnt  = "/proc";
    croak "$mnt is not a proc filesystem"
      unless -d $mnt and ( stat _ )[12] == 0;
    my $file = "$mnt/mounts";
    open my $fh, '<', $file
      or croak "Unable to open '$file': $!";
    my @entries;
    while (<$fh>) {
        chomp;
        my @entry = split;
        if ( @entry != 6 ) {
            warn "invalid number of entries in $file line $.";
            next;
        }
        $#entry = 3;    # ignore the two dummy values at the end
        s/\\([0-7]{1,3})/chr oct $1/g for @entry;

        # fs_spec and fs_file are returned as an entry
        push( @entries, [ $entry[0], $entry[1] ] )
          if $self->_is_valid( $entry[2] );
    }
    close($file);
    return \@entries;

}

=head1 EXPORTS

Nothing.

=head1 SEE ALSO

=over

=item *

B<proc(5)>

=item *

L<Filesys::Df>

=item *

L<Linux::Proc::Mounts>: this class borrows code from it.

=item *

L<Linux::Info>

=back

=head1 AUTHOR

Alceu Rodrigues de Freitas Junior, E<lt>arfreitas@cpan.orgE<gt>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2015 of Alceu Rodrigues de Freitas Junior, E<lt>arfreitas@cpan.orgE<gt>

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

1;

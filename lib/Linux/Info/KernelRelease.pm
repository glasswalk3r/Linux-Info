package Linux::Info::KernelRelease;
use strict;
use warnings;
use Carp qw(confess carp);
use Set::Tiny 0.04;
use Class::XSAccessor getters => {
    get_raw              => 'raw',
    get_mainline_version => 'mainline_version',
    get_abi_bump         => 'abi_bump',
    get_flavour          => 'flavour',
    get_major            => 'major',
    get_minor            => 'minor',
    get_patch            => 'patch',
    get_compiled_by      => 'compiled_by',
    get_gcc_version      => 'gcc_version',
    get_type             => 'type',
    get_build_datetime   => 'build_datetime',
};

# VERSION

=pod

=head1 NAME

Linux::Info::KernelRelease - parses and provide Linux kernel detailed information

=head1 SYNOPSIS

Getting the current kernel information:

    my $sys = Linux::Info::SysInfo->new;
    my $current = Linux::Info::KernelRelease->new({
        release  => $sys->get_release,
        version  => $sys->get_version,
        mainline => $sys->get_mainline_version
    });

Or using L<Linux::Info::SysInfo> syntax sugar to achieve the same result:

    my $sys = Linux::Info::SysInfo->new;
    my $current = $sys->get_detailed_kernel;

Or using a given Linux kernel release string:

    my $kernel = Linux::Info::KernelRelease->new('2.4.20-0-generic');

Now you can compare both:

    if ($current > $kernel) {
        say 'Kernel was upgraded!';
    }

=head1 DESCRIPTION

This module parses the Linux kernel information obtained from sources like the
C<uname> command and others.

This make it easier to fetch each information piece of information from the
string and also to compare different kernel versions, since instances of this
class overload operators like ">=", ">" and "<".

=head1 METHODS

=head2 new

Creates a new instance.

Expects as parameter the kernel release information
(F</proc/sys/kernel/osrelease>).

Optionally, you can pass:

=over

=item 1.

The kernel version information (F</proc/version>).

=item 2.

The kernel mainline information if available (as from
F</proc/version_signature> on Ubuntu Linux).

=back

With those parameters, even more information will be available.

=cut

# Linux version 2.6.18-92.el5 (brewbuilder@ls20-bc2-13.build.redhat.com) (gcc version 4.1.2 20071124 (Red Hat 4.1.2-41)) #1 SMP Tue Apr 29 13:16:15 EDT 2008
# Linux version 4.18.0-513.5.1.el8_9.x86_64 (mockbuild@iad1-prod-build001.bld.equ.rockylinux.org) (gcc version 8.5.0 20210514 (Red Hat 8.5.0-20) (GCC)) #1 SMP Fri Nov 17 03:31:10 UTC 2023

# Linux version 6.5.0-28-generic (buildd@lcy02-amd64-098) (x86_64-linux-gnu-gcc-12 (Ubuntu 12.3.0-1ubuntu1~22.04) 12.3.0, GNU ld (GNU Binutils for Ubuntu) 2.38) #29~22.04.1-Ubuntu SMP PREEMPT_DYNAMIC Thu Apr  4 14:39:20 UTC 2

my @version_data = qw(compiled_by gcc_version type build_datetime);

sub new {
    my ( $class, $opts_ref ) = @_;
    confess "Must receive a hash reference as parameter"
      unless ( defined($opts_ref) and ( ref $opts_ref eq 'HASH' ) );

    confess 'The release key is required'
      unless ( exists $opts_ref->{release} );

    # 6.5.0-28-generic
    unless ( $opts_ref->{release} =~ /^\d\.\d+\.\d+(\-\d+\-[a-z]+)?/ ) {
        my $error =
          'The string for release "' . $opts_ref->{release} . '" is invalid';
        confess $error;
    }

    my @pieces = split( '-', $opts_ref->{release} );

    my $self = {
        raw      => $opts_ref->{release},
        abi_bump => $pieces[-2],
        flavour  => $pieces[-1]
    };

    my $acceptable = Set::Tiny->new(qw(release version mainline));

    foreach my $key ( keys %{$opts_ref} ) {
        confess "$key key is invalid" unless $acceptable->has($key);
    }

    # if RedHat
    if ( ( exists $opts_ref->{version} ) and ( defined $opts_ref->{version} ) )
    {
        my $regex =
qr/^Linux\sversion\s[\w\._-]+\s\((?<compiled_by>[\w\.\-\@]+)\)\s\(gcc\sversion\s(?<gcc_version>[\d\.]+).*\)\s#1\s(?<type>\w+)\s(?<build_datetime>.*)/;
        if ( $opts_ref->{version} =~ $regex ) {
            foreach my $attrib (@version_data) {
                $self->{$attrib} = $+{$attrib};
            }
        }
        else {
            foreach my $attrib (@version_data) {
                $self->{$attrib} = undef;
            }
        }
    }
    else {
        foreach my $attrib (@version_data) {
            $self->{$attrib} = undef;
        }
    }

    if (    ( exists $opts_ref->{mainline} )
        and ( defined( $opts_ref->{mainline} ) ) )
    {
        $self->{mainline_version} =
          ( split( /\s/, $opts_ref->{mainline} ) )[-1];
    }
    else {
        $self->{mainline_version} = $pieces[0];
    }

    bless $self, $class;
    $self->_parse_version();
    return $self;
}

=head2 get_raw

Returns the raw information stored, as passed to the C<new> method.

=head2 get_mainline_version

Returns the mainline kernel-version.

=head2 get_abi_bump

Returns the application binary interface (ABI) bump from the kernel.

=head2 get_flavour

Returns the kernel flavour parameter.

=head2 get_major

Returns from the version, returns the integer corresponding to the major number.

=head2 get_minor

Returns from the version, returns the integer corresponding to the minor number.

=head2 get_patch

From the version, returns the integer corresponding to the patch number.

=head2 get_build_datetime

Returns a string representing when the kernel was built.

=head2 get_compiled_by

Returns a string, representing the user who compiled the kernel.

=head2 get_gcc_version

Returns a string, representing gcc compiler version used to compile the kernel.

=head2 get_type

Returns a string, representing the features which define the kernel type.

=cut

sub _parse_version {
    my $self = shift;
    my ( $major, $minor, $patch ) = split( /\./, $self->{mainline_version} );
    $self->{major} = $major;
    $self->{minor} = $minor;
    $self->{patch} = $patch;
}

sub _validate_other {
    my ( $self, $other ) = @_;
    my $class     = ref $self;
    my $other_ref = ref $other;

    confess 'The other parameter must be a reference' if ( $other_ref eq '' );
    confess 'The other instance must be a instance of'
      . $class
      . ', not '
      . $other_ref
      unless ( $other->isa($class) );
}

sub _ge_version {
    my ( $self, $other ) = @_;
    $self->_validate_other($other);

    return 1 if ( $self->{major} > $other->get_major );
    return 0 if ( $self->{major} < $other->get_major );
    return 1 if ( $self->{minor} > $other->get_minor );
    return 0 if ( $self->{minor} < $other->get_minor );
    return 1 if ( $self->{patch} > $other->get_patch );
    return 0 if ( $self->{patch} < $other->get_patch );
    return 1;
}

sub _gt_version {
    my ( $self, $other ) = @_;
    $self->_validate_other($other);

    return 1 if ( $self->{major} > $other->get_major );
    return 0 if ( $self->{major} < $other->get_major );
    return 1 if ( $self->{minor} > $other->get_minor );
    return 0 if ( $self->{minor} < $other->get_minor );
    return 1 if ( $self->{patch} > $other->get_patch );
    return 0 if ( $self->{patch} < $other->get_patch );
    return 0;
}

sub _lt_version {
    my ( $self, $other ) = @_;
    $self->_validate_other($other);

    return 0 if ( $self->{major} > $other->get_major );
    return 1 if ( $self->{major} < $other->get_major );
    return 0 if ( $self->{minor} > $other->get_minor );
    return 1 if ( $self->{minor} < $other->get_minor );
    return 0 if ( $self->{patch} > $other->get_patch );
    return 1 if ( $self->{patch} < $other->get_patch );
    return 0;
}

use overload
  '>=' => '_ge_version',
  '>'  => '_gt_version',
  '<'  => '_lt_version';

=head1 SEE ALSO

=over

=item *

https://ubuntu.com/kernel

=item *

https://www.unixtutorial.org/use-proc-version-to-identify-your-linux-release/

=back

=head1 AUTHOR

Alceu Rodrigues de Freitas Junior, E<lt>glasswalk3r@yahoo.com.brE<gt>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2024 of Alceu Rodrigues de Freitas Junior,
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

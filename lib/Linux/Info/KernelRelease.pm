package Linux::Info::KernelRelease;
use strict;
use warnings;
use Carp qw(confess carp);
use base 'Class::Accessor';

# VERSION

my @_attribs = qw(raw mainline_version abi_bump flavour major minor patch);

__PACKAGE__->follow_best_practice;
__PACKAGE__->mk_ro_accessors(@_attribs);

=pod

=head1 NAME

Linux::Info::KernelRelease - parses and provide Linux kernel detailed information

=head1 SYNOPSIS

=head1 DESCRIPTION

=head1 METHODS

=head2 new

=cut

sub new {
    my ( $class, $release, $mainline ) = @_;

    confess "Must receive a string as kernel release information"
      unless ($release);

    # 6.5.0-28-generic
    confess "The received string for release '$release' is invalid"
      unless ( $release =~ /^\d\.\d+\.\d+(\-\d+\-[a-z]+)?/ );

    my @pieces = split( '-', $release );

    my $self = {
        raw      => $release,
        abi_bump => $pieces[-2],
        flavour  => $pieces[-1]
    };

    $self->{mainline_version} =
      ($mainline) ? ( split( /\s/, $mainline ) )[-1] : $pieces[0];
    bless $self, $class;
    $self->_parse_version();
    return $self;
}

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

This software is copyright (c) 2024 of Alceu Rodrigues de Freitas Junior, E<lt>glasswalk3r@yahoo.com.brE<gt>

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

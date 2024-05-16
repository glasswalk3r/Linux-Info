package Linux::Info::Distribution::Finder;

use warnings;
use strict;
use Hash::Util qw(lock_hash);
use Carp       qw(confess);
use Class::XSAccessor setters => { set_config_dir => 'config_dir', };
use File::Spec;
use constant DEFAULT_CONFIG_DIR => '/etc';

use Linux::Info::Distribution::OSRelease;

# VERSION

=pod

=head1 NAME

Linux::Info::Distribution::Finder - class to search for candidate files

=head2 SYNOPSIS

    use Linux::Info::Distribution::Finder;
    my $finder = Linux::Info::Distribution::Finder->new;
    my $info_ref = $finder->search_distro;

=head3 DESCRIPTION

This class should be used to retrieve Linux distribution information on several
candidates files.

First it tries F</etc/os-release> (since it should contain more data), then
look into other known places.

=cut

my %release_files = (
    'gentoo-release'        => 'gentoo',
    'fedora-release'        => 'fedora',
    'centos-release'        => 'centos',
    'enterprise-release'    => 'oracle enterprise linux',
    'turbolinux-release'    => 'turbolinux',
    'mandrake-release'      => 'mandrake',
    'mandrakelinux-release' => 'mandrakelinux',
    'debian_version'        => 'debian',
    'debian_release'        => 'debian',
    'SuSE-release'          => 'suse',
    'knoppix-version'       => 'knoppix',
    'yellowdog-release'     => 'yellowdog',
    'slackware-version'     => 'slackware',
    'slackware-release'     => 'slackware',
    'redflag-release'       => 'redflag',
    'redhat-release'        => 'redhat',
    'redhat_version'        => 'redhat',
    'conectiva-release'     => 'conectiva',
    'immunix-release'       => 'immunix',
    'tinysofa-release'      => 'tinysofa',
    'trustix-release'       => 'trustix',
    'adamantix_version'     => 'adamantix',
    'yoper-release'         => 'yoper',
    'arch-release'          => 'arch',
    'libranet_version'      => 'libranet',
    'va-release'            => 'va-linux',
    'pardus-release'        => 'pardus',
    'system-release'        => 'amazon',
    'CloudLinux-release'    => 'CloudLinux',
);
lock_hash(%release_files);

=head1 METHODS

=head2 new

Creates and returns a new instance.

No parameter is expected.

=cut

sub new {
    my $class = shift;
    my $self  = { config_dir => DEFAULT_CONFIG_DIR, release_info => undef };
    bless $self, $class;
    return $self;
}

=head2 set_config_dir

Changes the default configuration directory used by a instance.

Most useful for unit testing with mocks.

=cut

sub _config_dir {
    my $self = shift;
    opendir( my $dh, $self->{config_dir} )
      or confess( 'Cannot read ' . $self->{config_dir} . ': ' . $! );
    my $version_regex = qr/version$/;
    my $release_regex = qr/release$/;
    my @candidates;
    my $unwanted = (
        File::Spec->splitpath(
            Linux::Info::Distribution::OSRelease->DEFAULT_FILE
        )
    )[-1];

    while ( readdir $dh ) {
        next if ( ( $_ eq '.' ) or ( $_ eq '..' ) );
        push( @candidates, ($_) )
          if (
            ( $_ =~ $version_regex )
            or (    ( $_ ne $unwanted )
                and ( $_ =~ $release_regex ) )
          );
    }

    closedir($dh);
    return \@candidates;
}

# TODO: should return a well known data structure
sub _search_release_file {
    my $self           = shift;
    my $candidates_ref = $self->_config_dir;

    foreach my $thing ( @{$candidates_ref} ) {
        my $file_path = $self->{config_dir} . '/' . $thing;

        if ( ( exists $release_files{$thing} ) and ( -f $file_path ) ) {
            $self->{release_info} = {
                id            => ( lc $release_files{$thing} ),
                file_to_parse => ($file_path),
            };
            last;
        }
    }
}

=head2 search_distro

Search and return the Linux distribution information.

The returned value might be one generated by
L<Linux::Info::Distribution::OSRelease> C<parse> method, if there is a
F</etc/os-release> file available.

If not, a custom distribution file will be attempted and the returned value
will be a hash reference with the following structure:

    {
        id => 'someid',
        file_to_parse => '/etc/foobar_version',
    }

Since the file needs to be parsed to retrieve all available information,
this file will need to be parsed by a L<Linux::Info::Distribution::Custom>
subclasses.

=cut

sub search_distro {
    my $self       = shift;
    my $os_release = shift || Linux::Info::Distribution::OSRelease->new;

    return $self->{release_info} if ( defined( $self->{release_info} ) );

    if ( $self->{config_dir} eq DEFAULT_CONFIG_DIR ) {
        if ( -r $os_release->get_source ) {
            $self->{release_info} = $os_release->parse;
        }
        else {
            $self->_search_release_file;
        }
    }
    else {
        $self->_search_release_file;
    }

    return $self->{release_info};
}

=head2 has_distro_info

Returns "true" (1) if the instance has already cached distribution information.

Otherwise, returns "false" (0).

=cut

sub has_distro_info {
    my $self = shift;
    return ( defined( $self->{release_info} ) ) ? 1 : 0;
}

=head2 has_custom

Returns "true" (1) if the instance has cached distribution information
retrieved from a custom file.

Otherwise, returns "false" (0).

=cut

sub has_custom {
    my $self = shift;

    if (    ( defined( $self->{release_info} ) )
        and ( exists $self->{release_info}->{file_to_parse} )
        and ( defined $self->{release_info}->{file_to_parse} ) )
    {
        return 1;
    }

    return 0;
}

=head1 EXPORTS

Nothing.

You can use C<Linux::Info:Distribution::Finder::DEFAULT_CONFIG_DIR> to fetch
the default directory used to search for distribution information.

=cut

1;

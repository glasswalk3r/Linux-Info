package Linux::Info::Distribution::Finder;

use warnings;
use strict;
use Hash::Util qw(lock_hash);
use Carp       qw(confess);
use Class::XSAccessor setters => { set_config_dir => 'config_dir', };
use File::Spec;

use Linux::Info::Distribution::OSRelease;

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

sub new {
    my $class = shift;
    my $self  = { config_dir => '/etc', release_info => undef };
    bless $self, $class;
    return $self;
}

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

sub _search_release_file {
    my $self           = shift;
    my $candidates_ref = $self->_config_dir;

    foreach my $thing ( @{$candidates_ref} ) {
        my $file_path = $self->{config_dir} . '/' . $thing;

        if ( ( exists $release_files{$thing} ) and ( -f $file_path ) ) {
            $self->{release_info} = {
                distro_id     => ( lc $release_files{$thing} ),
                file_to_parse => ($file_path),
            };
            last;
        }
    }
}

sub search_distro {
    my $self       = shift;
    my $os_release = shift || Linux::Info::Distribution::OSRelease->new;

    return $self->{release_info} if ( defined( $self->{release_info} ) );

    return $os_release->parse if ( -r $os_release->get_source );

    $self->_search_release_file;
    return $self->{release_info};
}

sub distro_name {
    my $self = shift;
    return $self->{release_info}->{distro_name}
      if ( defined( $self->{release_info} ) );
    return undef;
}

1;

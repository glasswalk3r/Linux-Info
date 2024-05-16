package Linux::Info::Distribution::OSRelease::Ubuntu;

use warnings;
use strict;
use parent 'Linux::Info::Distribution::OSRelease';
use Hash::Util qw(lock_hash unlock_hash);
use Class::XSAccessor getters => {
    get_pretty_name        => 'pretty_name',
    get_version_codename   => 'version_codename',
    get_id_like            => 'id_like',
    get_home_url           => 'home_url',
    get_support_url        => 'support_url',
    get_bug_report_url     => 'bug_report_url',
    get_privacy_policy_url => 'privacy_policy_url',
    get_ubuntu_codename    => 'ubuntu_codename',
};

# VERSION

sub new {
    my ( $class, $file_path ) = @_;
    my $self = $class->SUPER::new();
    unlock_hash( %{$self} );

    my @attribs = (
        'pretty_name',        'version_codename',
        'id_like',            'home_url',
        'support_url',        'bug_report_url',
        'privacy_policy_url', 'ubuntu_codename',
    );

    foreach my $attrib (@attribs) {
        $self->{$attrib} = $self->{cache}->{$attrib};
    }

    delete( $self->{cache} );

    lock_hash( %{$self} );
    return $self;
}

1;

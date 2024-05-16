package Linux::Info::Distribution::OSRelease::Ubuntu;

use warnings;
use strict;
use parent 'Linux::Info::Distribution::OSRelease';
use Hash::Util qw(lock_hash unlock_hash);
use Class::XSAccessor getters => {
    get_version_codename   => 'version_codename',
    get_support_url        => 'support_url',
    get_bug_report_url     => 'bug_report_url',
    get_privacy_policy_url => 'privacy_policy_url',
    get_ubuntu_codename    => 'ubuntu_codename',
};

# VERSION

=pod

=head1 NAME

Linux::Info::Distribution::OSRelease::Ubuntu - a subclass of Linux::Info::Distribution::OSRelease

=head1 DESCRIPTION

This subclass extends the attributes available on the parent class based on
what Ubuntu makes available.

See the methods to check which additional information is avaiable.

=head1 METHODS

=head2 new

Returns a new instance of this class.

Expects as an optional parameter the complete path to a file that will be used
to retrieve data in the expected format.

=cut

sub new {
    my ( $class, $file_path ) = @_;
    my $self = $class->SUPER::new($file_path);
    unlock_hash( %{$self} );

    my @attribs = (
        'version_codename', 'support_url',
        'bug_report_url',   'privacy_policy_url',
        'ubuntu_codename',
    );

    foreach my $attrib (@attribs) {
        $self->{$attrib} = $self->{cache}->{$attrib};
    }

    $self->clean_cache;
    lock_hash( %{$self} );
    return $self;
}

=head2 get_version_codename

Returns the Ubuntu codename for the released version.

=head2 get_support_url

Returns the URL with support information about Ubuntu.

=head2 get_bug_report_url

Returns the URL with details on how to report bugs on Ubuntu.

=head2 get_privacy_policy_url

Returns the URL with the privacy policy of Ubuntu.

=head2 get_ubuntu_codename

Returns a string the Ubuntu codename, based on the version.

=head1 EXPORTS

Nothing.

=cut

1;

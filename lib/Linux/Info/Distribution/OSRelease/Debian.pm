package Linux::Info::Distribution::OSRelease::Debian;

use warnings;
use strict;
use base 'Linux::Info::Distribution::OSRelease';
use Hash::Util qw(lock_hash unlock_hash);
use Class::XSAccessor getters => {
    get_bug_report_url   => 'bug_report_url',
    get_support_url      => 'support_url',
    get_version_codename => 'version_codename',
};

# VERSION

# ABSTRACT: a subclass of Linux::Info::Distribution::OSRelease

=head1 DESCRIPTION

This subclass extends the attributes available on the parent class based on
what Debian GNU Linux makes available.

See the methods to check which additional information is available.

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

    my @attribs = ( 'bug_report_url', 'support_url', 'version_codename' );

    foreach my $attrib (@attribs) {
        $self->{$attrib} = $self->{cache}->{$attrib};
    }

    $self->clean_cache;
    lock_hash( %{$self} );
    return $self;
}

=head2 get_bug_report_url

Returns the URL for reporting bugs for this distribution.

=head2 get_support_url

Returns the URL for support on how to get support on this distribution.

=head2 get_version_codename

Returns a string with the codename associated with this distribution version.

=cut

1;

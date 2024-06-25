package Linux::Info::Distribution::OSRelease::Alpine;

use warnings;
use strict;
use base 'Linux::Info::Distribution::OSRelease';
use Hash::Util qw(lock_hash unlock_hash);
use Class::XSAccessor getters => { get_bug_report_url => 'bug_report_url' };

# VERSION
# ABSTRACT: a subclass of Linux::Info::Distribution::OSRelease

=head1 DESCRIPTION

This subclass extends the attributes available on the parent class based on
what Alpine Linux makes available.

See the methods to check which additional information is avaiable.

=head1 METHODS

=head2 new

Returns a new instance of this class.

Expects as an optional parameter the complete path to a file that will be used
to retrieve data in the expected format.

=cut

sub _handle_missing {
    my ( $class, $info_ref ) = @_;

    # WORKAROUND: Alpine doesn't provide that
    $info_ref->{version} = undef unless ( exists $info_ref->{version} );
}

sub new {
    my ( $class, $file_path ) = @_;
    my $self = $class->SUPER::new($file_path);
    unlock_hash( %{$self} );
    $self->{bug_report_url} = $self->{cache}->{bug_report_url};
    $self->clean_cache;
    lock_hash( %{$self} );
    return $self;
}

=head2 get_bug_report_url

Returns the URL of the bug report website.

=cut

1;

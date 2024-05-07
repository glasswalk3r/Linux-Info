package Linux::Info::DiskStats::Options;
use warnings;
use strict;
use Hash::Util qw(lock_keys);
use Carp       qw(confess);
use Regexp::Common 2017060201;

# VERSION

=head1 NAME

Linux::Info::DiskStats::Options - Configuration for Linux::Info::DiskStats instances.

=head1 SYNOPSIS

    $opts = Linux::Info::DiskStats::Options->new({
        backwards_compatible => 1,
        source_file          => '/tmp/foobar.txt',
        init_file            => '/tmp/diskstats.yml',
        global_block_size    => 4096,
        current_kernel       => '2.6.18-0-generic',
    })

=head1 DESCRIPTION

Configuration for L<Linux::Info::DiskStats> can get so complex that is worth
creating a class to describe and validate it.

The good news is that a instance of C<Linux::Info::DiskStats::Options> doesn't
need to be that complex in every situation. But you will be glad to get
validations in place anyway.

=head1 METHODS

=head1 new

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
version) will be used instead. It is basically used to enable unit testing.

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
    my ( $class, $opts_ref ) = @_;
    my $self = {};

    if ( defined($opts_ref) ) {
        confess 'The options reference must be a hash reference'
          unless ( ref $opts_ref eq 'HASH' );
    }

    $self->{backwards_compatible} = 1
      unless ( ( exists $opts_ref->{backwards_compatible} )
        and defined( $opts_ref->{backwards_compatible} ) );

    if ( $self->{backwards_compatible} ) {
        confess
'Must setup global_block_size or block_sizes unless backwards_compatible is disabled'
          unless ( ( exists $opts_ref->{global_block_size} )
            or ( exists $opts_ref->{block_sizes} ) );

        my $int_regex = qr/^$RE{num}->{int}$/;

        if ( exists $opts_ref->{global_block_size} ) {
            confess 'global_block_size must have an integer as value'
              unless ( ( defined( $opts_ref->{global_block_size} ) )
                and ( $opts_ref->{global_block_size} =~ $int_regex ) );
        }

        if ( exists $opts_ref->{block_sizes} ) {
            confess 'block_sizes must be a hash reference'
              unless ( ( defined $opts_ref->{block_sizes} )
                and ( ref $opts_ref->{block_sizes} eq 'HASH' ) );

            confess 'block_sizes must have at least one disk'
              unless ( ( scalar( keys %{ $opts_ref->{block_sizes} } ) ) > 0 );

            foreach my $disk ( keys %{ $opts_ref->{block_sizes} } ) {
                confess 'block size must be an integer'
                  unless ( $opts_ref->{block_sizes}->{$disk} =~ $int_regex );
            }
        }

    }

    return bless $self, $class;
}

1;

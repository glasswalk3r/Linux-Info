package Linux::Info::SysInfo::CPU::Arm;
use strict;
use warnings;
use Carp       qw(confess);
use Hash::Util qw(lock_keys);
use Class::XSAccessor getters => {};

use parent 'Linux::Info::SysInfo::CPU';

# VERSION

# ABSTRACT: Collects Arm based CPU information from /proc/cpuinfo

# https://developer.arm.com/documentation
#

=head1 SYNOPSIS


=head1 DESCRIPTION

This is a subclass of L<Linux::Info::SysInfo::CPU>, with specific code to parse
ARM format of L</proc/cpuinfo>.

=head1 SEE ALSO

=over

=item *

https://developer.arm.com/documentation

=item *

L<lscpu patch|https://github.com/util-linux/util-linux/pull/564/files> that
defines the translation of hexadecimal values to ARM processor implementer.

=back

=cut

sub model_regex {
    return qr/^Processor\s+\:\s(.*)/;
}

1;

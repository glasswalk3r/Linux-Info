package Linux::Info::SysInfo::CPU::Arm;
use strict;
use warnings;
use Carp qw(confess);

use parent 'Linux::Info::SysInfo::CPU';

# VERSION

# ABSTRACT: Collects Arm based CPU information from /proc/cpuinfo

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

my %vendors = (
    '0x41' => 'ARM',
    '0x42' => 'Broadcom',
    '0x43' => 'Cavium',
    '0x44' => 'DEC',
    '0x4e' => 'Nvidia',
    '0x50' => 'APM',
    '0x51' => 'Qualcomm',
    '0x53' => 'Samsung',
    '0x56' => 'Marvell',
    '0x69' => 'Intel',
);

sub _parse {
    my $model_regex = qr/^Processor\s+\:\s(.*)/;

# Features	: fp asimd evtstrm aes pmull sha1 sha2 crc32 atomics fphp asimdhp cpuid asimdrdm lrcpc dcpop
    my $flags_regex = qr/^Features\t\:\s+(.*)/;

    # CPU implementer	: 0x41
    my $vendor_regex = qr/CPU\simplementer\t\:\s(0x\d+)/;
}

1;

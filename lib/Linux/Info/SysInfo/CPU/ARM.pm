package Linux::Info::SysInfo::CPU;
use strict;
use warnings;
use Carp       qw(croak);
use Hash::Util qw(lock_keys);
use Class::XSAccessor getters => {};

# VERSION

# ABSTRACT: Collects CPU information from /proc/cpuinfo

# https://developer.arm.com/documentation
# https://github.com/util-linux/util-linux/pull/564/files

1;

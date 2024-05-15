use warnings;
use strict;
use Test::More;

use constant CLASS => 'Linux::Info::Distribution::Factory';

require_ok(CLASS);
can_ok( CLASS, qw(create new distro_name _init) );

done_testing;

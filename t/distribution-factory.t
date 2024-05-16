use warnings;
use strict;
use Test::More;
use Linux::Info::Distribution::Finder;

my $class = 'Linux::Info::Distribution::Factory';

require_ok($class);
can_ok( $class, qw(create new distro_name) );

my $finder = Linux::Info::Distribution::Finder->new;
$finder->set_config_dir('t/samples');

my $instance = Linux::Info::Distribution::Factory->new($finder);
isa_ok( $instance, $class );
is(
    $instance->distro_name,
    'Red Hat Linux Enterprise Server',
    'distro_name returns the expected value'
) or diag( explain($instance) );

my $distro = $instance->create;
isa_ok( $distro, 'Linux::Info::Distribution::Custom::RedHat' )
  or diag( explain($instance) );

done_testing;

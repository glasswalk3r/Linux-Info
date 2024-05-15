use warnings;
use strict;
use Test::More;

my $class = 'Linux::Info::Distribution::Custom::RedHat';
require_ok($class);
can_ok( $class, qw(get_type is_enterprise get_codename) );

my $instance = $class->new(
    { id => 'redhat', file_to_parse => 't/samples/redhat_version' } );
ok( $instance, 'new method works' );
isa_ok( $instance, 'Linux::Info::Distribution::Custom' );

is( $instance->get_name, 'Red Hat Linux Enterprise Server', 'get_name works' )
  or diag( explain($instance) );
is( $instance->get_id, 'redhat', 'get_id works' ) or diag( explain($instance) );
ok( $instance->is_enterprise, 'the distro is Enterprise' )
  or diag( explain($instance) );
is( $instance->get_type, 'Server', 'get_type works' )
  or diag( explain($instance) );
is( $instance->get_codename, 'Maipo', 'get_codename works' )
  or diag( explain($instance) );
is( $instance->get_version, 'release 7.2, codename Maipo', 'get_version works' )
  or diag( explain($instance) );
is( $instance->get_version_id, '7.2', 'get_version_id works' )
  or diag( explain($instance) );
done_testing;

use warnings;
use strict;
use Test::More;
use File::Temp qw(tempfile);

use Linux::Info::Distribution::OSRelease;

my $class = 'Linux::Info::Distribution::Finder';
require_ok($class);
can_ok( $class,
    qw(new _config_dir _search_release_file search_distro distro_name ) );
ok( $class->new, 'constructor works' );

my $instance = $class->new;
isa_ok( $instance, $class );

SKIP: {
    skip 'default file not available on the file system', 1
      unless ( -f Linux::Info::Distribution::OSRelease->DEFAULT_FILE );
    is( ref( $instance->search_distro ),
        'HASH', 'search_distro returns the expected value' );
}

my $fixture = 't/samples/os-release';
note("Using custom file $fixture");
is(
    ref(
        $instance->search_distro(
            Linux::Info::Distribution::OSRelease->new($fixture)
        )
    ),
    'HASH',
    'search_distro returns the expected value with custom OSRelease'
);

my ( $fh, $tmp_file ) = tempfile;
close($fh);
unlink $tmp_file;
my $dir = 't/samples';
note("Forcing $dir as a custom config_dir and OSRelease with $tmp_file");
$instance->set_config_dir($dir);
my $result_ref = $instance->search_distro(
    Linux::Info::Distribution::OSRelease->new($tmp_file) );
my $config_dir_ref = $instance->_config_dir;
is( ref($config_dir_ref), 'ARRAY',
    '_config_dir returns the expected reference type' );
is( ( scalar @{$config_dir_ref} ),
    1, '_config_dir returns the expected number of files' )
  or diag( explain($config_dir_ref) );

is( ref($result_ref), 'HASH',
    'search_distro returns the expected reference type' )
  or diag( explain($instance) );
is_deeply(
    $result_ref,
    {
        distro_id     => 'redhat',
        file_to_parse => 't/samples/redhat_version',
    },
    'earch_distro returns the expected value'
) or diag( explain($result_ref) );

done_testing;

use warnings;
use strict;
use v5.8.9;
use ExtUtils::MakeMaker;

die 'OS unsupported! Sorry, but this system seems not to be a linux system!'
  unless $^O =~ /linux/i;

die 'OS unsupported, no read access to /proc' unless -r '/proc';

WriteMakefile(
    NAME         => 'Linux::Info',
    VERSION_FROM => 'lib/Linux/Info.pm',
    PREREQ_PM    => {
        'UNIVERSAL::require' => 0,
        'UNIVERSAL'          => 0,
        'Test::More'         => "1.001014",
        'Carp'               => "1.36",
        'POSIX'              => 0,
        'Time::HiRes'        => "1.9726",
        'Devel::CheckOS'     => "1.76",
        'Readonly'           => "2.00",
        'Class::Accessor'    => "0.34",
    },
    META_MERGE => {
        resources => {
            homepage   => 'https://github.com/glasswalk3r/Linux-Info',
            license    => 'http://www.gnu.org/licenses/gpl.txt',
            bugtracker => 'https://github.com/glasswalk3r/Linux-Info/issues',
            repository => 'https://github.com/glasswalk3r/Linux-Info'
        },
    },
    dist => { SUFFIX => '.gz', COMPRESS => 'gzip --best' },
    (
        $] >= 5.010
        ?    ## Add these new keywords supported since 5.005
          (
            ABSTRACT_FROM =>
              'lib/Linux/Info.pm',    # retrieve abstract from module
            AUTHOR => 'Alceu Rodrigues de Freitas Junior <arfreitas@cpan.org>'
          )
        : ()
    ),
    ( $ExtUtils::MakeMaker::VERSION >= 6.3002 ? ( 'LICENSE' => 'gpl', ) : () )

);

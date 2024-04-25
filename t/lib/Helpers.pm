package Helpers;

use warnings;
use strict;
use Exporter 'import';
our @EXPORT_OK = qw(total_lines tests_set_desc);

sub total_lines {
    my $opts_ref     = shift;
    my $file         = $opts_ref->{source_file};
    my $line_counter = 0;

    open( my $in, '<', $file ) or die "Cannot read $file: $!";
    while (<$in>) {
        $line_counter++;
    }
    close($in) or die "Cannot close $file: $!";
    return $line_counter;
}

sub tests_set_desc {
    my ( $opts_ref, $kernel_info ) = @_;

    return ('Validating '
          . $opts_ref->{source_file}
          . ' information for '
          . $kernel_info
          . ' with backwards compatible turned '
          . ( $opts_ref->{backwards_compatible} ? 'on' : 'off' ) );
}

1;

package Linux::Info::SysInfo::CPU::Intel;
use strict;
use warnings;
use Carp qw(confess);
use Class::XSAccessor getters => {};

# VERSION

# ABSTRACT: Collects s390 based CPU information from /proc/cpuinfo

sub _parse {
    my $self        = shift;
    my $file        = $self->{source_file};
    my $model_regex = qr/^model\sname\s+\:\s(.*)/;

    open( my $fh, '<', $file ) or confess "Cannot read $file: $!";

  LINE: while ( my $line = <$fh> ) {
        chomp($line);

        if ( $line =~ /^# processors\s*:\s*(\d+)/ ) {
            $self->{tcpucount} = $1;
            last CASE;
        }

    }

    close($fh);
}

1;

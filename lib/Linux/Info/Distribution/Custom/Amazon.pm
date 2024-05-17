package Linux::Info::Distribution::Custom::Amazon;

use warnings;
use strict;
use parent 'Linux::Info::Distribution::Custom';

# VERSION
# ABSTRACT: a subclass of Linux::Info::Distribution::Custom

sub _set_regex {
    my $self = shift;
    $self->{regex} =
      qr/(?<name>Amazon\sLinux)\sAMI\srelease\s(?<version>[\d\.]+)/;
}

sub _set_others {
    my ( $self, $data_ref ) = @_;
    $self->{name}       = $data_ref->{name};
    $self->{version}    = $data_ref->{version};
    $self->{version_id} = $data_ref->{version};
}

1;

package Linux::Info::Distribution::Custom;

use strict;
use warnings;
use Carp       qw(confess);
use Hash::Util qw(lock_hash unlock_hash);
use parent 'Linux::Info::Distribution';
use Class::XSAccessor getters =>
  { get_source => 'source', get_regex => 'regex' };

# VERSION

sub _set_regex {
    confess 'Must be implemented by subclasses of ' . ref(shift);
}

sub _set_others {
    confess 'Must be implemented by subclasses of ' . ref(shift);
}

sub _parse_source {
    my $self = shift;
    $self->_set_regex;
    my %match_result;
    my $source_file = $self->{source};

    open( my $in, '<', $source_file )
      or confess("Cannot read $source_file: $!");

    while (<$in>) {
        chomp;
        if ( $_ =~ $self->{regex} ) {
            map { $match_result{$_} = $+{$_} } keys %+;
            last;
        }
    }

    close($in)
      or confess("Cannot close $source_file: $!");
    confess "Failed to parse the content of $source_file"
      unless ( scalar( keys %match_result ) > 0 );
    $self->{source} = $source_file;
    $self->_set_others( \%match_result );
}

sub new {
    my ( $class, $attribs_ref ) = @_;

    confess 'The hash reference is missing the "file_to_parse" key'
      unless ( exists $attribs_ref->{file_to_parse} );

    $attribs_ref->{version}    = undef;
    $attribs_ref->{version_id} = undef;
    my $self = $class->SUPER::new($attribs_ref);
    unlock_hash( %{$self} );
    $self->{source} = $attribs_ref->{file_to_parse};
    $self->_parse_source;
    lock_hash( %{$self} );
    return $self;
}

1;

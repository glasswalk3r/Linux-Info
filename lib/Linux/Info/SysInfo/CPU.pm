package Linux::Info::SysInfo::CPU;
use strict;
use warnings;
use Carp       qw(confess);
use Hash::Util qw(lock_keys);
use Set::Tiny 0.04;
use Class::XSAccessor
  getters => {
    get_arch     => 'architecture',
    get_cores    => 'cores',
    get_threads  => 'threads',
    get_model    => 'model',
    get_flags    => 'flags',
    get_bogomips => 'bogomips',
    get_bugs     => 'bugs',
    get_vendor   => 'vendor',
  },
  exists_predicates => { has_multithread => 'multithread', };

# VERSION

# ABSTRACT: Collects CPU information from /proc/cpuinfo

sub _set_proc_bits {
    confess 'Must be overrided by subclasses';
}

sub _set_hyperthread {
    confess 'Must be overrided by subclasses';
}

sub _parse {
    confess 'Must be overrided by subclasses';
}

sub _parse_list {
    return ( split( /\s+:\s/, shift->{line} ) )[1];
}

sub _parse_flags {
    my ( $self, $line ) = @_;
    $self->{line} = $line;
    my $value = $self->_parse_list;
    $self->{flags}->insert( split( /\s/, $value ) );
    $self->{line} = undef;
}

sub _parse_bugs {
    my ( $self, $line ) = @_;
    $self->{line} = $line;
    my $value = $self->_parse_list;
    $self->{bugs}->insert( split( /\s/, $value ) );
    $self->{line} = undef;
}

sub has_flag {
    my ( $self, $flag ) = @_;

    # Set::Tiny uses 1 for truth, undef for false
    return 0 if ( $self->{flags}->is_empty );
    return 1 if ( $self->{flags}->has($flag) );
    return 0;
}

sub new {
    my ( $class, $source_file ) = @_;
    my $self = {
        multithread  => 0,
        model        => undef,
        processors   => 0,
        cores        => 0,
        threads      => 0,
        flags        => Set::Tiny->new,
        architecture => undef,
        bogomips     => 0,
        bugs         => Set::Tiny->new,
        vendor       => undef,
    };
    $source_file = '/proc/cpuinfo'
      unless ( ( defined($source_file) ) and ( $source_file ne '' ) );

    croak "The file $source_file is not available for reading"
      unless ( -r $source_file );

    $self->{source_file} = $source_file;
    bless $self, $class;
    $self->_parse;
    $self->_set_hyperthread;
    $self->_set_proc_bits;
    delete $self->{line};
    lock_keys( %{self} );
    return $self;
}

1;

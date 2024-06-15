package Linux::Info::SysInfo::CPU;
use strict;
use warnings;
use Carp       qw(confess);
use Hash::Util qw(lock_keys);
use Set::Tiny 0.04;
use Class::XSAccessor getters => {
    get_arch        => 'architecture',
    get_model       => 'model',
    get_bogomips    => 'bogomips',
    get_vendor      => 'vendor',
    get_source_file => 'source_file',
};

# VERSION

# ABSTRACT: Collects CPU information from /proc/cpuinfo

my $override_error = 'This method must be overrided by subclasses';

sub _set_proc_bits {
    confess $override_error;
}

sub _set_hyperthread {
    confess $override_error;
}

sub _parse {
    confess $override_error;
}

sub processor_regex {
    confess $override_error;
}

sub _custom_attribs {
    confess $override_error;
}

sub get_cores {
    confess $override_error;
}

sub get_threads {
    confess $override_error;
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

sub has_flag {
    my ( $self, $flag ) = @_;

    # Set::Tiny uses 1 for truth, undef for false
    return 0 if ( $self->{flags}->is_empty );
    return 1 if ( $self->{flags}->has($flag) );
    return 0;
}

sub get_flags {
    my @flags = sort( shift->{flags}->members );
    return \@flags;
}

sub new {
    my ( $class, $source_file ) = @_;
    my $self = {
        model        => undef,
        processors   => 0,
        flags        => Set::Tiny->new,
        architecture => undef,
        bogomips     => 0,
        vendor       => undef,
    };
    $source_file = '/proc/cpuinfo'
      unless ( ( defined($source_file) ) and ( $source_file ne '' ) );

    confess "The file $source_file is not available for reading"
      unless ( -r $source_file );

    $self->{source_file} = $source_file;
    bless $self, $class;
    $self->_custom_attribs;
    $self->_parse;
    $self->_set_hyperthread;
    $self->_set_proc_bits;
    delete $self->{line};
    lock_keys( %{$self} );
    return $self;
}

1;

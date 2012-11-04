package Vim::Helper::Plugin;
use strict;
use warnings;
use Carp qw/croak/;
our @CARP_NOT = ( 'Vim::Helper' );

sub import {
    my $class = shift;
    my $caller = caller;
    my %config_keys = @_;

    {
        no strict 'refs';
        no warnings 'once';
        push @{ "$caller\::ISA" } => $class;
        *{ "$caller\::config_keys" } = sub { \%config_keys };
    }

    _gen_accessor( $caller, $_ )
        for keys %config_keys;
}

sub new {
    my $class = shift;
    return bless {} => $class;
}

sub args {{}}
sub opts {{}}
sub vimrc { "" }
sub config_keys {{}}

sub config {
    my $self = shift;
    my ( $config ) = @_;

    for my $key ( keys %{ $self->config_keys }) {
        my $val = delete $config->{$key};
        my $spec = $self->config_keys->{$key};

        croak "config key '$key' is required."
            if $spec->{required} && !defined $val;

        $self->$key( $val ) if defined $val;
    }

    return unless keys %$config;

    croak "The following keys are not valid: " . join ", " => keys %$config;
}

sub _gen_accessor {
    my ( $class, $name ) = @_;

    my $default = $class->config_keys->{$name}->{default};

    my $meth = sub {
        my $self = shift;
        ( $self->{$name} ) = @_ if @_;

        if ( defined($default) && !exists $self->{$name} ) {
            $self->{$name} = ref $default ? $self->$default : $default;
        }

        return $self->{$name};
    };

    no strict 'refs';
    *{ $class . '::' . $name } = $meth;
}

1;

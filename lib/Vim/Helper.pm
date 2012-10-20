package Vim::Helper;
use strict;
use warnings;

use Carp qw/ croak /;

sub import {
    my $class = shift;
    my $caller = caller;

    my $meta = $class->new( class => $caller );
    {
        no strict 'refs';
        *{$caller . '::VH_META'} = sub { $meta };
    }

    $meta->_load_plugin( 'Help' );
    $meta->_load_plugin( $_ ) for @_;

    return $meta;
}

sub new {
    my $class = shift;
    my %config = @_;

    croak "class was not specified"
        unless $config{class};

    return bless {
        class       => $config{class},
        plugins     => {},
        plugin_list => [],
    } => $class;
}

sub class       { shift->{'class'}       }
sub plugins     { shift->{'plugins'}     }
sub plugin_list { shift->{'plugin_list'} }

sub _load_plugin {
    my $self = shift;
    my ( $plugin, $caller ) = @_;

    my $plugin_class = __PACKAGE__ . '::' . $plugin;
    eval "require $plugin_class; 1" || die $@;

    my $alias = $plugin;
    $alias =~ s/::/_/g;

    push @{$self->plugin_list} => [ $alias => $plugin_class ];

    my $config = sub {
        $self->plugins->{$alias} = $plugin_class->new(
            %{$_[0] || {}},
        );
    };

    no strict 'refs';
    *{$caller . ":\:$alias"} = $config;
}

sub _init_plugins {
    my $self = shift;
    for my $plugin ( @{ $self->plugin_list }) {
        my ( $alias, $class ) = @$plugin;
        $self->plugins->{$alias} ||= $plugin_class->new;
    }
}

sub load {
    my $self = shift;
}

sub run {
    my $self = shift;
    my @args = @_;
    $self->_init_plugins;


}

1;

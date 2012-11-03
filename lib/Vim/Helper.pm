package Vim::Helper;
use strict;
use warnings;

use Carp qw/ croak /;
require Declare::CLI;

our $VERSION = "0.001";

sub import {
    my $class = shift;
    my $caller = caller;

    my $meta = $caller->can( 'VH_META' ) ? $caller->VH_META : undef;

    croak "Could not find meta object. Did you accidentally specify a package in your config?"
        unless $meta;

    $meta->_load_plugin( $_, $caller ) for @_;

    return $meta;
}

sub new {
    my $class = shift;

    my $self = bless {
        plugins     => {},
        cli         => Declare::CLI->new(),
    } => $class;

    $self->cli->add_opt( 'config' );

    return $self;
}

sub cli     { shift->{'cli'}          }
sub plugins { shift->{'plugins'}      }
sub plugin  { $_[0]->plugins->{$_[1]} }

sub _load_plugin {
    my $self = shift;
    my ( $plugin, $caller ) = @_;

    my $plugin_class = __PACKAGE__ . '::' . $plugin;
    eval "require $plugin_class; 1" || die $@;

    my $alias = $plugin;
    $alias =~ s/::/_/g;

    $self->plugins->{$alias} = $plugin_class->new();
    my $config = sub { $self->plugins->{$alias}->config( @_ ) };

    $self->add_args( $self->plugins->{$alias}->args );
    $self->add_opts( $self->plugins->{$alias}->opts );

    no strict 'refs';
    *{$caller . ":\:$alias"} = $config;
}

sub add_opts {
    my $self = shift;
    my ( $opts ) = @_;

    $self->cli->add_opt( $_ => %{ $opts->{$_} } )
        for keys %$opts;
}

sub add_args {
    my $self = shift;
    my ( $args ) = @_;

    for my $arg ( keys %$args ) {
        my %copy = %{ $args->{$arg} };
        delete $copy{help};
        $self->cli->add_arg( $arg => %copy )
    }
}

sub run {
    my $class = shift;
    my ( @cli ) = @_;

    my $self = $class->new();
    my $package = "$class\::_Config";
    $self->_load_plugin( 'Help', $package );

    my ( $preopts ) = $self->cli->preparse( @cli );

    my $config = $preopts->{config} || "$ENV{HOME}/.config/vimph";
    croak "Could not find config file '$config'"
        unless -f $config;

    open( my $fh, "<", $config ) || die "Could not open '$config': $!\n";
    my $data = join "" => <$fh>;
    close( $fh );

    eval <<"    EOT" || die $@;
package $package;
use strict;
use warnings;

sub VH_META { \$self }

# line 0 "$config"
$data

1;
    EOT

    return $self->cli->handle( $self, @cli );
}

1;

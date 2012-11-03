package Vim::Helper::Help;
use strict;
use warnings;

sub new {
    my $class = shift;
    my ( $cli ) = @_;

    $cli->add_arg( 'help' => \&arg_help );
    $cli->add_opt( 'help', bool => 1, trigger => \&opt_help );

    return bless {} => $class;
}

sub config {
    my $self = shift;
    my ( $config ) = @_;
}

sub opt_help {
    my $helper = shift;
    print "Usage: $0 [OPTS] command [ARGS]\n\n" . $helper->cli->usage;
    exit( 0 );
}

sub arg_help {
    my $helper = shift;
    my ( $name, $opts, @args ) = @_;

    return {
        code => 0,
    };
}

1;

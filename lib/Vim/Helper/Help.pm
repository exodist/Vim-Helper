package Vim::Helper::Help;
use strict;
use warnings;

sub args {{
    help => {
        handler => \&arg_help,
        description => "Help with a specific command",
        help => "Usage: $0 help COMMAND",
    },
}}

sub opts {{
    help => {
        bool => 1,
        trigger => \&opt_help,
        description => "Show usage help"
    },
}}

sub new {
    my $class = shift;
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
    my ( $name, $opts, $command ) = @_;

    my $plugin;
    for $name ( keys %{ $helper->plugins }) {
        $plugin = $helper->plugins->{$name};
        last if $plugin->args->{$command};
        $plugin = undef;
    }

    return {
        code => 1,
        stderr => "Command not found\n",
    } unless $plugin;

    return {
        code => 0,
        stdout => $plugin->args->{$command}->{help} . "\n" || "No help available\n",
    };
}

1;

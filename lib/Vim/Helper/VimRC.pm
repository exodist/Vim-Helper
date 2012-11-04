package Vim::Helper::VimRC;
use strict;
use warnings;

use Vim::Helper::Plugin;

sub args {{
    vimrc => {
        handler => \&generate,
        description => "Generate a vimrc for your config",
        help => "Usage: $0 vimrc >> ~/.vimrc",
    }
}}

sub generate {
    my $helper = shift;
    my ( $name, $opts, @plugins ) = @_;

    @plugins = keys %{ $helper->plugins }
        unless @plugins;

    my @out;

    for my $name ( @plugins ) {
        my $plugin = $helper->plugin( $name );
        next unless $plugin->can( 'vimrc' );

        my $content = $plugin->vimrc( $helper, $opts );
        next unless $content;

        my $head = "\" Start Vim-Helper plugin: $name\n";
        my $tail = "\" End Vim-Helper plugin: $name\n";

        push @out => (
            $head,
            $content,
            $tail,
            "\n"
        );
    }

    return {
        code => 0,
        stdout => \@out,
    };
}

1;

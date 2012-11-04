package Vim::Helper::Fennec;
use strict;
use warnings;

use Carp qw/croak/;
use Vim::Helper::Plugin(
    run_key  => { default => '<F8>'  },
    less_key => { default => '<F12>' },
);

sub vimrc {
    my $self = shift;
    my ( $helper, $opts ) = @_;

    my $cmd = $helper->command( $opts );

    my $run_key  = $self->run_key;
    my $less_key = $self->less_key;

    return <<"    EOT";
function! RunFennecLine()
    let cur_line = line(".")
    exe "!FENNEC_TEST='" . cur_line . "' prove -v -Ilib -I. %"
endfunction

function! RunFennecLineLess()
    let cur_line = line(".")
    exe "!FENNEC_TEST='" . cur_line . "' prove -v -Ilib -I. % 2>&1 | less"
endfunction

:map $less_key :w<cr>:call RunFennecLineLess()<cr>
:map $run_key :w<cr>:call RunFennecLine()<cr>

:imap $less_key <ESC>:w<cr>:call RunFennecLineLess()<cr>
:imap $run_key <ESC>:w<cr>:call RunFennecLine()<cr>
    EOT
}

1;

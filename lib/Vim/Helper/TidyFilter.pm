package Vim::Helper::TidyFilter;
use strict;
use warnings;
use File::Temp qw/tempfile/;
use Carp qw/croak/;

use Vim::Helper::Plugin (
    save_rc => { required => 1 },
    load_rc => { required => 1 },
);

#<pippijn> :let o=system("echo echo \"'hello'\"")
#<pippijn> :execute o
#<pippijn> :execute system("echo echo ...etc
#<pippijn> all works here

sub args {{
    tidy_load => {
        handler => \&load,
        description => "Read perl content from stdin, tidy it, return to stdout",
        help => "Usage: INPUT | $0 load > OUTPUT",
    },
    tidy_save => {
        handler => \&save,
        description => "Read perl content from stdin, tidy it, return to stdout",
        help => "Usage: INPUT | $0 save > OUTPUT",
    },
}}

sub vimrc {
    my $self = shift;
    my ( $helper, $opts ) = @_;

    my $cmd = $helper->command( $opts );

return <<"    EOT";
function! LoadTidyFilter()
    let cur_line = line(".")
    :silent :%!$cmd tidyfilter load
    exe ":" . cur_line
endfunction

function! SaveTidyFilter()
    let cur_line = line(".")
    :silent :%!$cmd tidyfilter save
    exe ":" . cur_line
endfunction

augroup type
  auto BufReadPost  *.psgi :call LoadTidyFilter()
  auto BufWritePre  *.psgi :call SaveTidyFilter()
  auto BufWritePost *.psgi :call LoadTidyFilter()

  auto BufReadPost  *.pl :call LoadTidyFilter()
  auto BufWritePre  *.pl :call SaveTidyFilter()
  auto BufWritePost *.pl :call LoadTidyFilter()

  auto BufReadPost  *.pm :call LoadTidyFilter()
  auto BufWritePre  *.pm :call SaveTidyFilter()
  auto BufWritePost *.pm :call LoadTidyFilter()

  auto BufReadPost  *.t :call LoadTidyFilter()
  auto BufWritePre  *.t :call SaveTidyFilter()
  auto BufWritePost *.t :call LoadTidyFilter()
augroup END
    EOT
}

sub load {
    my $helper = shift;
    my $self = $helper->plugin( 'TidyFilter' );
    my ( $name, $opts ) = @_;
    $self->_tidy( $self->load_rc );
}

sub save {
    my $helper = shift;
    my $self = $helper->plugin( 'TidyFilter' );
    my ( $name, $opts ) = @_;
    $self->_tidy( $self->save_rc );
}

sub _tidy {
    my $self = shift;
    my ( $rc ) = @_;

    my ( $fhi, $tmpin )  = tempfile( UNLINK => 1 );
    my ( $fho, $tmpout ) = tempfile( UNLINK => 1 );
    close( $fho );
    
    my $content = join "" => <STDIN>;
    print $fhi $content;
    close( $fhi );
   
    # We need to unlink any existing perltidy.ERR file
    # We will run perltidy, if something unreasonable happens we abort
    unlink "perltidy.ERR";
    my $cmd = "cat '$tmpin' | perltidy -pro=\"$rc\" 1>'$tmpout'";
    system( $cmd ) && return $self->abort( $content, "Error: $!" );

    # If everything goes well we will output the tidy version, if there was a
    # problem we will output the original.

    return $self->abort( $content, "Error: found perltidy.err file" )
        if -e "perltidy.ERR";

    open( $fho, "<", $tmpout ) && $self->abort( $content, "Could not open '$tmpout': $!" );
    $content = join "" => <$fho>;
    close( $fho );

    return { code => 0, stdout => $content };
}

sub abort {
    my $self = shift;
    my ( $content, $error ) = @_;
    return {
        code => 1,
        stderr => "$error\n",
        stdout => $content,
    }
}

1;

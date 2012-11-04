package Vim::Helper::Test;
use strict;
use warnings;

use Vim::Helper::Plugin (
    from_mod  => { default => \&default_from_mod  },
    from_test => { default => \&default_from_test },
    test_key  => { default => '<Leader>gt'        },
    imp_key   => { default => '<Leader>gi'        },
);

sub args {{
    file_test => {
        handler => \&file_to_test,
        description => "Get test filename from module",
        help => "Usage: $0 file_test FILENAME",
    },
    test_imp => {
        handler => \&test_to_imp,
        description => "Get the implementation filename from the test file",
        help => "Usage: $0 test_imp FILENAME",
    },
}}

sub vimrc {
    my $self = shift;
    my ( $helper, $opts ) = @_;

    my $cmd = $helper->command( $opts );

    my $tk = $self->test_key;
    my $ik = $self->imp_key;

    return <<"    EOT";
function! GoToPerlTest()
    exe ":e `$cmd file_test %`"
endfunction

function! GoToPerlImp()
    exe ":e `$cmd test_imp %`"
endfunction

:map  $tk :call GoToPerlTest()<cr>
:imap $tk :call GoToPerlTest()<cr>

:map  $ik :call GoToPerlImp()<cr>
:imap $ik :call GoToPerlImp()<cr>
    EOT
}

sub file_to_test {
    my $helper = shift;
    my $self = $helper->plugin( 'Test' );
    my ( $name, $opts, $filename ) = @_;

    my $package = $self->package_from_file( $filename );
    
    return {
        code   => 1,
        stderr => "Could not find package declaration in '$filename'\n",
    } unless $package;

    my $file = $self->from_mod->( $filename, $package, split '::' => $package );

    return {
        code   => 0,
        stdout => "$file\n",
    } if $file;

    return {
        code   => 1,
        stderr => "Could not determine test file name.\n",
    }
}

sub test_to_imp {
    my $helper = shift;
    my ( $name, $opts, $filename ) = @_;

    my $self = $helper->plugin( 'Test' );
    my $loader = $helper->plugin( 'LoadMod' ) || do {
        require Vim::Helper::LoadMod;
        return Vim::Helper::LoadMod->new;
    };

    my $package = $self->package_from_file( $filename );

    my $file = $self->from_test->(
        $filename,
        $package,
        $package ? (split '::' => $package) : ()
    );

    my $path = $loader->find_file( $file );

    return {
        code   => 0,
        stdout => "$path\n",
    } if $path;

    return {
        code   => 1,
        stderr => "Could not determine module file name.\n",
    }
}
 
sub package_from_file {
    my $self = shift;
    my ( $filename ) = @_;
    open( my $fh, "<", $filename ) || return undef;
    while( my $line = <$fh> ) {
        next unless $line =~ m/^.*package\s+([^\s;]+)/;
        close( $fh );
        return $1;
    }
    close( $fh );
    return undef;
}

sub default_from_mod {
    my ( $filename, $modname, @modparts ) = @_;
    return 't/' . join( "-" => @modparts ) . ".t";
}

sub default_from_test {
    my ( $filename, $modname, @modparts ) = @_;
    $filename =~ s{^t/}{};
    $filename =~ s{^.*/t/}{};
    $filename =~ s{\.t$}{};
    my ( @parts ) = split '-', $filename;
    return join( '/' => @parts ) . '.pm';
}

1;

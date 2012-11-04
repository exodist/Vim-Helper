package Vim::Helper::LoadMod;
use strict;
use warnings;

use Vim::Helper::Plugin(
    search => { default => sub { [@INC] }},
    key    => { default => '<Leader>gm'  },
);

sub args {{
    'find' => {
        handler => \&loadmod,
        description => "Find a modules file name in the configured search path.",
        help => "Usage: $0 find [CHARACTER OFFSET] \"TEXT\"",
    },
}}

sub vimrc {
    my $self = shift;
    my ( $helper, $opts ) = @_;

    my $cmd = $helper->command( $opts );
    my $key = $self->key;

    return <<"    EOT";
function! PHLoadMod()
    let text=shellescape(getline("."))
    let pos=getpos('.')
    let pmod=system("$cmd find " . pos[2] . " " . text)
    if v:shell_error
        :!echo "Could not find module"
    else
        exe ":e " . pmod
    endif
endfunction

:map  $key :call PHLoadMod()<cr>
:imap $key :call PHLoadMod()<cr>
    EOT
}

sub loadmod {
    my $helper = shift;
    my $self = $helper->plugin( 'LoadMod' );
    my ( $name, $opts, $offset, $line ) = @_;

    return {
        code   => 1,
        stderr => "Must provide both an offset, and text\n",
    } unless $offset && $line;

    my @parts = split /([^A-Z0-9a-z_:\/])/, $line;
    
    my $part;
    my $track = 0;
    for ( @parts ) {
        $track += length($_);
        $part = $_ if $track >= $offset;
        last if $part;
    }
    
    my $file = $self->mod_to_file( $part );
    my $path = $self->find_file( $file );

    return {
        code   => 0,
        stdout => "$path\n",
    } if $path;
    
    return {
        code => 1,
        stderr => "File '$file' not found in search path\n"
    }
}

sub mod_to_file {
    my $self = shift;
    my ( $mod ) = @_;

    my $file = $mod;
    $file =~ s|::|/|g;
    $file .= ".pm" unless $mod =~ m/\.pm$/;

    return $file;
}

sub find_file {
    my $self = shift;
    my ( $file ) = @_;

    for my $dir ( @{$self->search} ) {
        my $test = "$dir/$file";
        $test =~ s|/+|/|g;
        return $test if -e $test;
    }

    return undef;
}

1;

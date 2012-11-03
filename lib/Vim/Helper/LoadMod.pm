package Vim::Helper::LoadMod;
use strict;
use warnings;

use Carp qw/croak/;

sub args {{
    'find' => {
        handler => \&loadmod,
        description => "Find a modules file name in the configured search path.",
        help => "Usage: $0 find [CHARACTER OFFSET] \"TEXT\"",
    },
}}

sub opts {{}}

sub new {
    my $class = shift;
    return bless {} => $class;
}

sub search { shift->{search} || [ @INC ] };

sub config {
    my $self = shift;
    my ( $config ) = @_;

    $self->{search} = $config->{search}
        if $config->{search};
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
    
    my $file = $part;
    $file =~ s|::|/|g;
    $file .= ".pm" unless $part =~ m/\.pm$/;
    
    for my $dir ( @{$self->{search}} ) {
        my $test = "$dir/$file";
        $test =~ s|/+|/|g;
        return {
            code   => 0,
            stdout => "$test\n",
        } if -e $test;
    }
    
    return {
        code => 1,
        stderr => "File '$file' not found in search path\n"
    }
}

1;

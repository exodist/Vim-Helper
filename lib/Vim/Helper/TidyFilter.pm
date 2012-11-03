package Vim::Helper::TidyFilter;
use strict;
use warnings;

sub new {
    my $class = shift;
    my ( $cli ) = @_;
    return bless {} => $class;
}

sub config {
    my $self = shift;
    my ( $config ) = @_;
}

1;

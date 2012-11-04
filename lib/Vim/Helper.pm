package Vim::Helper;
use strict;
use warnings;

use Carp qw/ croak /;
require Declare::CLI;

our $VERSION = "0.001";

for my $accessor ( qw/ cli plugins / ) {
    no strict 'refs';
    *$accessor = sub {
        my $self = shift;
        ( $self->{$accessor} ) = @_ if @_;
        return $self->{$accessor};
    };
}

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

sub plugin  { $_[0]->plugins->{$_[1]} }

sub command {
    my $self = shift;
    my ( $opts ) = @_;

    my @parts = ( $0 );

    push @parts => "-c '$opts->{config}'"
        if $opts->{config};

    return join " " => @parts;
}

sub _load_plugin {
    my $self = shift;
    my ( $plugin, $caller ) = @_;

    my $plugin_class = __PACKAGE__ . '::' . $plugin;
    eval "require $plugin_class; 1" || die $@;

    my $alias = $plugin;
    $alias =~ s/::/_/g;

    $self->plugins->{$alias} = $plugin_class->new();
    my $config = sub { $self->plugins->{$alias}->config( @_ ) };

    $self->_add_args( $self->plugins->{$alias}->args );
    $self->_add_opts( $self->plugins->{$alias}->opts );

    no strict 'refs';
    *{$caller . ":\:$alias"} = $config;
}

sub _add_opts {
    my $self = shift;
    my ( $opts ) = @_;

    $self->cli->add_opt( $_ => %{ $opts->{$_} } )
        for keys %$opts;
}

sub _add_args {
    my $self = shift;
    my ( $args ) = @_;

    for my $arg ( keys %$args ) {
        my %copy = %{ $args->{$arg} };
        delete $copy{help};
        $self->cli->add_arg( $arg => %copy )
    }
}

sub read_config {
    my $self = shift;
    my ( $opts ) = @_;

    my $config = $opts->{config} || "$ENV{HOME}/.config/vimph";
    die "Could not find config file '$config'\n"
        unless -f $config;

    open( my $fh, "<", $config ) || die "Could not open '$config': $!\n";
    my $data = join "" => <$fh>;
    close( $fh );

    return ( $data, $config );
}

our $PKG_COUNT = 1;
sub run {
    my $class = shift;
    my ( @cli ) = @_;

    my $self = $class->new();
    my $package = "$class\::_Config" . $PKG_COUNT++;
    $self->_load_plugin( 'Help', $package );
    $self->_load_plugin( 'VimRC', $package );

    my ( $preopts ) = $self->cli->preparse( @cli );
    my ( $data, $filename ) = $self->read_config( $preopts );

    eval <<"    EOT" || die $@;
package $package;
use strict;
use warnings;

sub VH_META { \$self }

# line 1 "$filename"
$data
# line 9 "eval"
1;
    EOT

    return $self->cli->handle( $self, @cli );
}
1;

__END__

=pod

=head1 NAME

Vim::Helper - Extended tools to assist working with perl in vim.

=head1 DESCRIPTION

Vim::Helper is a framework intended to integrate with vim to make working with
perl easier. It is a collection of plugins controlled by a config file that is
written in perl. The framework provides a command line tool intended to be
interfaced by vim.

Every plugin provides its own options and arguments, as well as help and vimrc
generation. Once your config file is complete you can have the tool generate
vimrc content that you can pase into your existing vimrc.

=head1 SYNOPSIS

The module is 'use'd in your config file, aside from that you do not generally
interact directly with the module.

=head2 EXAMPLE CONFIG FILE

See examples/* in the distribution for more.

~/.config/vimph:

    # use Vim::Helper with a list of plugins (Vim::Helper::[PLUGIN])
    use Vim::Helper qw/
        TidyFilter
        Test
        LoadMod
    /;

    # Each plugin is given a configuration function which is the plugin name,
    # '::' is replaced with '_' for plugins with deeper paths.
    # Each plugin config function takes a hashref of options. Options are plugin
    # specific.

    Test {
        from_mod => sub {
            my ( $filename, $modname, @modparts ) = @_;
            return 't/' . join( "-" => @modparts ) . ".t";
        },
        from_test => sub {
            my ( $filename, $modname, @modparts ) = @_;
            $filename =~ s{^t/}{};
            $filename =~ s{^.*/t/}{};
            $filename =~ s{\.t$}{};
            my ( @parts ) = split '-', $filename;
            return join( '/' => @parts ) . '.pm';
        },
    };

    TidyFilter {
        save_rc => '~/.config/perltidysaverc',
        load_rc => '~/.config/perltidyloadrc',
    };

    LoadMod {
        search => [ "./lib", @INC ],
    };

=head2 GENERATING VIMRC

    $ scripts/vimph vimrc

The above command will output content that can be inserted directly into a
.vimrc file.

=head1 PLUGINS

There are several plugins included with the Vim::Helper distribution.
Additional plugins are easy to write.

=head2 INCLUDED PLUGINS

=over 4

=item Fennec

L<Vim::Helper::Fennec> - For use with L<Fennec> based test suites.

=item LoadMod

L<Vim::Helper::LoadMod> - Used to load the perl module that the cursor is
sitting on. Move the cursor over the module name C<... My::Module ...> and hit
the configured key, the module will be found and opened.

=item Test

L<Vim::Helper::Test> - Used to interact with tests. PRovides keys for
automatically finding and opening test files when you are in modules, and
vice-versa.

=item TidyFilter

L<Vim::Helper::TidyFilter> - Used to run perltidy on your files automatically
when you open, save, or close them. You can use seperate tidy configs for
loading/saving.

A good use of this is if you are sane and prefer space for indentation, but
your team requires tabs be used. You can edit in your style, and save to the
teams style.

=item VimRC

B<Loaded automatically, no config options.>

L<Vim::Helper::VimRC> - Used to generate the vimrc content.

=item Help

B<Loaded automatically, no config options.>

L<Vim::Helper::Help> - Used to generate help output.

=back

=head2 WRITING PLUGINS

See L<Vim::Helper::Plugin> for more details.

=head1 META MODEL



=head2 METHODS

=head1 AUTHORS

Chad Granum L<exodist7@gmail.com>

=head1 COPYRIGHT

Copyright (C) 2012 Chad Granum

Vim-Helper is free software; Standard perl licence.

Vim-Helper is distributed in the hope that it will be useful, but WITHOUT
ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS
FOR A PARTICULAR PURPOSE. See the license for more details.

=cut


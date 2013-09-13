package Tickit::DSL;
# ABSTRACT: shortcuts for writing Tickit apps
use strict;
use warnings;
use parent qw(Exporter);

our $VERSION = '0.004';

=head1 NAME

Tickit::DSL - domain-specific language for Tickit terminal apps

=head1 VERSION

version 0.004

=head1 SYNOPSIS

 use Tickit::DSL;
 vbox {
  hbox { static 'left' } expand => 1;
  hbox { static 'right' } expand => 1;
 }

=head1 DESCRIPTION

WARNING: This is an early version, has an experimental API, and is
subject to change in future. Please get in contact and/or wait for 1.0 if you want something stable.

Provides a simplified interface for writing Tickit applications. This is
mainly intended for prototyping:

 #!/usr/bin/env perl
 use strict;
 use warnings;
 use Tickit::DSL;
 
 vbox {
  # Single line menu at the top of the screen
  menubar {
   submenu File => sub {
    menuitem Open  => sub { warn 'open' };
    menuspacer;
    menuitem Exit  => sub { tickit->stop };
   };
   submenu Edit => sub {
    menuitem Copy  => sub { warn 'copy' };
    menuitem Cut   => sub { warn 'cut' };
    menuitem Paste => sub { warn 'paste' };
   };
   menuspacer;
   submenu Help => sub {
    menuitem About => sub { warn 'about' };
   };
  };
  # A 2-panel layout covers most of the rest of the display
  widget {
   # Left and right panes:
   vsplit {
    # A tree on the left, 1/4 total width
    widget {
     placeholder;
    } expand => 1;
    # and a tab widget on the right, 3/4 total width
    widget {
     tabbed {
      widget { placeholder } label => 'First thing';
 	};
    } expand => 3;
   } expand => 1;
  } expand => 1;
  # At the bottom of the screen we show the status bar
  # statusbar { } show => [qw(clock cpu memory debug)];
  # although it's not on CPAN yet so we don't
 };
 tickit->run;

=cut

use Tickit::Widget::Border;
use Tickit::Widget::Box;
use Tickit::Widget::Button;
use Tickit::Widget::CheckButton;
use Tickit::Widget::Entry;
use Tickit::Widget::Frame;
use Tickit::Widget::GridBox;
use Tickit::Widget::HBox;
use Tickit::Widget::HSplit;
use Tickit::Widget::Menu;
use Tickit::Widget::MenuBar;
use Tickit::Widget::Menu::Item;
use Tickit::Widget::Placegrid;
use Tickit::Widget::Progressbar;
use Tickit::Widget::RadioButton;
use Tickit::Widget::Scroller;
use Tickit::Widget::Scroller::Item::Text;
use Tickit::Widget::ScrollBox;
use Tickit::Widget::SegmentDisplay;
use Tickit::Widget::SparkLine;
use Tickit::Widget::Spinner;
use Tickit::Widget::Static;
use Tickit::Widget::Statusbar;
use Tickit::Widget::Tabbed;
use Tickit::Widget::Table;
use Tickit::Widget::Tree;
use Tickit::Widget::VBox;
use Tickit::Widget::VSplit;

# Not on CPAN yet...
# use Tickit::Widget::Table::Paged;

use List::UtilsBy qw(extract_by);

our $MODE;
our $PARENT;
our @PENDING_CHILD;
our $TICKIT;
our $LOOP;
our @WIDGET_ARGS;
our $GRID_COL;
our $GRID_ROW;

our @EXPORT = our @EXPORT_OK = qw(
	tickit later loop
	widget customwidget
	add_widgets
	gridbox gridrow
	vbox hbox
	vsplit hsplit
	static entry
	scroller scroller_text
	scrollbox
	tabbed
	tree
	table
	placeholder
	statusbar
	menubar submenu menuitem menuspacer
);

=head2 import

By default we'll import all the known widget shortcuts. To override this, pass a list
(possibly empty) on import:

 use Tickit::DSL qw();

By default, the synchronous L<Tickit> class will be used. You can make L</tickit> refer
to a L<Tickit::Async> object instead by passing the C< :async > tag:

 use Tickit::DSL qw(:async);

the default is C< :sync >, but you can make this explicit:

 use Tickit::DSL qw(:sync);

There is currently no support for mixing the two styles in a single application - if
C< :async > or C< :sync > have already been passed to a previous import, attempting
to apply the opposite one will cause an exception.

This is fine:

 use Tickit::DSL qw(:sync);
 use Tickit::DSL qw();
 use Tickit::DSL;

This is not:

 use Tickit::DSL qw(:sync);
 use Tickit::DSL qw(:async); # will raise an exception

=cut

sub import {
	my $class = shift;
	my ($mode) = extract_by { /^:a?sync$/ } @_;
	if($MODE && $mode && $mode ne $MODE) {
		die "Cannot mix sync/async - we are already $MODE and were requested to switch to $mode";
	} elsif($mode) {
		$MODE = $mode;
	}
	$MODE ||= ':sync';
	if($MODE eq ':sync') {
		require Tickit;
	} elsif($MODE eq ':async') {
		require IO::Async::Loop;
		require Tickit::Async;
	} else {
		die "Unknown mode: $MODE";
	}
    $class->export_to_level(1, $class, @_);
}
=head1 FUNCTIONS

All of these are exported unless otherwise noted.

=cut

=head2 loop

Returns the L<IO::Async::Loop> instance if we're in C< :async > mode, throws an
exception if we're not. See L</import> for details.

=cut

sub loop {
	die "No loop available when running as $MODE" unless $MODE eq ':async';
	$LOOP = shift if @_;
	$LOOP ||= IO::Async::Loop->new
}

=head2 tickit

Returns (constructing if necessary) the L<Tickit> (or L<Tickit::Async>) instance.

=cut

sub tickit {
	$TICKIT = shift if @_;
	return $TICKIT if $TICKIT;

	if($MODE eq ':async') {
		$TICKIT = Tickit::Async->new;
		loop->add($TICKIT);
	} else {
		$TICKIT ||= Tickit->new;
	}
	$TICKIT
}

=head2 later

Defers a block of code.

 later {
  print "this happened later\n";
 };

Will run the code after the next round of I/O events.

=cut

sub later(&) {
	my $code = shift;
	tickit->later($code)
}

=head2 add_widgets

Adds some widgets under an existing widget.

 my $some_widget = vbox { };
 add_widgets {
  vbox { ... };
  hbox { ... };
 } under => $some_widget;

Returns the widget we added the new widgets under (i.e. the C< under > parameter).

=cut

sub add_widgets(&@) {
	my $code = shift;
	my %args = @_;
	local $PARENT = delete $args{under} or die 'expected add_widgets { ... } under => $some_widget;';
	local @WIDGET_ARGS = %args;
	$code->($PARENT);
	$PARENT;
}

=head2 vbox

Creates a L<Tickit::Widget::VBox>. This is a container, so the first
parameter is a coderef which will switch the current parent to the new
vbox.

Any additional parameters will be passed to the new L<Tickit::Widget::VBox>
instance:

 vbox {
   ...
 } class => 'some_vbox';
 vbox {
   ...
 } classes => [qw(other vbox)], style => { fg => 'green' };

=cut

sub vbox(&@) {
	my ($code, %args) = @_;
	my $w = Tickit::Widget::VBox->new(%args);
	{
		local $PARENT = $w;
		$code->($w);
	}
	apply_widget($w);
}

=head2 vsplit

Creates a L<Tickit::Widget::VSplit>. This is a container, so the first
parameter is a coderef which will switch the current parent to the new
widget. Note that this widget expects 2 child widgets only.

Any additional parameters will be passed to the new L<Tickit::Widget::VSplit>
instance:

 vsplit {
   ...
 } class => 'some_vsplit';
 vsplit {
   ...
 } classes => [qw(other vsplit)], style => { fg => 'green' };

=cut

sub vsplit(&@) {
	my ($code, %args) = @_;
	my $w = do {
		local $PARENT = 'Tickit::Widget::VSplit';
		local @PENDING_CHILD;
		$code->();
		Tickit::Widget::VSplit->new(
			left_child  => $PENDING_CHILD[0],
			right_child => $PENDING_CHILD[1],
			%args,
		);
	};
	apply_widget($w);
}

=head2 gridbox

Creates a L<Tickit::Widget::GridBox>. This is a container, so the first
parameter is a coderef which will switch the current parent to the new
widget.

Although any widget is allowed here, you'll probably want all the immediate
children to be L</gridrow>s.

Any additional parameters will be passed to the new L<Tickit::Widget::GridBox>
instance:

 gridbox {
   gridrow { static 'left'; static 'right' };
   gridrow { static 'BL'; static 'BR' };
 } style => { col_spacing => 1, row_spacing => 1 };

=cut

sub gridbox(&@) {
	my ($code, %args) = @_;
	my $w = Tickit::Widget::GridBox->new(%args);
	{
		local $PARENT = $w;
		local $GRID_COL = 0;
		local $GRID_ROW = 0;
		$code->($w);
	}
	apply_widget($w);
}

=head2 gridrow

Marks a separate row in an existing L<Tickit::Widget::GridBox>. This behaves
something like a container, see L</gridbox> for details.

=cut

sub gridrow(&@) {
	my ($code) = @_;
	die "Grid rows must be in a gridbox" unless $PARENT->isa('Tickit::Widget::GridBox');
	$code->($PARENT);
	$GRID_COL = 0;
	++$GRID_ROW;
}

=head2 hbox

Creates a L<Tickit::Widget::HBox>. This is a container, so the first
parameter is a coderef which will switch the current parent to the new
hbox.

Any additional parameters will be passed to the new L<Tickit::Widget::HBox>
instance:

 hbox {
   ...
 } class => 'some_hbox';
 hbox {
   ...
 } classes => [qw(other hbox)], style => { fg => 'green' };

=cut

sub hbox(&@) {
	my ($code, %args) = @_;
	my $w = Tickit::Widget::HBox->new(%args);
	{
		local $PARENT = $w;
		$code->($w);
	}
	apply_widget($w);
}

=head2 hsplit

Creates a L<Tickit::Widget::HSplit>. This is a container, so the first
parameter is a coderef which will switch the current parent to the new
widget. Note that this widget expects 2 child widgets only.

Any additional parameters will be passed to the new L<Tickit::Widget::HSplit>
instance:

 hsplit {
   ...
 } class => 'some_hsplit';
 hsplit {
   ...
 } classes => [qw(other hsplit)], style => { fg => 'green' };

=cut

sub hsplit(&@) {
	my ($code, %args) = @_;
	my $w = do {
		local $PARENT = 'Tickit::Widget::HSplit';
		local @PENDING_CHILD;
		$code->();
		Tickit::Widget::HSplit->new(
			top_child    => $PENDING_CHILD[0],
			bottom_child => $PENDING_CHILD[1],
			%args
		);
	};
	apply_widget($w);
}

=head2 scrollbox

Creates a L<Tickit::Widget::ScrollBox>. This is a container, so the first
parameter is a coderef which will switch the current parent to the new
widget. Note that this widget expects a single child widget only.

Any additional parameters will be passed to the new L<Tickit::Widget::ScrollBox>
instance:

 scrollbox {
   ...
 } class => 'some_hsplit';

=cut

sub scrollbox(&@) {
	my ($code, %args) = @_;
	my $w = do {
		local $PARENT = 'Tickit::Widget::ScrollBox';
		local @PENDING_CHILD;
		$code->();
		
		Tickit::Widget::ScrollBox->new(
			child => $PENDING_CHILD[0],
			%args
		);
	};
	apply_widget($w);
}

=head2 scroller

Adds a L<Tickit::Widget::Scroller>. Contents are probably going to be L</scroller_text>
for now.

 scroller {
   scroller_text 'line ' . $_ for 1..500;
 };

Passes any additional args to the constructor:

 scroller {
   scroller_text 'line ' . $_ for 1..100;
 } gravity => 'bottom';

=cut

sub scroller(&@) {
	my ($code, %args) = @_;
	my $w = Tickit::Widget::Scroller->new(%args);
	{
		local $PARENT = $w;
		$code->($w);
	}
	apply_widget($w);
}

=head2 scroller_text

A text item, expects to be added to a L</scroller>.

=cut

sub scroller_text {
	my $w = Tickit::Widget::Scroller::Item::Text->new(shift // '');
	apply_widget($w);
}

=head2 tabbed

Creates a L<Tickit::Widget::Tabbed> instance. Use the L</widget> wrapper
to set the label when adding new tabs.

 tabbed {
   widget { static 'some text' } label => 'first tab';
   widget { static 'other text' } label => 'second tab';
 };

If you want a different ribbon, pass it like so:

 tabbed {
   widget { static 'some text' } label => 'first tab';
   widget { static 'other text' } label => 'second tab';
 } ribbon_class => 'Some::Ribbon::Class', tab_position => 'top';

The C<ribbon_class> parameter may be undocumented.

=cut

sub tabbed(&@) {
	my ($code, %args) = @_;
	my $w = Tickit::Widget::Tabbed->new(%args);
	{
		local $PARENT = $w;
		$code->($w);
	}
	apply_widget($w);
}

=head2 statusbar

A L<Tickit::Widget::Statusbar>. Not very exciting.

=cut

sub statusbar(&@) {
	my ($code, %args) = @_;
	my $w = Tickit::Widget::Statusbar->new(%args);
	{
		local $PARENT = $w;
		$code->($w);
	}
	apply_widget($w);
}

=head2 static

Static text. Very simple:

 static 'some text';

You can be more specific if you want:

 static 'some text', align => 'center';

=cut

sub static {
	my %args = (text => @_);
	$args{text} //= '';
	my $w = Tickit::Widget::Static->new(
		%args
	);
	apply_widget($w);
}

=head2 entry

A L<Tickit::Widget::Entry> input field. Takes a coderef as the first parameter
since the C<on_enter> handler seems like an important feature.

 my $rslt = static 'result here';
 entry { shift; $rslt->set_text(eval shift) } text => '1 + 3';

=cut

sub entry(&@) {
	my %args = (on_enter => @_);
	my $w = Tickit::Widget::Entry->new(
		%args
	);
	apply_widget($w);
}

=head2 tree

A L<Tickit::Widget::Tree>. If it works I'd be amazed.

=cut

sub tree(&@) {
	my %args = (on_enter => @_);
	my $w = Tickit::Widget::Tree->new(
		%args
	);
	apply_widget($w);
}

=head2 placeholder

Use this if you're not sure which widget you want yet. It's a L<Tickit::Widget::Placegrid>,
so there aren't many options.

 placeholder;
 vbox {
   widget { placeholder } expand => 3;
   widget { placeholder } expand => 5;
 };

=cut

sub placeholder() {
	apply_widget(Tickit::Widget::Placegrid->new);
}

=head2 menubar

Menubar courtesy of L<Tickit::Widget::MenuBar>. Every self-respecting app wants
one of these.

 menubar {
  submenu File => sub {
   menuitem Exit  => sub { tickit->stop };
  };
  menuspacer;
  submenu Help => sub {
   menuitem About => sub { warn 'about' };
  };
 };

=cut

sub menubar(&@) {
	my ($code, %args) = @_;
	my $w = Tickit::Widget::MenuBar->new(%args);
	{
		local $PARENT = $w;
		$code->($w);
	}
	apply_widget($w);
}

=head2 submenu

A menu entry in a L</menubar>. First parameter is used as the label,
second is the coderef to populate the widgets (will be called immediately).

See L</menubar>.

=cut

sub submenu {
	my ($text, $code) = splice @_, 0, 2;
	my $w = Tickit::Widget::Menu->new(name => $text);
	{
		local $PARENT = $w;
		$code->($w);
	}
	apply_widget($w);
}

=head2 menuspacer

Adds a spacer if you're in a menu. No idea what it'd do if you're not in a menu.

=cut

sub menuspacer() {
	my $w = Tickit::Widget::Menu->separator;
	apply_widget($w);
}

=head2 menuitem

A menu is not much use without something in it. See L</menubar>.

=cut

sub menuitem {
	my ($text, $code) = splice @_, 0, 2;
	my $w = Tickit::Widget::Menu::Item->new(
		name        => $text,
		on_activate => $code,
		@_
	);
	apply_widget($w);
}

=head2 customwidget

A generic function for adding 'custom' widgets - i.e. anything that's not already
supported by this module.

This will call the coderef, expecting to get back a L<Tickit::Widget>, then it'll
apply that widget to whatever the current parent is. Any options will be passed
as widget arguments, see L</widget> for details.

 customwidget {
  my $tbl = Tickit::Widget::Table::Paged->new;
  $tbl->add_column(...);
  $tbl;
 } expand => 1;

=cut

sub customwidget(&@) {
	my ($code, @args) = @_;
	my %args = @args;
	local $PARENT = delete($args{parent}) || $PARENT;
	my $w = $code->($PARENT);
	{
		local @WIDGET_ARGS = %args;
		apply_widget($w);
	}
}

=head2 widget

Many container widgets provide support for additional options when adding child widgets.
For example, a L<Tickit::Widget::VBox> can take an C<expand> parameter which determines
how space should be allocated between children.

This function provides a way to pass those options - use it as a wrapper around another
widget-generating function, like so:

 widget { static 'this is text' } expand => 1;

in context, this would be:

 vbox {
   widget { static => '33%' } expand => 1;
   widget { static => '66%' } expand => 2;
 };

=cut

sub widget(&@) {
	my ($code, @args) = @_;
	my %args = @args;
	local $PARENT = delete($args{parent}) || $PARENT;
	{
		local @WIDGET_ARGS = @args;
		$code->($PARENT);
	}
}

=head2 apply_widget

Internal function used for applying the given widget.

Not exported.

=cut

sub apply_widget {
	my $w = shift;
	if($PARENT) {
		if($PARENT->isa('Tickit::Widget::Scroller')) {
			$PARENT->push($w);
		} elsif($PARENT->isa('Tickit::Widget::Menu')) {
			$PARENT->push_item($w, @WIDGET_ARGS);
		} elsif($PARENT->isa('Tickit::Widget::MenuBar')) {
			$PARENT->push_item($w, @WIDGET_ARGS);
		} elsif($PARENT->isa('Tickit::Widget::HSplit')) {
			push @PENDING_CHILD, $w;
		} elsif($PARENT->isa('Tickit::Widget::VSplit')) {
			push @PENDING_CHILD, $w;
		} elsif($PARENT->isa('Tickit::Widget::ScrollBox')) {
			push @PENDING_CHILD, $w;
		} elsif($PARENT->isa('Tickit::Widget::Tabbed')) {
			$PARENT->add_tab($w, @WIDGET_ARGS);
		} elsif($PARENT->isa('Tickit::Widget::GridBox')) {
			$PARENT->add($GRID_ROW, $GRID_COL++, $w, @WIDGET_ARGS);
		} else {
			$PARENT->add($w, @WIDGET_ARGS);
		}
	} else {
		tickit->set_root_widget($w);
	}
	$w
}

1;

__END__

=head1 SEE ALSO

=over 4

=item * L<Tickit::Widget::Border>

=item * L<Tickit::Widget::Box>

=item * L<Tickit::Widget::Button>

=item * L<Tickit::Widget::CheckButton>

=item * L<Tickit::Widget::Entry>

=item * L<Tickit::Widget::Frame>

=item * L<Tickit::Widget::GridBox>

=item * L<Tickit::Widget::HBox>

=item * L<Tickit::Widget::HSplit>

=item * L<Tickit::Widget::Menu>

=item * L<Tickit::Widget::Placegrid>

=item * L<Tickit::Widget::Progressbar>

=item * L<Tickit::Widget::RadioButton>

=item * L<Tickit::Widget::Scroller>

=item * L<Tickit::Widget::Scroller::Item::Text>

=item * L<Tickit::Widget::ScrollBox>

=item * L<Tickit::Widget::SegmentDisplay>

=item * L<Tickit::Widget::SparkLine>

=item * L<Tickit::Widget::Static>

=item * L<Tickit::Widget::Statusbar>

=item * L<Tickit::Widget::Tabbed>

=item * L<Tickit::Widget::Table>

=item * L<Tickit::Widget::Tree>

=item * L<Tickit::Widget::VBox>

=item * L<Tickit::Widget::VSplit>

=back

=head1 AUTHOR

Tom Molesworth <cpan@entitymodel.com>

=head1 LICENSE

Copyright Tom Molesworth 2012-2013. Licensed under the same terms as Perl itself.

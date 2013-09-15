
use strict;
use warnings;

use 5.010001;

use ExtUtils::MakeMaker 6.48;



my %WriteMakefileArgs = (
  "ABSTRACT" => "shortcuts for writing Tickit apps",
  "AUTHOR" => "Tom Molesworth <cpan\@entitymodel.com>",
  "BUILD_REQUIRES" => {},
  "CONFIGURE_REQUIRES" => {
    "ExtUtils::MakeMaker" => "6.48"
  },
  "DISTNAME" => "Tickit-DSL",
  "EXE_FILES" => [],
  "LICENSE" => "perl",
  "NAME" => "Tickit::DSL",
  "PREREQ_PM" => {
    "Future" => "0.15",
    "List::UtilsBy" => 0,
    "Mixin::Event::Dispatch" => "1.000",
    "Tickit" => "0.37",
    "Tickit::Widget::Decoration" => "0.001",
    "Tickit::Widget::Menu" => "0.05",
    "Tickit::Widget::Progressbar" => "0.002",
    "Tickit::Widget::ScrollBox" => "0.01",
    "Tickit::Widget::Scroller" => "0.12",
    "Tickit::Widget::SegmentDisplay" => "0.01",
    "Tickit::Widget::SparkLine" => "0.001",
    "Tickit::Widget::Statusbar" => "0.001",
    "Tickit::Widget::Tabbed" => "0.010",
    "Tickit::Widget::Table" => "0.100",
    "Tickit::Widget::Tree" => "0.002",
    "Tickit::Widgets" => "0.12",
    "Try::Tiny" => 0,
    "curry" => 0,
    "parent" => 0
  },
  "TEST_REQUIRES" => {
    "IO::Handle" => 0,
    "IPC::Open3" => 0,
    "Test::CheckDeps" => "0.006",
    "Test::Fatal" => "0.010",
    "Test::More" => "0.98"
  },
  "VERSION" => "0.007",
  "test" => {
    "TESTS" => "t/*.t"
  }
);


unless ( eval { ExtUtils::MakeMaker->VERSION(6.63_03) } ) {
  my $tr = delete $WriteMakefileArgs{TEST_REQUIRES};
  my $br = $WriteMakefileArgs{BUILD_REQUIRES};
  for my $mod ( keys %$tr ) {
    if ( exists $br->{$mod} ) {
      $br->{$mod} = $tr->{$mod} if $tr->{$mod} > $br->{$mod};
    }
    else {
      $br->{$mod} = $tr->{$mod};
    }
  }
}

unless ( eval { ExtUtils::MakeMaker->VERSION(6.56) } ) {
  my $br = delete $WriteMakefileArgs{BUILD_REQUIRES};
  my $pp = $WriteMakefileArgs{PREREQ_PM};
  for my $mod ( keys %$br ) {
    if ( exists $pp->{$mod} ) {
      $pp->{$mod} = $br->{$mod} if $br->{$mod} > $pp->{$mod};
    }
    else {
      $pp->{$mod} = $br->{$mod};
    }
  }
}

delete $WriteMakefileArgs{CONFIGURE_REQUIRES}
  unless eval { ExtUtils::MakeMaker->VERSION(6.52) };

WriteMakefile(%WriteMakefileArgs);




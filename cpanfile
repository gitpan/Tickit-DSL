requires 'parent', 0;
requires 'curry', 0;
requires 'Future', '>= 0.15';
requires 'Try::Tiny', 0;
requires 'List::UtilsBy', 0;
requires 'Mixin::Event::Dispatch', '>= 1.000';

requires 'Tickit', '>= 0.37';
requires 'Tickit::Widgets', '>= 0.12';
requires 'Tickit::Widget::Decoration', '>= 0.001';
requires 'Tickit::Widget::Menu', '>= 0.05';
requires 'Tickit::Widget::Progressbar', '>= 0.002';
requires 'Tickit::Widget::Scroller', '>= 0.12';
requires 'Tickit::Widget::ScrollBox', '>= 0.01';
requires 'Tickit::Widget::SegmentDisplay', '>= 0.01';
requires 'Tickit::Widget::SparkLine', '>= 0.001';
requires 'Tickit::Widget::Statusbar', '>= 0.001';
requires 'Tickit::Widget::Tabbed', '>= 0.010';
requires 'Tickit::Widget::Table', '>= 0.100';
requires 'Tickit::Widget::Tree', '>= 0.002';

on 'test' => sub {
	requires 'Test::More', '>= 0.98';
	requires 'Test::Fatal', '>= 0.010';
};


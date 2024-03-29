use strict;
use warnings;
use Test::More 0.88;
# This is a relatively nice way to avoid Test::NoWarnings breaking our
# expectations by adding extra tests, without using no_plan.  It also helps
# avoid any other test module that feels introducing random tests, or even
# test plans, is a nice idea.
our $success = 0;
END { $success && done_testing; }

# List our own version used to generate this
my $v = "\nGenerated by Dist::Zilla::Plugin::ReportVersions::Tiny v1.10\n";

eval {                     # no excuses!
    # report our Perl details
    my $want = '5.010001';
    $v .= "perl: $] (wanted $want) on $^O from $^X\n\n";
};
defined($@) and diag("$@");

# Now, our module version dependencies:
sub pmver {
    my ($module, $wanted) = @_;
    $wanted = " (want $wanted)";
    my $pmver;
    eval "require $module;";
    if ($@) {
        if ($@ =~ m/Can't locate .* in \@INC/) {
            $pmver = 'module not found.';
        } else {
            diag("${module}: $@");
            $pmver = 'died during require.';
        }
    } else {
        my $version;
        eval { $version = $module->VERSION; };
        if ($@) {
            diag("${module}: $@");
            $pmver = 'died during VERSION check.';
        } elsif (defined $version) {
            $pmver = "$version";
        } else {
            $pmver = '<undef>';
        }
    }

    # So, we should be good, right?
    return sprintf('%-45s => %-10s%-15s%s', $module, $pmver, $wanted, "\n");
}

eval { $v .= pmver('Exporter','any version') };
eval { $v .= pmver('ExtUtils::MakeMaker','6.48') };
eval { $v .= pmver('File::Spec','any version') };
eval { $v .= pmver('IO::Handle','any version') };
eval { $v .= pmver('IPC::Open3','any version') };
eval { $v .= pmver('List::UtilsBy','any version') };
eval { $v .= pmver('Test::CheckDeps','0.010') };
eval { $v .= pmver('Test::More','0.98') };
eval { $v .= pmver('Tickit','0.46') };
eval { $v .= pmver('Tickit::Async','any version') };
eval { $v .= pmver('Tickit::Console','0.06') };
eval { $v .= pmver('Tickit::Widget::Breadcrumb','0.002') };
eval { $v .= pmver('Tickit::Widget::Decoration','0.004') };
eval { $v .= pmver('Tickit::Widget::FileViewer','0.004') };
eval { $v .= pmver('Tickit::Widget::FloatBox','0.02') };
eval { $v .= pmver('Tickit::Widget::Layout::Desktop','0.005') };
eval { $v .= pmver('Tickit::Widget::Layout::Relative','0.005') };
eval { $v .= pmver('Tickit::Widget::Menu','0.08') };
eval { $v .= pmver('Tickit::Widget::Progressbar','0.101') };
eval { $v .= pmver('Tickit::Widget::ScrollBox','0.03') };
eval { $v .= pmver('Tickit::Widget::Scroller','0.18') };
eval { $v .= pmver('Tickit::Widget::SegmentDisplay','0.02') };
eval { $v .= pmver('Tickit::Widget::SparkLine','0.104') };
eval { $v .= pmver('Tickit::Widget::Statusbar','0.004') };
eval { $v .= pmver('Tickit::Widget::Tabbed','0.016') };
eval { $v .= pmver('Tickit::Widget::Table','0.207') };
eval { $v .= pmver('Tickit::Widget::Tree','0.108') };
eval { $v .= pmver('Tickit::Widgets','0.19') };
eval { $v .= pmver('parent','any version') };


# All done.
$v .= <<'EOT';

Thanks for using my code.  I hope it works for you.
If not, please try and include this output in the bug report.
That will help me reproduce the issue and solve your problem.

EOT

diag($v);
ok(1, "we really didn't test anything, just reporting data");
$success = 1;

# Work around another nasty module on CPAN. :/
no warnings 'once';
$Template::Test::NO_FLUSH = 1;
exit 0;

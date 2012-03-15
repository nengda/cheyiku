#!/home/y/bin/perl

use strict;
use warnings;

use File::Basename;

my $flex_home = $ENV{FLEX_HOME};
die "\$FLEX_HOME is not defined\n" unless $flex_home;

my @mxml_files = split(/\n/, `find . -name '*.mxml'`);
my @as_files = split(/\n/, `find . -name '*.as'`);

my @classes;
foreach my $mxml (@mxml_files) {
    $mxml = $1 if $mxml =~ /^(.*)\.mxml$/i;
    $mxml =~ s/^\.\///;
    my @tokens = split(/\//, $mxml);
    push @classes, join('.', @tokens);
}
foreach my $as (@as_files) {
    $as = $1 if $as =~ /^(.*)\.as$/i;
    $as =~ s/^\.\///;
    my @tokens = split(/\//, $as);
    push @classes, join('.', @tokens);
}

my $cmd = $flex_home . "/bin/compc -output=DTSFlexLib.swc -source-path=. -include-classes=" . join(',', @classes);
system($cmd) == 0 || die "Failed compiling DTSFlexLib\n";

exit;

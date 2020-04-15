#/usr/bin/env perl
use t::TestUtils;
use Test::More;
use Rex::Dondley::ProcessTaskArgs;

my $tests = 1; # keep on line 17 for ,i (increment and ,d (decrement)
diag( "Running my tests" );

my @modules = qw/ Moose /;
#my @methods = qw/ BUILD /;
#my %attribs = (
#   'attr'  => { type    => 'Str', lazy => 0, read => 'ro', req => 0,
#                default => '', },
#);

plan tests => $tests;

# class tests
subtest 'module checks'   => \&module_check, @modules;
#subtest 'attribute check' => \&attrib_check, ('Rex::Dondley::ProcessTaskArgs', \%attribs);
#subtest 'method checks'   => \&method_check, ('Rex::Dondley::ProcessTaskArgs', @methods);

# create an object
my $obj = Rex::Dondley::ProcessTaskArgs->new();

use strictures 1;
use lib 't/lib';
use Test::More tests => 3;
use_ok 'AnonMethodsExample';

my $obj = AnonMethodsExample->new;

isa_ok $obj, 'AnonMethodsExample';

is $obj->some_closure()->(), 1, 'simple closure';

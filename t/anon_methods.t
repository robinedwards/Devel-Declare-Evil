use strictures 1;
use lib 't/lib';
use Test::More tests => 4;
use_ok 'AnonExample';

my $obj = AnonExample->new;

isa_ok $obj, 'AnonExample';

my $code = $obj->some_closure;

is ref ($code), 'CODE', 'got closure';

is $obj->$code(), 1, 'simple closure';

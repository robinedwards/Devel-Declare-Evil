use strictures 1;
use lib 't/lib';
use Test::More tests => 6;
use_ok 'AnonExample';

my $obj = AnonExample->new;

isa_ok $obj, 'AnonExample';

{
    my $code = $obj->test_closure1;
    is ref ($code), 'CODE', 'got closure';
    is $obj->$code(), 1, 'simple closure';
}

{
    my $code = $obj->test_closure2;
    is ref ($code), 'CODE', 'got closure';
    is $obj->$code(1,1), 2, 'simple closure';
}



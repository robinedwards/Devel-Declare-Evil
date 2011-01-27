use strictures 1;
use lib 't/lib';
use Test::More tests => 7;
use_ok 'EvilMethods';
use_ok 'Example';

is Example->test_method, 1, 'method keyword works';
is Example->test_method_with_signature(1,1), 2, 'method signatures work';

my $obj = Example->new({});
ok defined $obj, "construction works";
is $obj->test_method, 1, 'method keyword works';
is $obj->test_method_with_signature(1,1), 2, 'method signature works';
#is $obj->test_edge_case1, 1;

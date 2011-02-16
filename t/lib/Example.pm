package Example;
use lib 't/lib';
use strictures 1;
use EvilMethods;

method new {
    return bless {}, $self;
}

method test_method_with_signature ($a, $b) {
    return $a + $b;
}

method test_method {
    return 1 if $self;
}

method test_edge_case1{
    return 1;
}
 
method test_edge_case2($a) {
    return 1;
}


method test_edge_case3($a){
    return 1;
}

method test_edge_case4 
{
    return 1;
}

method test_edge_case5 
($a,
$b,
$c)

{
    return 1 + $a + $b + $c;
}

method test_edge_case6
(

)
{
    return 1;
}

method test_edge_case7 {
    1
}method test_edge_case8 {
    1
}

1;

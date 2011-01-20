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

1;

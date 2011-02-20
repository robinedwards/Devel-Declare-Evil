package AnonExample;
use lib 't/lib';
use strictures 1;
use MethodKeyword;

sub new { return bless {}, __PACKAGE__; }

sub test_closure1 {
    my $self = shift;
    return method {
        return 1 if $self;
    }
}

sub test_closure2 {
    my $self = shift;
    return method ($a, $b) {
        die "FIXME";
        return ($a + $b) if $self;
    }
}

1;

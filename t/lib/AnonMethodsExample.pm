package AnonMethodsExample;
use lib 't/lib';
use strictures 1;
use EvilMethods;

sub new { return bless {}, __PACKAGE__; }

sub some_closure {
    my $self = shift;
    return method {
        return 1 if $self;
    };
}

1;

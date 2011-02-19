package MethodKeyword;
use strictures 1;
use base 'Devel::Declare::Evil';

sub import { shift->install(name => 'method', into => caller) }

sub named_inject {
    my ($self) = @_;

    return "sub $self->{name} {\n my (\$self"
        . unroller($self->tokens);    
};

sub anonymous_inject {
    my ($self) = @_;

    return 'my ($self'.unroller($self->tokens);
}

sub unroller {
    my (@tokens) = @_;

    my $snippet = join '', @tokens;
    my $unroll = ') = @_;';

    if ($snippet =~ m/\s*\((.+)\)\s+/s) {
        $unroll = ", $1) = \@_;";
    }

    return $unroll;
}

1;

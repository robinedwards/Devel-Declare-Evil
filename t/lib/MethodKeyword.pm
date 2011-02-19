package MethodKeyword;
use strictures 1;
use B::Hooks::EndOfScope;
use Filter::Util::Call;
use base 'Devel::Declare::Evil';
use namespace::autoclean;

sub import { shift->install(name => 'method', into => caller) }

sub named_inject {
    my ($self) = @_;

    return "sub $self->{name} {\n my (\$self"
        . unroller($self->tokens);    
};

sub anonymous_inject {
    my ($self) = @_;

    return 'BEGIN { MethodKeyword::anonymous_eos }'
    .' my ($self' . unroller($self->tokens);
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

sub anonymous_eos {
    on_scope_end {
        Filter::Util::Call::filter_add(sub {
                my $status = Filter::Util::Call::filter_read();

                warn "read: $_";
                return $status;
            }
        );
    };
}

1;

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

    return 
    'BEGIN { MethodKeyword::anonymous_eos('
    . $self->is_anonymous . ') }'
    .' my ($self' . unroller($self->tokens);
}

sub unroller {
    (join ('', @_) =~ m/\s*\((.+)\)\s+/s) ? ", $1) = \@_;" : ') = @_;';
}

sub anonymous_eos {
    my ($close_brace) = @_;
    on_scope_end {
        warn "called $close_brace\n";
        Filter::Util::Call::filter_add(sub {
                my $status = Filter::Util::Call::filter_read(1);
                return $status unless $status;

                die "expecting end of block??!" unless $_ eq '}';
                $_ = $close_brace == 1 ? '});' : '};'; 

                Filter::Util::Call::filter_del();
                return 1;
            }
        );
    };
}

1;

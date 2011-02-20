package MethodKeyword;
use strictures 1;
use B::Hooks::EndOfScope;
use Data::Dumper;
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
    my $code = 'BEGIN { MethodKeyword::anonymous_eos('
        . $self->is_anonymous . ') };';

    if ($self->is_anonymous == 1) {
        $code = 'sub { ' . $code;
    }

    return $code . ' my ($self' . unroller($self->tokens);
}

sub unroller {
    my ($roll, $r) = join ('', @_) =~ /\s*\(?(.+)\)(.*)/ms; 
    $r =~ s/{/ / if $r;
    return ($roll ? ", $roll) = \@_;" : ') = @_;'). ($r || '');
}

sub anonymous_eos {
    my ($close_brace) = @_;
    on_scope_end {
        Filter::Util::Call::filter_add(sub {
                my $status = Filter::Util::Call::filter_read_exact(1);
                return $status unless $status;

                $_ = (($close_brace == 1) ? ');' : ';' ) . $_; 

                Filter::Util::Call::filter_del();
                return 1;
            }
        );
    };
}

1;

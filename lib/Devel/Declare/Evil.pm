package Devel::Declare::Evil;
use strictures 1;
require Filter::Util::Call;

sub import {
    my ($class,$keyword) = @_;

    die "usage: use Devel::Declare::Evil 'keyword';" 
        unless $keyword;

    my $keyword_class = caller;

    # install targets import sub;
    no strict 'refs';
    *{"${keyword_class}::filter"} = _gen_filter($keyword_class, $keyword);
    *{"${keyword_class}::import"} = _gen_target_import($keyword_class, $keyword);
}


sub _gen_target_import {
    my ($keyword_class, $keyword) = @_;

    return sub {
        my $target = caller;
    
        my $glob = do { no strict 'refs'; \*{"${target}::$keyword"} };
        *{$glob} = sub (*) { };

        my $object = bless {
            tokens => [], globref => $glob, sent => 0, target => $target,
        }, $keyword_class;

        use B 'svref_2object';

        install_filter($object);
    };
}

sub install_filter {
    my ($object) = @_;
    Filter::Util::Call::real_import($object, ref($object), 0);
}

sub _gen_filter {
    my ($keyword_class, $keyword) = @_;

    return sub {
        my ($self) = @_;

        # if we have a new keyword
        # ( ref count increases ) as method; is written out
        if (my $rc = delete $self->{refcount_was}) {
            if (svref_2object($self->{globref})->REFCNT > $rc) {
                my $code = $self->generate_code($self->{name}, $self->{tokens});
                $self->{tokens} = [];
                $self->{tokens}[0] = "; $code";
            }
        }

        $self->{sent}-- if $self->{sent};

        if($self->{sent} == 2) {
            ($self->{name}) = $self->{tokens}[0] =~ /\s?(.*)/;
        }

        if ($self->{sent} == 1) {
            install_filter($self); # install filter again with reset sent
            $self->{sent} = 0;
            $self->{refcount_was} = svref_2object($self->{globref})->REFCNT;
            return 0;
        }

        # write out whatever we have tokens
        if (@{$self->{tokens}}) {
            $_ = shift(@{$self->{tokens}});
            return 1;
        }

        my $status = Filter::Util::Call::filter_read();
        return $status unless $status;

        # tokenize line
        my ($first, @save) = split(/(?=\s)/, $_);
        $self->{tokens} = \@save;

        $_ = $first; # right out first word.

        # spotted keyword
        $self->{sent} = 3 if ($first eq $keyword); 

        return 1;
    }
}

1;

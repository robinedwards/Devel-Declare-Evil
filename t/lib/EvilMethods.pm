package EvilMethods;
use strictures 1;
use Data::Dumper;
use Devel::Declare::Evil 'method';

sub parse_signature {
    my ($self, $signature) = @_;
    my @stack = split /\,\s?/, $signature;
    my $unroll = join ', ', @stack;
    return ", $unroll) = \@_;";
}

sub generate_code {
    my ($self, $name, $tokens) = @_;

    my $snippet = join ' ', @$tokens;
    my $unroll = ') = @_;';

    if ($snippet =~ /^\s*\((.+)\)/) {
        $unroll = $self->parse_signature($1);
    }

    return "sub $name {\n my (\$self $unroll";    
}

1;

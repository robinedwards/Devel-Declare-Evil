package EvilMethods;
use strictures 1;
use Devel::Declare::Evil;

keyword method => sub {
    my ($class, $name, $tokens) = @_;

    return "sub $name {\n my (\$self"
        . unroller($tokens);    
};

sub anon_code_generator {
    my ($class, $tokens) = @_;

    return 'my ($self'.unroller($tokens);
}

sub unroller {
    my ($tokens) = @_;

    my $snippet = join '', @$tokens;
    my $unroll = ') = @_;';

    if ($snippet =~ m/\s*\((.+)\)\s+/s) {
        $unroll = ", $1) = \@_;";
    }

    return $unroll;
}

1;

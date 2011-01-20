package EvilMethods;
use strictures 1;
use Devel::Declare::Evil;

keyword method => sub {
    my ($class, $name, $tokens) = @_;

    my $snippet = join ' ', @$tokens;
    my $unroll = ') = @_;';

    if ($snippet =~ /^\s*\((.+)\)/) {
        $unroll = ", $1) = \@_;";
    }

    return "sub $name {\n my (\$self $unroll";    
};

1;

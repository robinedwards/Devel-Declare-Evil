package Devel::Declare::Evil;
use strict;
use warnings;
use Data::Dumper;
#use strictures 1;
require Filter::Util::Call;

our $VERSION = 0.0001;

sub import {
    no strict 'refs';
    *{caller()."::keyword"} = *keyword;
}

sub keyword (@) {
    my ($keyword, $code) = @_;

    my $keyword_class = caller;

    # install filter, code_generator, import subs
    no strict 'refs';
    *{"${keyword_class}::filter"} = _gen_filter($keyword_class, $keyword);
    *{"${keyword_class}::import"} = _gen_target_import($keyword_class, $keyword);
    *{"${keyword_class}::code_generator"} = $code;
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

        $self->{sent}-- if $self->{sent};

        # ( ref count increases ) as method is written out
        if (my $rc = delete $self->{refcount_was}) {
            if (svref_2object($self->{globref})->REFCNT > $rc) {
                
                while (!_start_of_block($self->{tokens})) {
                    my $status = Filter::Util::Call::filter_read();
                    return $status unless $status;
                    push @{$self->{tokens}}, $_;
                    $_ = '';
                }

                my $code = $keyword_class->code_generator(
                    $self->{name}, $self->{tokens}
                );

                delete $self->{tokens};
                $self->{tokens}[0] = "; $code";
            }
        }

        # reinstall filter
        if ($self->{sent} == 1) {
            $self->{sent} = 0;
            install_filter($self);
            $self->{refcount_was} = svref_2object($self->{globref})->REFCNT;
            return 0;
        }

        # write out a token
        if (@{$self->{tokens}}) {

            my $toke = shift @{$self->{tokens}};

            if ($self->{sent} == 2) {
                # write out anything that isn't part of bareword in second pass.
                if(my ($ident, $stuff) = $toke =~ /(\s?\w+)(\W.*)/){
                    $self->{tokens}[0] = $stuff . $self->{tokens}[0];
                    $toke = $ident;
                }

                ($self->{name}) = $toke =~ /\s?(.*)/;
            }

            $_ = $toke;
            return 1;
        }

        my $status = Filter::Util::Call::filter_read();
        return $status unless $status;
        
        # don't tokenize lines that don't have a keyword
        return 1 if ($self->{sent} == 0 && $_ !~ /$keyword/);

        # tokenize line
        my ($first, @save) = split(/(?=\s)/, $_);
        $self->{tokens} = \@save;
        
        # spotted keyword
        if ($first =~ /$keyword(.*)/) {
            $_ = $keyword;

            if (my $extra = $1) {
                unshift @{$self->{tokens}}, $extra;

                if ($extra =~ /^[\(|\{]/) {
                    $self->{is_anon} = 1;
                }
            }

            $self->{sent} = 3
        }

        return 1;
    }
}

sub _start_of_block {
    for my $tok (@{shift()}) {
        return 1 if $tok =~ /\{/;
    }
}

1;

__END__

=head1 NAME

Devel::Declare::Evil - safe keywords using a source filter.

=head1 SYNOPSIS

    package EvilMethods;
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

    # Somewhere in another file
    package Bob;
    use EvilMethods;

    method new {
        return bless {}, $self;
    }

    method say_hello ($name) {
       say "Hi, $name!"; 
    }

    1;

=head1 EXPERIMENTAL

This module is not at all robust (yet) the following cases will break it: 

- Injection into anonymous blocks (not supported yet)
- New lines in signatures
- No whitespace after method name

=head1 HOW IT WORKS

Installs an empty sub with a glob prototype for your keyword. Then records the current reference count of the keywords symbol.
Filters through your code using Filter::Util::Call when a keyword is reached it's sent on to the perl interpreter.
As the interpreter recognises the prototype the ref count for the symbol increases, allowing safe execution of your filter.
The filter closes the call to the keyword and injects whatever code it needed.
For the previous example the compiler actually ends up interpreting:

    method; sub say_hello { my ($self, $name) = @_; ... }

=head1 SEE ALSO

Devel::Declare

=head1 CODE

Adapted from Matt Trout's Evil.pm:

http://sherlock.scsys.co.uk/~matthewt/evil.pm.txt

http://github.com/robinedwards/Devel-Declare-Evil

=head1 AUTHORS

Matt S Trout - E<lt>mst@shadowcat.co.ukE<gt> - original author of Evil.pm E<gt>

Robin Edwards, E<lt>robin.ge@gmail.comE<gt> - abstracted it into this module

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2010 by Robin Edwards

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.12.1 or,
at your option, any later version of Perl 5 you may have available.

=cut

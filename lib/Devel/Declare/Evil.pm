package Devel::Declare::Evil;
use strictures 1;
use List::Util 'first';
use B 'svref_2object';
require Filter::Util::Call;

our $VERSION = 0.0001;

sub install {
    my ($class, %args) = @_;

    my $target  = $args{into};
    my $keyword = $args{name};

    my $glob = do { no strict 'refs'; \*{"${target}::$keyword"} };

    my $filter = bless {
        keyword => $keyword,
        tokens  => [], 
        globref => $glob, 
        target  => $target,
        is_anonymous => 0,
    }, $class;

    $class->_install_filter($filter);
}

sub tokens          { @{$_[0]->{tokens}} }
sub keyword         { $_[0]->{keyword} }
sub name            { $_[0]->{name} }
sub is_anonymous    { $_[0]->{is_anonymous} }

sub _install_filter {
    $_[1]->{refcount_was} = svref_2object($_[1]->{globref})->REFCNT;
    $_[1]->{sent}         = 0;
    Filter::Util::Call::real_import($_[1], ref($_[1]), 0);
}

sub filter {
    my ($self) = @_;

    $self->{sent}-- if $self->{sent};

    # ( ref count increases ) as method is matched
    if (my $rc = delete $self->{refcount_was}) {
        if (svref_2object($self->{globref})->REFCNT > $rc) {

            unless ($self->is_anonymous == 2) { 
                return unless $self->_scan_till_block;
            }

            my $code = ($self->is_anonymous > 0)
                ? $self->anonymous_inject
                : "; ". $self->named_inject;

            $self->{tokens} = [$code];
        }
    }

    # reinstall filter
    if ($self->{sent} == 1) {
        $self->_install_filter($self);
        return 0;
    }

    # write out a token
    if ($self->tokens) {
        my $toke = shift @{$self->{tokens}};

        if ($self->{sent} == 2) {
            if(my ($ident, $stuff) = $toke =~ /(\s?\w+)(\W.*)/){
                $self->{tokens}[0] = $stuff . $self->{tokens}[0];
                $toke = $ident;
            }

            if(($self->{name}) = $toke =~ /\s?(\w+)/) {
                *{$self->{globref}} = sub (*) {};
            } else {
                $self->{is_anonymous} = 1 if $toke =~ /\s?\(/;
                $self->{is_anonymous} = 2 if $toke =~ /^\s?\{/;

                *{$self->{globref}} = sub (&) {shift};
            }
        }

        $_ = $toke;
        return 1;
    }

    my $status = Filter::Util::Call::filter_read();
    return $status unless $status;
    return 1 if ($self->{sent} == 0 && $_ !~ $self->keyword);

    $self->{tokens} = [ split /(?=\s)/, $_ ];

    $_ = '';

    # write out tokens till keyword found
    while (my $tok = shift @{$self->{tokens}}) {
        if ($tok !~ $self->keyword) {
            $_ .= $tok;
        } else {
            # TODO handler method{ / method( / ;method
            $_ .= $tok;

            $self->{sent} = 3;
            return 1;
        }
    }
}

sub _scan_till_block {
    my ($self) = @_;

    while (!first { /\{/ } $self->tokens) {
        my $status = Filter::Util::Call::filter_read();
        return $status unless $status;
        
        push @{$self->{tokens}}, $_;
        $_ = '';
    }

    return 1;
}

1;

__END__

=head1 NAME

Devel::Declare::Evil - safe keywords using a source filter.

=head1 SYNOPSIS
    package MethodKeyword;
    use base 'Devel::Declare::Evil';

    sub import { shift->install(name => 'method', into => caller) }

    sub named_inject {
        my ($self) = @_;

        return "sub $self->{name} {\n my (\$self"
            . unroller($self->tokens);    
    };

    sub unroller {
        my (@tokens) = @_;

        my $snippet = join '', @tokens;
        my $unroll = ') = @_;';

        if ($snippet =~ m/\s*\((.+)\)\s+/s) {
            $unroll = ", $1) = \@_;";
        }

        return $unroll;
    }

    # Somewhere in another file
    package Bob;
    use MethodKeyword;

    method say_hello ($name) {
       say "Hi, $name!"; 
    }

=head1 HOW IT WORKS

- Install an empty sub with a glob prototype for a keyword

- Record current reference count of the keywords symbol.

- Filter through code using Filter::Util::Call feeding code on to the perl interpeter one token at a time.

- As the interpreter recognises the prototype the ref count for the symbol increases, allowing safe injection.

- The filter closes the call to the keyword and injects whatever code it needed.

- For the synopsis example the compiler actually ends up interpreting:

    method; sub say_hello { my ($self, $name) = @_; ... }

=head1 METHODS

=head2 tokens - array of read tokens

=head2 keyword

=head2 name - name of sub

=head2 is_anonymous 

=head1 SEE ALSO

Devel::Declare

=head1 CODE

Adapted from Matt Trout's Evil.pm:

http://sherlock.scsys.co.uk/~matthewt/evil.pm.txt

http://github.com/robinedwards/Devel-Declare-Evil

=head1 AUTHORS

Matt S Trout - E<lt>mst@shadowcat.co.ukE<gt> - original author of Evil.pm E<gt>

Robin Edwards, E<lt>robin.ge@gmail.comE<gt> - adapted concept into this module.

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2010 by Robin Edwards

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5 or,
at your option, any later version of Perl 5 you may have available.

=cut


package HTML::Tidy;

use 5.006001;
use strict;
use warnings;

use HTML::Tidy::Error;

=head1 NAME

HTML::Tidy - Web validation in a Perl object

=head1 VERSION

Version 0.00_02

    $Header: /home/cvs/html-tidy/lib/HTML/Tidy.pm,v 1.11 2004/02/18 06:20:28 andy Exp $

=cut

our $VERSION = "0.00_02";

=head1 SYNOPSIS

  use HTML::Tidy;
  blah blah blah

=head1 DESCRIPTION


=cut

require Exporter;

our @ISA = qw(Exporter DynaLoader);

=head1 METHODS

=head2 new()

Create an HTML::Lint object.

    my $tidy = HTML::Tidy->new();

=cut

sub new {
    my $class = shift;

    my $self = {
        errors => [],
    };

    bless $self, $class;

    return $self;
}

=head2 errors()

Returns the errors accumulated.

=cut

sub errors {
    my $self = shift;

    return @{$self->{errors}};
}

=head2 clear_errors()

Clears the list of errors, in case you want to print and clear, print and clear.

=cut

sub clear_errors {
    my $self = shift;

    $self->{errors} = [];
}

=head2 parse_file( $filename, $str [, $str...] )

=cut

sub parse_file {
    my $self = shift;
    my $filename = shift;

    my $html = join( "", @_ );

    my $back = _calltidy( $html );
    my @lines = split( /\n/, $back );

    for my $line ( @lines ) {
        my ($lineno,$col,$msg) = ($line =~ /^line (\d+) column (\d+) - (.+)/);

        my $error = HTML::Tidy::Error->new( $filename, $lineno, $col, $msg );
        push( @{$self->{errors}}, $error );
    }

    return $back;
}

require XSLoader;
XSLoader::load('HTML::Tidy', $VERSION);

1;

__END__

=head1 BUGS & FEEDBACK

I welcome your comments and suggestions.  Please send them to
C<< <bug-html-tidy@rt.cpan.org> >> so that they can be tracked in the
RT ticket tracking system.

=head1 AUTHOR

Andy Lester, C<< <andy@petdance.com> >>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2004 by Andy Lester

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.1 or,
at your option, any later version of Perl 5 you may have available.

=cut

# $Id: Error.pm,v 1.4 2004/02/18 05:51:47 andy Exp $
package HTML::Tidy::Error;

use strict;

=head1 NAME

HTML::Tidy::Error - Error object for the Tidy functionality

=head1 SYNOPSIS

See L<HTML::Tidy> for all the gory details.

=head1 EXPORTS

None.  It's all object-based.

=head1 METHODS

Almost everything is an accessor.

=head2 new( $file, $line, $column, $message )

Create an object.  It's not very exciting.

=cut

sub new {
    my $class = shift;

    my $file = shift;
    my $line = shift;
    my $column = shift;
    my $message = shift;

    # Add an element that says what tag caused the error (B, TR, etc)
    # so that we can match 'em up down the road.
    my $self  = {
        _file => $file,
        _line => $line,
        _column => $column,
        _message => $message,
    };

    bless $self, $class;

    return $self;
}

=head2 where()

Returns a formatted string that describes where in the file the
error has occurred.

For example,

    (14:23)

for line 14, column 23.

The terrible thing about this function is that it's both a plain
ol' formatting function as in

    my $str = where( 14, 23 );

AND it's an object method, as in:

    my $str = $error->where();

I don't know what I was thinking when I set it up this way, but
it's bad practice.

=cut

sub where {
    my $self = shift;

    return sprintf( "(%d:%d)", $self->line, $self->column );
}

=head2 as_string()

Returns a nicely-formatted string for printing out to stdout or some similar user thing.

=cut

sub as_string {
    my $self = shift;

    return sprintf( "%s %s %s", $self->file, $self->where, $self->message );
}

=head2 file()

Returns the filename of the error, as set by the caller.

=head2 line()

Returns the line number of the error.

=head2 column()

Returns the column number, starting from 0

=head2 message()

Returns the HTML::Tidy message.

=cut

sub file        { my $self = shift; return $self->{_file}       || '' }
sub line        { my $self = shift; return $self->{_line}       || '' }
sub column      { my $self = shift; return $self->{_column}     || '' }
sub message     { my $self = shift; return $self->{_message}    || '' }


=head1 LICENSE

This code may be distributed under the same terms as Perl itself.

Please note that these modules are not products of or supported by the
employers of the various contributors to the code.

=head1 AUTHOR

Andy Lester, C<< <andy@petdance.com> >>

=cut

1; # happy

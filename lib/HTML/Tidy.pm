package HTML::Tidy;

use 5.006001;
use strict;
use warnings;

use HTML::Tidy::Message;

=head1 NAME

HTML::Tidy - Web validation in a Perl object

=head1 VERSION

Version 1.01

    $Header: /home/cvs/html-tidy/lib/HTML/Tidy.pm,v 1.33 2004/02/29 17:41:29 andy Exp $

=cut

our $VERSION = "1.01_01";

=head1 SYNOPSIS

    use HTML::Tidy;

    my $tidy = new HTML::Tidy;
    $tidy->ignore( type => TIDY_WARNING );
    $tidy->parse( "foo.html", $contents_of_foo );

    for my $message ( $tidy->messages ) {
        print $message->as_string;
    }

=head1 Description

C<HTML::Tidy> is an HTML checker in a handy dandy object.  It's meant as
a replacement for L<HTML::Lint>.  If you're currently an L<HTML::Lint>
user looking to migrate, see the section L<Converting from HTML::Lint>.

=head1 Exports

Message types C<TIDY_WARNING> and C<TIDY_ERROR>.

Everything else is an object method.

=cut

require Exporter;

our @ISA = qw( Exporter DynaLoader );

use constant TIDY_ERROR => 2;
use constant TIDY_WARNING => 1;

our @EXPORT = qw( TIDY_ERROR TIDY_WARNING );

=head1 Methods

=head2 new()

Create an HTML::Lint object.

    my $tidy = HTML::Tidy->new();

=cut

sub new {
    my $class = shift;

    my $self = {
        messages => [],
        ignore_type => [],
        ignore_text => [],
    };

    bless $self, $class;

    return $self;
}

=head2 messages()

Returns the messages accumulated.

=cut

sub messages {
    my $self = shift;

    return @{$self->{messages}};
}

=head2 clear_messages()

Clears the list of messages, in case you want to print and clear, print
and clear.  If you don't clear the messages, then each time you call
L<parse()> you'll be accumulating more in the list.

=cut

sub clear_messages {
    my $self = shift;

    $self->{messages} = [];
}

=head2 ignore( parm => value [, parm => value ] )

Specify types of messages to ignore.  Note that the ignore flags must be
set B<before> calling C<parse()>.  You can call C<ignore()> as many times
as necessary to set up all your restrictions; the options will stack up.

=over 4

=item * type => TIDY_(WARNING|ERROR)

Specifies the type of messages you want to ignore, either warnings
or errors.  If you wanted, you could call ignore on both and get no
messages at all.

    $tidy->ignore( type => TIDY_WARNING );

=item * text => qr/regex/

=item * text => [ qr/regex1/, qr/regex2/, ... ]

Checks the text of the message against the specified regex or regexes,
and ignores the message if there's a match.  The value for the I<text>
parm may be either a regex, or a reference to a list of regexes.

    $tidy->ignore( text => qr/DOCTYPE/ );
    $tidy->ignore( text => [ qr/unsupported/, qr/proprietary/i ] );

=back

=cut

sub ignore {
    my $self = shift;
    my @parms = @_;

    while ( @parms ) {
        my $parm = shift @parms;
        my $value = shift @parms;
        my @values = ref($value) eq "ARRAY" ? @$value : ($value);

        die "Invalid ignore type of \"$parm\"" unless ($parm eq "text") or ($parm eq "type");

        push( @{$self->{"ignore_$parm"}}, @values );
    } # while
} # ignore

=head2 parse( $filename, $str [, $str...] )

Parses a string, or list of strings, that make up a single HTML file.

The I<$filename> parm is only used as an identifier for your use.
The file is not actually read and opened.

Returns true if all went OK, or false if there was some problem calling
tidy, or parsing tidy's output.

=cut

sub parse {
    my $self = shift;
    my $filename = shift;

    my $parse_errors;
    my $html = join( "", @_ );

    my $errorblock = _calltidy( $html );
    return unless defined $errorblock;

    my @lines = split( /\012/, $errorblock );
    for my $line ( @lines ) {
        chomp $line;

        my $message;
        if ( $line =~ /^line (\d+) column (\d+) - (Warning|Error): (.+)$/ ) {
            my $type = ($3 eq "Warning") ? TIDY_WARNING : TIDY_ERROR;
            $message = HTML::Tidy::Message->new( $filename, $type, $1, $2, $4 );

        } elsif ( $line =~ /^\d+ warnings?, \d+ errors? were found!/ ) {
            # Summary line we don't want

        } elsif ( $line eq "No warnings or errors were found." ) {
            # Summary line we don't want

        } else {
            warn "Unknown error type: $line";
            ++$parse_errors;
        }
        push( @{$self->{messages}}, $message ) if $self->_is_keeper( $message );
    }

    return !$parse_errors;
}

# Tells whether a given message object is one that we should keep.

sub _is_keeper {
    my $self = shift;

    my $message = shift;

    my @ignore_types = @{$self->{ignore_type}};
    if ( @ignore_types ) {
        my $type = $message->type;
        return if grep { $type == $_ } @ignore_types;
    }

    my @ignore_texts = @{$self->{ignore_text}};
    if ( @ignore_texts ) {
        my $text = $message->text;
        return if grep { $text =~ $_ } @ignore_texts;
    }

    return 1;
}

require XSLoader;
XSLoader::load('HTML::Tidy', $VERSION);

1;

__END__

=head1 Converting From HTML::Lint

L<HTML::Tidy> is different from L<HTML::Lint> in a number of crucial ways.

=over 4

=item * It's not pure Perl

C<HTML::Tidy> is mostly a happy wrapper around libtidy.

=item * The real work is done by someone else

Changes to libtidy may come down the pipe that I don't have control over.
That's the price we pay for having it do a darn good job.

=item * It's no longer bundled with its C<Test::> counterpart

L<HTML::Lint> came bundled with C<Test::HTML::Lint>, but
L<Test::HTML::Tidy> is a separate distribution.  This saves the people
who don't want the C<Test::> framework from pulling it in, and all its
prerequisite modules.

=back

=head1 Bugs & Feedback

I welcome your comments and suggestions.  Please send them to
C<< <bug-html-tidy@rt.cpan.org> >> so that they can be tracked in the
RT ticket tracking system.

=head1 Author

Andy Lester, C<< <andy@petdance.com> >>

=head1 Copyright & License

Copyright (C) 2004 by Andy Lester

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.1 or,
at your option, any later version of Perl 5 you may have available.

=cut

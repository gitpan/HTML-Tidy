package HTML::Tidy;

use 5.006001;
use strict;
use warnings;
use Carp ();

use HTML::Tidy::Message;

=head1 NAME

HTML::Tidy - (X)HTML validation in a Perl object

=head1 VERSION

Version 1.08

=cut

our $VERSION = '1.08';

=head1 SYNOPSIS

    use HTML::Tidy;

    my $tidy = HTML::Tidy->new( {config_file => 'path/to/config'} );
    $tidy->ignore( type => TIDY_WARNING );
    $tidy->parse( "foo.html", $contents_of_foo );

    for my $message ( $tidy->messages ) {
        print $message->as_string;
    }

=head1 DESCRIPTION

C<HTML::Tidy> is an HTML checker in a handy dandy object.  It's meant as
a replacement for L<HTML::Lint|HTML::Lint>.  If you're currently an L<HTML::Lint|HTML::Lint>
user looking to migrate, see the section L</Converting from HTML::Lint>.

=head1 EXPORTS

Message types C<TIDY_WARNING> and C<TIDY_ERROR>.

Everything else is an object method.

=cut

use base 'Exporter';

use constant TIDY_ERROR   => 2;
use constant TIDY_WARNING => 1;

our @EXPORT = qw( TIDY_ERROR TIDY_WARNING );

=head1 METHODS

=head2 new()

Create an HTML::Tidy object.

    my $tidy = HTML::Tidy->new();

Optionally you can give a hashref of configuration parms.

    my $tidy = HTML::Tidy->new( {config_file => 'path/to/tidy.cfg'} );

This configuration file will be read and used when you clean or parse an HTML file.

You can also pass options directly to libtidy.

    my $tidy = HTML::Tidy->new( {
                                    output_xhtml => 1,
                                    tidy_mark => 0,
                                } );

See L<http://tidy.sourceforge.net/docs/quickref.html> or 
C<tidy -help-config> for the list of options supported by libtidy.

The following options are not supported by C<HTML::Tidy>:
quiet

=cut

sub new {
    my $class = shift;
    my $args = shift || {};
    my @unsupported_options = qw(
        force-output
        gnu-emacs-file
        gnu-emacs
        keep-time
        quiet
        slide-style
        write-back
    ); # REVIEW perhaps a list of supported options would be better

    my $self = bless {
        messages => [],
        ignore_type => [],
        ignore_text => [],
        config_file => '',
        tidy_options => {},
    }, $class;

    for my $key (keys %{$args} ) {
        if ($key eq 'config_file') {
            $self->{config_file} = $args->{$key};
            next;
        }

        my $newkey = $key;
        $newkey =~ tr/_/-/;

        if ( grep {$newkey eq $_} @unsupported_options ) {
            croak( "Unsupported option: $newkey" );
        }

        $self->{tidy_options}->{$newkey} = $args->{$key};
    }

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
L<parse()|parse( $filename, $str [, $str...] )> you'll be accumulating more in the list.

=cut

sub clear_messages {
    my $self = shift;

    $self->{messages} = [];

    return;
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
        my @values = ref($value) eq 'ARRAY' ? @{$value} : ($value);

        Carp::croak( qq{Invalid ignore type of "$parm"} )
            unless ($parm eq 'text') or ($parm eq 'type');

        push( @{$self->{"ignore_$parm"}}, @values );
    } # while

    return;
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
    if (@_ == 0) {
        croak('Usage: parser($filename,$str [, $str...])') ## no critic
    }
    my $html = join( '', @_ );

    utf8::encode($html) unless utf8::is_utf8($html);
    my ($errorblock,$newline) = _tidy_messages( $html,
                                                $self->{config_file},
                                                $self->{tidy_options}
                                              );
    utf8::decode($errorblock);

    return unless defined $errorblock;
    return !$self->_parse_errors($filename, $errorblock, $newline);
}

sub _parse_errors {
    my $self = shift;
    my $filename = shift;
    my $errs = shift;
    my $newline = shift;

    my $parse_errors;

    my @lines = split( /$newline/, $errs );

    for my $line ( @lines ) {
        chomp $line;

        my $message;
        if ( $line =~ /^line (\d+) column (\d+) - (Warning|Error): (.+)$/ ) {
            my ($line, $col, $type, $text) = ($1, $2, $3, $4);
            $type = ($type eq 'Warning') ? TIDY_WARNING : TIDY_ERROR;
            $message = HTML::Tidy::Message->new( $filename, $type, $line, $col, $text );

        }
        elsif ( $line =~ /^\d+ warnings?, \d+ errors? were found!/ ) {
            # Summary line we don't want

        }
        elsif ( $line eq 'No warnings or errors were found.' ) {
            # Summary line we don't want

        }
        elsif ( $line eq 'This document has errors that must be fixed before' ) {
            # Summary line we don't want

        }
        elsif ( $line eq 'using HTML Tidy to generate a tidied up version.' ) {
            # Summary line we don't want

        }
        elsif ( $line =~ m/^Info:/  ) {
            # Info line we don't want

        }
        elsif ( $line =~ m/^\s*$/  ) {
            # Blank line we don't want

        }
        else {
            Carp::carp "Unknown error type: $line";
            ++$parse_errors;
        }
        push( @{$self->{messages}}, $message )
            if $message && $self->_is_keeper( $message );
    } # for
    return $parse_errors;
}

=head2 clean( $str [, $str...] )

Cleans a string, or list of strings, that make up a single HTML file.

Returns the cleaned string as a single string.

=cut

sub clean {
    my $self = shift;
    if (@_ == 0) {
        croak('Usage: clean($str [, $str...])') ## no critic
    }
    my $text = join( '', @_ );

    utf8::encode($text) unless utf8::is_utf8($text);
    if ( defined $text ) {
        $text .= "\n";
    }

    my ($cleaned, $errbuf, $newline) = _tidy_clean( $text,
                                          $self->{config_file},
                                          $self->{tidy_options});
    utf8::decode($cleaned);
    utf8::decode($errbuf);

    $self->_parse_errors('', $errbuf, $newline);
    return $cleaned;
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

=head2 libtidy_version()

    $version = HTML::Tidy->libtidy_version();
    # for example -> "1 September 2005"
    $version = HTML::Tidy->libtidy_version( { numeric => 1 } );
    # for example -> 20050901

Returns the version of the underling tidy library.

=cut

sub libtidy_version {
    my $self = shift;
    my $args = shift || {};

    my $version_str = _tidy_release_date();

    return $version_str unless $args->{numeric};

    my @version = split(/\s+/,$version_str);

    my %months = (
        January =>  1,  February =>  2,  March => 3,
        April   =>  4,  May      =>  5,  June => 6,
        July    =>  7,  August   =>  8,  September => 9,
        October => 10,  November => 11,  December => 12,
    );
    my $month = $months{$version[1]};

    return  10_000 * $version[2]
           +   100 * $month
           +         $version[0];
}

require XSLoader;
XSLoader::load('HTML::Tidy', $VERSION);

1;

__END__

=head1 INSTALLING LIBTIDY

L<HTML::Tidy|HTML::Tidy> requires that C<libtidy> be installed on your system.
You can obtain libtidy through your distribution's package manager
(make sure you install the development package with headers), or from
the libtidy website at L<http://tidy.sourceforge.net/src/tidy_src.tgz>.

=head1 CONVERTING FROM C<HTML::Lint>

L<HTML::Tidy|HTML::Tidy> is different from L<HTML::Lint|HTML::Lint> in a number of crucial ways.

=over 4

=item * It's not pure Perl

C<HTML::Tidy> is mostly a happy wrapper around libtidy.  Tidy's home
page is at L<http://tidy.sourceforge.net>.

=item * The real work is done by someone else

Changes to libtidy may come down the pipe that I don't have control over.
That's the price we pay for having it do a darn good job.

=item * It's no longer bundled with its C<Test::> counterpart

L<HTML::Lint|HTML::Lint> came bundled with C<Test::HTML::Lint>, but
L<Test::HTML::Tidy|Test::HTML::Tidy> is a separate distribution.  This saves the people
who don't want the C<Test::> framework from pulling it in, and all its
prerequisite modules.

=back

=head1 BUGS & FEEDBACK

Please report any bugs or feature requests to
C<bug-html-tidy at rt.cpan.org>, or through the web interface at
L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=HTML-Tidy>.
I will be notified, and then you'll automatically be notified of progress on
your bug as I make changes.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc HTML::Tidy

You can also look for information at:

=over 4

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/HTML-Tidy>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/HTML-Tidy>

=item * RT: CPAN's request tracker

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=HTML-Tidy>

=item * Search CPAN

L<http://search.cpan.org/dist/HTML-Tidy>

=item * Subversion source code repository

L<http://code.google.com/p/html-tidy/source>

=back

=head1 ACKNOWLEDGEMENTS

Thanks to Jonathan Rockway and Robert Bachmann for contributions.

=head1 AUTHOR

Andy Lester, C<< <andy at petdance.com> >>

=head1 COPYRIGHT & LICENSE

Copyright (C) 2005-2007 by Andy Lester

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.1 or,
at your option, any later version of Perl 5 you may have available.

=cut

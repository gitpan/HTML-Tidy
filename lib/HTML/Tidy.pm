package HTML::Tidy;

use 5.006001;
use strict;
use warnings;

use HTML::Tidy::Message;

=head1 NAME

HTML::Tidy - Web validation in a Perl object

=head1 VERSION

Version 0.02

    $Header: /home/cvs/html-tidy/lib/HTML/Tidy.pm,v 1.19 2004/02/21 06:15:45 andy Exp $

=cut

our $VERSION = "0.02";

=head1 SYNOPSIS

  use HTML::Tidy;
  blah blah blah

=head1 DESCRIPTION

=cut

=head1 EXPORTS

Severity codes C<TIDY_ERROR>, C<TIDY_WARNING> and C<TIDY_ERROR>.

=cut

require Exporter;

our @ISA = qw( Exporter DynaLoader );

use constant TIDY_ERROR => 3;
use constant TIDY_WARNING => 2;
use constant TIDY_INFO => 1;

our @EXPORT = qw( TIDY_ERROR TIDY_WARNING TIDY_INFO );

=head1 METHODS

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

Clears the list of messages, in case you want to print and clear, print and clear.

=cut

sub clear_messages {
    my $self = shift;

    $self->{messages} = [];
}

=head2 ignore( type => [ TIDY_X, TIDY_Y ] )

Specify types of messages to ignore.

=cut

sub ignore {
    my $self = shift;
    my @parms = @_;

    while ( @parms ) {
        my $parm = shift @parms;
        my $value = shift @parms;

        $self->{"ignore_$parm"} = $value;
    }

    $self->{messages} = [];
}

=head2 parse_file( $filename, $str [, $str...] )

Returns true if all went OK, or false if there was some problem calling
tidy, or parsing tidy's output.

=cut

sub parse_file {
    my $self = shift;
    my $filename = shift;

    my $parse_errors;
    my $html = join( "", @_ );

    my $errorblock = _calltidy( $html );
    return unless defined $errorblock;

    my @lines = split( /\n/, $errorblock );
    for my $line ( @lines ) {
        my $message;
        if ( $line =~ /^Info: (.+)$/ ) {
            $message = HTML::Tidy::Message->new( $filename, TIDY_INFO, undef, undef, $1 );

        } elsif ( $line =~ /^line (\d+) column (\d+) - (Warning|Error): (.+)$/ ) {
            my $type = ($3 eq "Warning") ? TIDY_WARNING : TIDY_ERROR;
            $message = HTML::Tidy::Message->new( $filename, $type, $1, $2, $4 );

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
        return if grep { $_ == $type } @ignore_types;
    }

    return 1;
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

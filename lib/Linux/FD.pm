package Linux::FD;

use 5.006;

use strict;
use warnings FATAL => 'all';

our $VERSION = '0.004';

use Sub::Exporter -setup => { exports => [qw/eventfd signalfd timerfd/] };

use XSLoader;
XSLoader::load(__PACKAGE__, $VERSION);

sub eventfd {
	my @args = @_;
	require Linux::FD::Event;
	return Linux::FD::Event->new(@args);
}

sub signalfd {
	my @args = @_;
	require Linux::FD::Signal;
	return Linux::FD::Signal->new(@args);
}

sub timerfd {
	my @args = @_;
	require Linux::FD::Timer;
	return Linux::FD::Timer->new(@args);
}

1;    # End of Linux::FD

__END__

=head1 NAME

Linux::FD - Linux specific special filehandles

=head1 VERSION

Version 0.004

=head1 DESCRIPTION

Linux::FD provides you Linux specific special file handles. These are

 * Event filehandles
 * Signal filehandles
 * Timer filehandles

These allow you to use conventional polling mechanisms to wait a large variety of events.

=head1 SUBROUTINES

Linux::FD defines 3 utility functions

=head2 eventfd($initial_value)

This creates an eventfd handle. See L<Linux::FD::Event> for more information on it.

=head2 signalfd($sigset)

This creates an signalfd handle. See L<Linux::FD::Signal> for more information on it.

=head2 timerfd($clock_id)

This creates an timerfd handle. See L<Linux::FD::Timer> for more information on it.

=head1 AUTHOR

Leon Timmermans, C<< <leont at cpan.org> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-linux-fd at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Linux-FD>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Linux::FD

You can also look for information at:

=over 4

=item * RT: CPAN's request tracker

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=Linux-FD>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/Linux-FD>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/Linux-FD>

=item * Search CPAN

L<http://search.cpan.org/dist/Linux-FD/>

=back

=head1 LICENSE AND COPYRIGHT

Copyright 2010 Leon Timmermans.

This program is free software; you can redistribute it and/or modify it
under the terms of either: the GNU General Public License as published
by the Free Software Foundation; or the Artistic License.

See http://dev.perl.org/licenses/ for more information.

=cut

package Linux::FD;

use 5.006;

use strict;
use warnings FATAL => 'all';

use Sub::Exporter -setup => { exports => [qw/eventfd signalfd timerfd/] };

use XSLoader;
XSLoader::load(__PACKAGE__, __PACKAGE__->VERSION);

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

1;

#ABSTRACT: Linux specific special filehandles

__END__

=head1 DESCRIPTION

Linux::FD provides you Linux specific special file handles. These are

=over 4

=item * Event filehandles

=item * Signal filehandles

=item * Timer filehandles

=back

These allow you to use conventional polling mechanisms to wait for a large variety of events.

=func eventfd($initial_value, @flags)

This creates an eventfd handle. See L<Linux::FD::Event> for more information on it.

=func signalfd($sigset)

This creates an signalfd handle. See L<Linux::FD::Signal> for more information on it.

=func timerfd($clock_id)

This creates an timerfd handle. See L<Linux::FD::Timer> for more information on it.

=cut

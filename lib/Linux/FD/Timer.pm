package Linux::FD::Timer;

use 5.006;

use strict;
use warnings FATAL => 'all';
use Carp qw/croak/;
use Const::Fast;
use Errno qw/EAGAIN EINTR/;

use parent 'IO::Handle';

our $VERSION = '0.001';

const my $fail_fd    => -1;
const my $timer_size => 8;

## no critic (ProhibitBuiltinHomonyms)

sub new {
	my ($class, $clock_id) = @_;

	my $fd = _new_fd($clock_id);
	croak "Can't open timerfd descriptor: $!" if $fd == $fail_fd;
	open my $fh, '+<&', $fd or croak "Can't fdopen($fd): $!";
	bless $fh, $class;
	return $fh;
}

sub receive {
	my $self = shift;
	my ($ret, $raw);
	do {
		$ret = sysread $self, $raw, $timer_size;
	} while (not defined $ret and $! == EINTR);
	if (not defined $ret) {
		return if $! == EAGAIN;
		croak "Couldn't read timerfd: $!";
	}
	return unpack 'Q', $raw;
}

1;    # End of Linux::FD::Timer

__END__

=head1 NAME

Linux::FD::Timer - Timer filehandles for Linux

=head1 VERSION

Version 0.001

=head1 SYNOPSIS

 use Linux::FD::Timer;

 my $fh = Linux::FD::Timer->new('monotonic');
 $fh->set_timeout(10, 10);
 while (1) {
     #do something..
     $fh->wait; #until the 10 seconds have passed.
 }

=head1 DESCRIPTION

This module creates and operates on a timer that delivers timer expiration notifications via a file descriptor. It provides an alternative to the use of Time::HiRes' setitimer or POSIX::RT::Timer, with the advantage that the file descriptor may easily be monitored by mechanisms such as select, poll, and epoll.

=head1 METHODS

=head2 new($clockid)

This creates a new timer object, and returns a file handle that refers to that timer. The clockid argument specifies the clock that is used to mark the progress of the timer, and must be either C<'realtime'> or C<'monotonic'>. C<realtime> is a settable system-wide clock. C<monotonic> is a non-settable clock that is not affected by discontinuous changes in the system clock (e.g., manual changes to system time). The current value of each of these clocks can be retrieved using L<POSIX::RT::Clock>. The handle will be non-blocking by default.

=head2 get_timeout()

Get the timeout value. In list context, it also returns the interval value. Note that this value is always relative to the current time.

=head2 set_timeout(value, $interval = 0, $abs_time = 0)

Set the timer and interval values. If C<$abstime> is true, they are absolute values, otherwise they are relative to the current time. Returns the old value like C<get_time> does.

=head2 receive

If the timer has already expired one or more times since its settings were last modified using settime(), or since the last successful wait, then receive returns an unsigned 8-byte integer containing the number of expirations that have occurred. If not it either returns undef or it blocks (if the handle is blocking).

=head1 AUTHOR

Leon Timmermans, C<< <leont at cpan.org> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-linux-fd at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Linux-FD>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Linux::FD::Timer

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

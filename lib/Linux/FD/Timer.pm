package Linux::FD::Timer;

use 5.006;

use strict;
use warnings FATAL => 'all';
use Carp qw/croak/;
use Const::Fast;
use Linux::FD ();

use parent 'IO::Handle';

const my $fail_fd => -1;

sub new {
	my ($class, $clock_id) = @_;

	my $fd = _new_fd($clock_id);
	croak "Can't open timerfd descriptor: $!" if $fd == $fail_fd;
	open my $fh, '+<&', $fd or croak "Can't fdopen($fd): $!";
	bless $fh, $class;
	return $fh;
}

1;    # End of Linux::FD::Timer

__END__

#ABSTRACT: Timer filehandles for Linux

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

=method new($clockid)

This creates a new timer object, and returns a file handle that refers to that timer. The clockid argument specifies the clock that is used to mark the progress of the timer, and must be either C<'realtime'> or C<'monotonic'>. C<realtime> is a settable system-wide clock. C<monotonic> is a non-settable clock that is not affected by discontinuous changes in the system clock (e.g., manual changes to system time). The current value of each of these clocks can be retrieved using L<POSIX::RT::Clock>.

=method get_timeout()

Get the timeout value. In list context, it also returns the interval value. Note that this value is always relative to the current time.

=method set_timeout(value, $interval = 0, $abs_time = 0)

Set the timer and interval values. If C<$abstime> is true, they are absolute values, otherwise they are relative to the current time. Returns the old value like C<get_time> does.

=method receive

If the timer has already expired one or more times since its settings were last modified using settime(), or since the last successful wait, then receive returns an unsigned 8-byte integer containing the number of expirations that have occurred. If not it either returns undef or it blocks (if the handle is blocking).

=cut

package Linux::FD::Signal;

use 5.006;

use strict;
use warnings FATAL => 'all';
use Carp qw/croak/;
use Const::Fast;
use Scalar::Util qw/blessed/;
use IPC::Signal qw/sig_num/;
use Linux::FD ();

use parent 'IO::Handle';

const my $fail_fd => -1;

sub new {
	my ($class, $sigmask) = @_;

	my $sigset = blessed($sigmask) && $sigmask->isa('POSIX::SigSet') ? $sigmask : POSIX::SigSet->new(sig_num($sigmask));
	my $fd = _new_fd($sigset);
	croak "Can't open signalfd descriptor: $!" if $fd == $fail_fd;
	open my $fh, '+<&', $fd or croak "Can't fdopen($fd): $!";
	bless $fh, $class;
	return $fh;
}

1;    # End of Linux::FD::Signal

__END__

#ABSTRACT: Signal filehandles for Linux

=head1 SYNOPSIS

 use Linux::FD::Signal;
 
 my $fh = Linux::FD::Signal->new($sigset);

=method new($sigmask)

This creates a signalfd file descriptor that can be used to accept signals targeted at the caller. This provides an alternative to the use of a signal handler or sigwaitinfo, and has the advantage that the file descriptor may be monitored by select, poll, and epoll.

The $sigmask argument specifies the set of signals that the caller wishes to accept via the file descriptor. This should either be a signal name(without the C<SIG> prefix) or a L<POSIX::SigSet|POSIX> object. Normally, the set of signals to be received via the file descriptor should be blocked to prevent the signals being handled according to their default dispositions. It is not possible to receive SIGKILL or SIGSTOP signals via a signalfd file descriptor; these signals are silently ignored if specified in $sigmask.

=method set_mask($sigmask)

Sets the signal mask to a new value. It's argument works exactly the same as C<new>'s

=method receive()

If one or more of the signals specified in mask is pending for the process, then it returns the information of one signalfd_siginfo structures (see below) that describe the signals.

As a consequence of the receive, the signals are consumed, so that they are no longer pending for the process (i.e., will not be caught by signal handlers, and cannot be accepted using sigwaitinfo).

If none of the signals in mask is pending for the process, then the receive either blocks until one of the signals in mask is generated for the process, or fails with the error EAGAIN if the file descriptor has been made non-blocking.

The information is returned as a hashref with the following keys: signo, errno, code, pid, uid, fd, tid, band, overrun, trapno, status, int, ptr, utime, stime, address. All of these are returned as integers. Some of them are only useful in certain circumstances, others may not be useful from perl at all.

=head1 SEE ALSO

L<Signal::Mask>

=cut

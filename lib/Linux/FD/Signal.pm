package Linux::FD::Signal;

use 5.006;

use strict;
use warnings FATAL => 'all';
use Carp qw/croak/;
use Const::Fast;
use Errno qw/EAGAIN EINTR/;
use Fcntl qw//;
use POSIX qw/sigprocmask SIG_BLOCK SIG_UNBLOCK/;
use Scalar::Util qw/blessed/;

use parent 'IO::Handle';

our $VERSION = '0.001';

const my $fail_fd       => -1;
const my $signalfd_size => 128;

const my $raw_map => <<'MAP_END';
signo   L
errno   l
code    l
pid     L
uid     L
fd      l
tid     L
band    L
overrun L
trapno  L
status  l
int     l
ptr     Q
utime   Q
stime   Q
address Q
rest    A*
MAP_END

my $template = join '', $raw_map =~ m/ (\w [*+?]? ) $ /xgm;

my @keys = $raw_map =~ m/ ^ ( \w+ ) /xgm;

sub new {
	my ($class, $sigmask) = @_;

	my $sigset = blessed($sigmask) && $sigmask->isa('POSIX::SigSet') ? $sigmask : POSIX::SigSet->new(sig_num($sigmask));
	my $fd = _new_fd($sigset);
	croak "Can't open signalfd descriptor: $!" if $fd == $fail_fd;
	open my $fh, '+<&', $fd or croak "Can't fdopen($fd): $!";
	bless $fh, $class;
	return $fh;
}

sub receive {
	my $self = shift;
	my ($ret, $raw);
	do {
		$ret = sysread $self, $raw, $signalfd_size;
	} while (not defined $ret and $! == EINTR);
	if (not defined $ret) {
		return if $! == EAGAIN;
		croak "Couldn't read signalfd_info: $!";
	}
	my %ret;
	@ret{@keys} = unpack $template, $raw;
	return \%ret;
}

1;    # End of Linux::FD::Signal

__END__

=head1 NAME

Linux::FD::Signal - Signal filehandles

=head1 VERSION

Version 0.001

=head1 SYNOPSIS

 use Linux::FD::Signal;
 
 my $fh = Linux::FD::Signal->new($sigset);

=head1 METHODS

=head2 new($sigmask)

This creates a signalfd file descriptor that can be used to accept signals targeted at the caller. This provides an alternative to the use of a signal handler or sigwaitinfo, and has the advantage that the file descriptor may be monitored by select, poll, and epoll. The handle will be non-blocking by default.

The $sigmask argument specifies the set of signals that the caller wishes to accept via the file descriptor. This should either be a signal name(without the C<SIG> prefix) or a L<POSIX::SigSet|POSIX> object. Normally, the set of signals to be received via the file descriptor should be blocked to prevent the signals being handled according to their default dispositions. It is not possible to receive SIGKILL or SIGSTOP signals via a signalfd file descriptor; these signals are silently ignored if specified in $sigmask.

=head2 set_mask($sigmask)

Sets the signal mask to a new value. It's argument works exactly the same as C<new>'s

=head2 receive()

If one or more of the signals specified in mask is pending for the process, then it returns the information of one signalfd_siginfo structures (see below) that describe the signals.

As a consequence of the receive, the signals are consumed, so that they are no longer pending for the process (i.e., will not be caught by signal handlers, and cannot be accepted using sigwaitinfo).

If none of the signals in mask is pending for the process, then the receive either blocks until one of the signals in mask is generated for the process, or fails with the error EAGAIN if the file descriptor has been made non-blocking.

The information is returned as a hashref with the following keys: signo, errno, code, pid, uid, fd, tid, band, overrun, trapno, status, int, ptr, utime, stime, address. All of these are returned as integers. Some of them are only useful in certain circumstances, others may not be useful from perl at all.

=head1 AUTHOR

Leon Timmermans, C<< <leont at cpan.org> >>

=head1 SEE ALSO

L<Signal::Mask>

=head1 BUGS

Please report any bugs or feature requests to C<bug-linux-fd at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Linux-FD>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Linux::FD::Signal

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

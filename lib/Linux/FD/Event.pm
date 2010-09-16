package Linux::FD::Event;

use 5.006;

use strict;
use warnings FATAL => 'all';
use Carp qw/croak/;
use Const::Fast;
use Errno qw/EAGAIN EINTR/;

use parent 'IO::Handle';

our $VERSION = '0.001';

const my $fail_fd    => -1;
const my $event_size => 8;

sub new {
	my ($class, $initial) = @_;
	$initial ||= 0;

	my $fd = _new_fd($initial);
	croak "Can't open eventfd descriptor: $!" if $fd == $fail_fd;
	open my $fh, '+<&', $fd or croak "Can't fdopen($fd): $!";
	bless $fh, $class;
	return $fh;
}

sub get {
	my $self = shift;
	my ($ret, $raw);
	do {
		$ret = sysread $self, $raw, $event_size;
	} while (not defined $ret and $! == EINTR);
	if (not defined $ret) {
		return if $! == EAGAIN;
		croak "Couldn't read from eventfd: $!";
	}
	return unpack 'Q', $raw;
}

sub add {
	my ($self, $value) = @_;
	my $raw = pack 'Q', int $value;
	my $ret;
	do {
		$ret = syswrite $self, $raw, $event_size;
	} while (not defined $ret and $! == EINTR);
	if (not defined $ret) {
		return if $! == EAGAIN;
		croak "Couldn't write value '$value' to eventfd: $!";
	}
	return;
}

1;    # End of Linux::FD::Event

__END__

=head1 NAME

Linux::FD::Event - Event filehandles

=head1 VERSION

Version 0.001

=head1 SYNOPSIS

 use Linux::FD::Event;
 
 my $foo = Linux::FD::Event->new(42);
 if (fork) {
	 say $foo->get while sleep 1
 }
 else {
     $foo->add($_) while <>;
 }

=head1 METHODS

=head2 new($initial_value)

This creates an eventfd object that can be used as an event wait/notify mechanism by userspace applications, and by the kernel to notify userspace applications of events. The object contains an unsigned 64-bit integer counter that is maintained by the kernel. This counter is initialized with the value specified in the argument $initial_value. The handle will be non-blocking by default.

=head2 get()

If the eventfd counter has a non-zero value, then a C<get> returns 8 bytes containing that value, and the counter's value is reset to zero. If the counter is zero at the time of the C<get>, then the call either blocks until the counter becomes non-zero, or fails with the error EAGAIN if the file handle has been made non-blocking.

=head2 add($value)

A C<add> call adds the 8-byte integer value $value to the counter. The maximum value that may be stored in the counter is the largest unsigned 64-bit value minus 1 (i.e., 0xfffffffffffffffe). If the addition would cause the counter's value to exceed the maximum, then the C<add> either blocks until a C<get> is performed on the file descriptor, or fails with the error EAGAIN if the file descriptor has been made non- blocking. A C<add> will fail with the error EINVAL if an attempt is made to write the value 0xffffffffffffffff.

=head1 AUTHOR

Leon Timmermans, C<< <leont at cpan.org> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-linux-fd at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Linux-FD>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Linux::FD::Event

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

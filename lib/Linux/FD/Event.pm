package Linux::FD::Event;

use 5.006;

use strict;
use warnings FATAL => 'all';
use Linux::FD ();

use parent 'IO::Handle';

1;    # End of Linux::FD::Event

#ABSTRACT: Event filehandles for Linux

__END__

=head1 SYNOPSIS

 use Linux::FD::Event;
 
 my $foo = Linux::FD::Event->new(42);
 if (fork) {
     say $foo->get while sleep 1
 }
 else {
     $foo->add($_) while <>;
 }

=method new($initial_value, @flags)

This creates an eventfd object that can be used as an event wait/notify mechanism by userspace applications, and by the kernel to notify userspace applications of events. The object contains an unsigned 64-bit integer counter that is maintained by the kernel. This counter is initialized with the value specified in the argument C<$initial_value>. C<@flags> is an optional list of flags, currently limited to C<'non-blocking'> (requires Linux 2.6.27), and C<'semaphore'> (requires Linux 2.6.30).

=method get()

If the eventfd counter has a non-zero value, and C<'semaphore'> is not set, then a C<get> returns 64 bit unsigned integer containing that value, and the counter's value is reset to zero. If C<'semaphore'> is set, it decrements the counter by one and returns one. In either case, if the counter is zero at the time of the C<get>, then the call either blocks until the counter becomes non-zero, or fails with the error EAGAIN if the file handle has been made non-blocking.

=method add($value)

A C<add> call adds the 64 bit unsigned integer value $value to the counter. The maximum value that may be stored in the counter is the largest unsigned 64-bit value minus 1 (i.e., 0xfffffffffffffffe). If the addition would cause the counter's value to exceed the maximum, then the C<add> either blocks until a C<get> is performed on the file descriptor, or fails with the error EAGAIN if the file descriptor has been made non-blocking. A C<add> will fail with the error EINVAL if an attempt is made to write the value 0xffffffffffffffff.

=cut


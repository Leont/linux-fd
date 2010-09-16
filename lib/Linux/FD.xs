#include <sys/eventfd.h>
#include <sys/signalfd.h>
#include <sys/timerfd.h>

#define PERL_NO_GET_CONTEXT
#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

#define get_fd(self) PerlIO_fileno(IoOFP(sv_2io(SvRV(self))));

static void get_sys_error(char* buffer, size_t buffer_size) {
#ifdef _GNU_SOURCE
	const char* message = strerror_r(errno, buffer, buffer_size);
	if (message != buffer) {
		memcpy(buffer, message, buffer_size -1);
		buffer[buffer_size] = '\0';
	}
#else
	strerror_r(errno, buffer, buffer_size);
#endif
}

static void S_die_sys(pTHX_ const char* format) {
	char buffer[128];
	get_sys_error(buffer, sizeof buffer);
	Perl_croak(aTHX_ format, buffer);
}
#define die_sys(format) S_die_sys(aTHX_ format)

sigset_t* S_sv_to_sigset(pTHX_ SV* sigmask) {
	if (!SvOK(sigmask))
		return NULL;
	if (!SvROK(sigmask) || !sv_isa(sigmask, "POSIX::SigSet"))
		Perl_croak(aTHX_ "sigset is not of type POSIX::SigSet");
	IV tmp = SvIV((SV*)SvRV(sigmask));
	return INT2PTR(sigset_t*, tmp);
}
#define sv_to_sigset(sigmask) S_sv_to_sigset(aTHX_ sigmask)

#define NANO_SECONDS 1000000000

static NV timespec_to_nv(struct timespec* time) {
	return time->tv_sec + time->tv_nsec / (double)NANO_SECONDS;
}

static void nv_to_timespec(NV input, struct timespec* output) {
	output->tv_sec  = (time_t) floor(input);
	output->tv_nsec = (long) ((input - output->tv_sec) * NANO_SECONDS);
}

typedef struct { const char* key; clockid_t value; } map[];

static map clocks = {
	{ "realtime" , CLOCK_REALTIME  },
	{ "monotonic", CLOCK_MONOTONIC }
};

static clockid_t S_get_clockid(pTHX_ const char* clock_name) {
	int i;
	for (i = 0; i < sizeof clocks / sizeof *clocks; ++i) {
		if (strEQ(clock_name, clocks[i].key))
			return clocks[i].value;
	}
	Perl_croak(aTHX_ "No such timer '%s' known", clock_name);
}
#define get_clockid(name) S_get_clockid(aTHX_ name)

void non_blocking(int fd) {
	fcntl(fd, F_SETFL, O_NONBLOCK);
}

#ifndef EFD_CLOEXEC
#define EFD_CLOEXEC 0
#endif

#ifndef SFD_CLOEXEC
#define SFD_CLOEXEC 0
#endif

#ifndef TFD_CLOEXEC
#define TFD_CLOEXEC 0
#endif

MODULE = Linux::FD				PACKAGE = Linux::FD::Event

int
_new_fd(initial)
	IV initial;
	CODE:
		RETVAL = eventfd(initial, EFD_CLOEXEC);
		non_blocking(RETVAL);
	OUTPUT:
		RETVAL


MODULE = Linux::FD				PACKAGE = Linux::FD::Signal

int
_new_fd(sigmask)
	SV* sigmask;
	CODE:
		RETVAL = signalfd(-1, sv_to_sigset(sigmask), SFD_CLOEXEC);
		non_blocking(RETVAL);
	OUTPUT:
		RETVAL

void set_mask(self, sigmask)
	SV* self;
	SV* sigmask;
	PREINIT:
	int fd;
	CODE:
	fd = get_fd(self);
	if(signalfd(fd, sv_to_sigset(sigmask), 0) == -1)
		die_sys("Couldn't set_mask: %s");


MODULE = Linux::FD				PACKAGE = Linux::FD::Timer

int
_new_fd(clock_name)
	const char* clock_name;
	PREINIT:
		clockid_t clock_id;
	CODE:
		clock_id = get_clockid(clock_name);
		RETVAL = timerfd_create(clock_id, TFD_CLOEXEC);
		non_blocking(RETVAL);
	OUTPUT:
		RETVAL

void
get_timeout(self)
	SV* self;
	PREINIT:
		int timer;
		struct itimerspec value;
	PPCODE:
		timer = get_fd(self);
		if (timerfd_gettime(timer, &value) == -1)
			die_sys("Couldn't get_timeout: %s");
		mXPUSHn(timespec_to_nv(&value.it_value));
		if (GIMME_V == G_ARRAY)
			mXPUSHn(timespec_to_nv(&value.it_interval));

SV*
set_timeout(self, new_value, new_interval = 0, abstime = 0)
	SV* self;
	NV new_value;
	NV new_interval;
	IV abstime;
	PREINIT:
		int timer;
		struct itimerspec new_itimer, old_itimer;
	CODE:
		timer = get_fd(self);
		nv_to_timespec(new_value, &new_itimer.it_value);
		nv_to_timespec(new_interval, &new_itimer.it_interval);
		if (timerfd_settime(timer, (abstime ? TIMER_ABSTIME : 0), &new_itimer, &old_itimer) == -1)
			die_sys("Couldn't set_timeout: %s");
		mXPUSHn(timespec_to_nv(&old_itimer.it_value));
		if (GIMME_V == G_ARRAY)
			mXPUSHn(timespec_to_nv(&old_itimer.it_interval));

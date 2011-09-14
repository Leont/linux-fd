#ifndef _GNU_SOURCE
#	define _GNU_SOURCE
#endif
#define GNU_STRERROR_R

#include <string.h>

#include <sys/eventfd.h>
#include <sys/signalfd.h>
#include <sys/timerfd.h>

#define PERL_NO_GET_CONTEXT
#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

#define get_fd(self) PerlIO_fileno(IoOFP(sv_2io(SvRV(self))));

static void get_sys_error(char* buffer, size_t buffer_size) {
#if _POSIX_VERSION >= 200112L
	const char* message = strerror_r(errno, buffer, buffer_size);
	if (message != buffer)
		memcpy(buffer, message, buffer_size);
#else
	const char* message = strerror(errno);
	strncpy(buffer, message, buffer_size - 1);
	buffer[buffer_size - 1] = '\0';
#endif
}

static void S_die_sys(pTHX_ const char* format) {
	char buffer[128];
	get_sys_error(buffer, sizeof buffer);
	Perl_croak(aTHX_ format, buffer);
}
#define die_sys(format) S_die_sys(aTHX_ format)

sigset_t* S_sv_to_sigset(pTHX_ SV* sigmask, const char* name) {
	if (!SvOK(sigmask))
		return NULL;
	if (!SvROK(sigmask) || !sv_derived_from(sigmask, "POSIX::SigSet"))
		Perl_croak(aTHX_ "%s is not of type POSIX::SigSet");
#if PERL_VERSION > 15 || PERL_VERSION == 15 && PERL_SUBVERSION > 2
	return (sigset_t *) SvPV_nolen(SvRV(sigmask));
#else
	IV tmp = SvIV((SV*)SvRV(sigmask));
	return INT2PTR(sigset_t*, tmp);
#endif
}
#define sv_to_sigset(sigmask, name) S_sv_to_sigset(aTHX_ sigmask, name)

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

#ifndef EFD_CLOEXEC
#define EFD_CLOEXEC 0
#endif

#ifndef SFD_CLOEXEC
#define SFD_CLOEXEC 0
#endif

#ifndef TFD_CLOEXEC
#define TFD_CLOEXEC 0
#endif

#define SET_HASH_IMPL(key,value) hv_store(hash, key, sizeof key - 1, value, 0)
#define SET_HASH_U(key) SET_HASH_IMPL(#key, newSVuv(buffer.ssi_##key))
#define SET_HASH_I(key) SET_HASH_IMPL(#key, newSViv(buffer.ssi_##key))

MODULE = Linux::FD				PACKAGE = Linux::FD::Event

int
_new_fd(initial)
	IV initial;
	CODE:
		RETVAL = eventfd(initial, EFD_CLOEXEC);
	OUTPUT:
		RETVAL

IV
get(self)
	SV* self;
	PREINIT:
		uint64_t buffer;
		int ret, events;
	CODE:
		events = get_fd(self);
		do {
			ret = read(events, &buffer, sizeof buffer);
		} while (ret == -1 && errno == EINTR);
		if (ret == -1) {
			if (errno == EAGAIN)
				XSRETURN_EMPTY;
			else
				die_sys("Couldn't read from eventfd: %s");
		}
		RETVAL = buffer;
	OUTPUT:
		RETVAL

IV
add(self, value)
	SV* self;
	IV value;
	PREINIT:
		uint64_t buffer;
		int ret, events;
	CODE:
		events = get_fd(self);
		buffer = value;
		do {
			ret = write(events, &buffer, sizeof buffer);
		} while (ret == -1 && errno == EINTR);
		if (ret == -1) {
			if (errno == EAGAIN)
				XSRETURN_EMPTY;
			else
				die_sys("Couldn't write to eventfd: %s");
		}
		RETVAL = value;
	OUTPUT:
		RETVAL


MODULE = Linux::FD				PACKAGE = Linux::FD::Signal

int
_new_fd(sigmask)
	SV* sigmask;
	CODE:
		RETVAL = signalfd(-1, sv_to_sigset(sigmask, "signalfd"), SFD_CLOEXEC);
	OUTPUT:
		RETVAL

void set_mask(self, sigmask)
	SV* self;
	SV* sigmask;
	PREINIT:
	int fd;
	CODE:
	fd = get_fd(self);
	if(signalfd(fd, sv_to_sigset(sigmask, "signalfd"), 0) == -1)
		die_sys("Couldn't set_mask: %s");

SV*
receive(self)
	SV* self;
	PREINIT:
		struct signalfd_siginfo buffer;
		int tmp, timer;
		HV* hash;
	CODE:
		timer = get_fd(self);
		do {
			tmp = read(timer, &buffer, sizeof buffer);
		} while (tmp == -1 && errno == EINTR);
		if (tmp == -1) {
			if (errno == EAGAIN)
				XSRETURN_EMPTY;
			else
				die_sys("Couldn't read from signalfd: %s");
		}
		hash = newHV();
		SET_HASH_U(signo);
		SET_HASH_I(errno);
		SET_HASH_I(code);
		SET_HASH_U(pid);
		SET_HASH_U(uid);
		SET_HASH_I(fd);
		SET_HASH_U(tid);
		SET_HASH_U(band);
		SET_HASH_U(overrun);
		SET_HASH_U(trapno);
		SET_HASH_I(status);
		SET_HASH_I(int);
		SET_HASH_U(ptr);
		SET_HASH_U(utime);
		SET_HASH_U(stime);
		SET_HASH_U(addr);
		RETVAL = newRV_noinc((SV*)hash);
	OUTPUT:
		RETVAL


MODULE = Linux::FD				PACKAGE = Linux::FD::Timer

int
_new_fd(clock_name)
	const char* clock_name;
	PREINIT:
		clockid_t clock_id;
	CODE:
		clock_id = get_clockid(clock_name);
		RETVAL = timerfd_create(clock_id, TFD_CLOEXEC);
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
	PPCODE:
		timer = get_fd(self);
		nv_to_timespec(new_value, &new_itimer.it_value);
		nv_to_timespec(new_interval, &new_itimer.it_interval);
		if (timerfd_settime(timer, (abstime ? TIMER_ABSTIME : 0), &new_itimer, &old_itimer) == -1)
			die_sys("Couldn't set_timeout: %s");
		mXPUSHn(timespec_to_nv(&old_itimer.it_value));
		if (GIMME_V == G_ARRAY)
			mXPUSHn(timespec_to_nv(&old_itimer.it_interval));

IV
receive(self)
	SV* self;
	PREINIT:
		uint64_t buffer;
		int ret, timer;
	CODE:
		timer = get_fd(self);
		do {
			ret = read(timer, &buffer, sizeof buffer);
		} while (ret == -1 && errno == EINTR);
		if (ret == -1) {
			if (errno == EAGAIN)
				XSRETURN_EMPTY;
			else
				die_sys("Couldn't read from timerfd: %s");
		}
		RETVAL = buffer;
	OUTPUT:
		RETVAL


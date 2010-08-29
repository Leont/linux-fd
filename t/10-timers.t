# perl -T

use strict;
use warnings FATAL => 'all';

use Test::More tests => 7;
use Linux::FD 'timerfd';
use IO::Select;
use Time::HiRes qw/sleep/;

my $selector = IO::Select->new;

alarm 2;

my $fd = timerfd('realtime');
$selector->add($fd);

ok !$selector->can_read(0), 'Can\'t read an empty timerfd';

$fd->set_timeout(0.1);

sleep 0.2;

ok $selector->can_read(0), 'Can read an triggered timerfd';

ok $fd->wait, 'Got timeout';

ok !$selector->can_read(0), 'Can\'t read an waited timerfd';

$fd->set_timeout(0.1, 0.1);

my ($value, $interval) = $fd->get_timeout;

cmp_ok $value, '<=', 0.1, 'Value is right';
is $interval, 0.1, 'Interval is right';

sleep 0.21;

is $fd->wait, 2, 'Got two timeouts';

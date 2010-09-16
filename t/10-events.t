# perl -T

use strict;
use warnings FATAL => 'all';

use Test::More tests => 6;
use Linux::FD 'eventfd';
use IO::Select;

my $selector = IO::Select->new;

alarm 2;

my $fd = eventfd(0);
$selector->add($fd);

ok !$selector->can_read(0), "Can't read an empty eventfd";

ok $selector->can_write(0), "Can write to an empty eventfd";

ok !defined $fd->get, 'Can\'t read an empty eventfd';

$fd->add(42);

ok $selector->can_read(0), "Can read a filled eventfd";

is($fd->get, 42, 'Value of eventfd was 42');

ok !$selector->can_read(0), "Can't read an emptied eventfd";

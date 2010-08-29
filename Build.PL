use 5.006;
use strict;
use warnings;
use Module::Build;

if ($^O ne 'linux') {
	print "No support for OS\n";
	exit 0;
}

my $builder = Module::Build->new(
	module_name         => 'Linux::FD',
	license             => 'perl',
	dist_author         => q{Leon Timmermans <leont@cpan.org>},
	dist_version_from   => 'lib/Linux/FD.pm',
	build_requires      => {
		'Test::More'    => 0,
		'Test::Exception' => 0,
	},
	requires	        => {
		parent          => 0,
		perl            => 5.006,
		'Const::Fast'   => 0,
		'Sub::Exporter' => 0,
	},
	add_to_cleanup      => [ 'Linux-FD-*' ],
	create_makefile_pl  => 'small',
	sign                => 1,
);

$builder->create_build_script();

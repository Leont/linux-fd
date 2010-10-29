use 5.006;
use strict;
use warnings;
use Module::Build;
use Config;

if ($^O ne 'linux') {
	print "No support for OS\n";
	exit 0;
}

my $builder = Module::Build->new(
	module_name         => 'Linux::FD',
	license             => 'perl',
	dist_author         => q{Leon Timmermans <leont@cpan.org>},
	dist_version_from   => 'lib/Linux/FD.pm',
	configure_requires  => {
		'Module::Build' => 0.28,
	},
	build_requires      => {
		'ExtUtils::CBuilder' => 0,
		'Module::Build' => 0.28,
		'Test::More'    => 0,
	},
	requires	        => {
		perl            => 5.006,
		parent          => 0,
		'Const::Fast'   => 0,
		'IPC::Signal'   => 0,
		'Sub::Exporter' => 0,
	},
	add_to_cleanup      => [ 'Linux-FD-*' ],
	create_makefile_pl  => 'small',
	sign                => 1,
	meta_merge          => {
		resources       => {
			bugtracker  => 'http://rt.cpan.org/NoAuth/Bugs.html?Dist=Linux-FD',
			repository  => 'http://github.com/Leont/linux-fd'
		}
	},
);

$builder->create_build_script();

use strict;
use warnings;
use Module::Build::Pluggable qw(CPANfile);

my $build = Module::Build::Pluggable->new(
    license        => 'perl',
    dynamic_config => 0,

    build_requires     => {},
    configure_requires => {},
    requires => {
        perl => '5.008001',
    },

    no_index    => { 'directory' => [ 'inc' ] },
    name        => 'Log-Minimal-Instance',
    module_name => 'Log::Minimal::Instance',

    test_files           => (-d '.git' || $ENV{RELEASE_TESTING}) ? 't/ xt/' : 't/',
    recursive_test_files => 1,

    meta_merge => {
        resources => {
            repository => 'https://github.com/arisawa/p5-Log-Minimal-Instance',
            bugtracker => 'https://github.com/arisawa/p5-Log-Minimal-Instance/issues',
        },
    },

    create_readme  => 1,
    create_license => 1,
);

$build->create_build_script();

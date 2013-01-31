use strict;
use warnings;
use Module::Build;

my $build = Module::Build->new(
    license        => 'perl',
    dynamic_config => 0,

    build_requires     => {
        'Test::More'     => '0.98',
        'Test::Requires' => '0.06',
    },
    configure_requires => { 'Module::Build' => '0.38' },
    requires           => {
        perl            => '5.008001',
        'Log::Minimal'  => '0.14',
        'File::Stamped' => '0.03',
    },

    no_index    => { 'directory' => [ 'inc' ] },
    name        => 'Log-Minimal-Instance',
    module_name => 'Log::Minimal::Instance',

    # script_files => [''],

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

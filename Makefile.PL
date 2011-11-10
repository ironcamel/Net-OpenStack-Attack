use ExtUtils::MakeMaker;
WriteMakefile(
    NAME         => 'StackAttack',
    VERSION_FROM => 'lib/StackAttack.pm',
    ABSTRACT     => 'Tool for stress testing OpenStack',
    PREREQ_PM    => {
        'App::Rad'                   => '0',
        'HTTP::Async'                => '0',
        'HTTP::Request'              => '0',
        'JSON'                       => '0',
        'LWP'                        => '0',
        'Method::Signatures::Simple' => '0',
        'Time::SoFar'                => '0',
    },
    LICENSE   => 'perl',
    EXE_FILES => [ 'bin/stackattack' ],
);

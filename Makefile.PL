use 5.006001;
use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.

eval { require LWP::Simple; };

if ( $@ ) {
    print <<EOF;

NOTE: It seems that you don't have LWP::Simple installed.
      The weblint program will not be able to retrieve web pages.

EOF
}

WriteMakefile(
    NAME                => 'HTML::Tidy',
    AUTHOR              => 'Andy Lester <andy@petdance.com>',
    VERSION_FROM        => 'lib/HTML/Tidy.pm',
    ABSTRACT_FROM       => 'lib/HTML/Tidy.pm',
    PREREQ_PM           => {
        'Exporter'      => 0,
        'Test::More'    => 0,
        'Test::Builder' => 0,
    },
    LIBS                => ['-ltidy'], # e.g., '-lm'
    DEFINE              => '', # e.g., '-DHAVE_SOMETHING'
    INC                 => '-I. -I/usr/local/include/tidy', # e.g., '-I. -I/usr/include/other'
    # Un-comment this if you add C files to link with later:
    # OBJECT            => '$(O_FILES)', # link all the C files too

    EXE_FILES           => [qw(bin/webtidy)],
    dist => {
        COMPRESS => 'gzip -9f', 
        SUFFIX => 'gz',
    },
    clean => { FILES => 'HTML-Tidy-*' },
);

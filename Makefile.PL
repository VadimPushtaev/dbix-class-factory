use 5.006;
use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME                => 'DBIx::Class::Factory',
    AUTHOR              => q{Vadim Pushtaev <pushtaev@cpan.org>},
    VERSION_FROM        => 'lib/DBIx/Class/Factory.pm',
    ABSTRACT_FROM       => 'lib/DBIx/Class/Factory.pm',
    ($ExtUtils::MakeMaker::VERSION >= 6.3002
      ? ('LICENSE'=> 'perl')
      : ()),
    PL_FILES            => {},
    PREREQ_PM => {
        'Test::More' => 0,
    },
    dist                => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean               => { FILES => 'DBIx-Class-Factory-*' },
);

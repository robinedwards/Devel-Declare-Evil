use 5.06;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME              => 'Devel::Declare::Evil',
    VERSION_FROM      => 'lib/Devel/Declare/Evil.pm',
    PREREQ_PM         => {
        strictures => 1,
        'Filter::Util::Call' => 0,
        'Test::More' => 0,
    },
    ($] >= 5.005 ?   
      (ABSTRACT_FROM  => 'lib/Devel/Declare/Evil.pm', # retrieve abstract from module
       AUTHOR         => 'Robin Edwards <robin.ge@gmail.com>') : ()),
);

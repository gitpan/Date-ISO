use ExtUtils::MakeMaker;

# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
  'NAME'         => 'Date::ISO',
  'VERSION_FROM' => 'ISO.pm',      # finds $VERSION
  'PREREQ_PM'    => {
      'Date::Leapyear' => 0,
      'Date::ICal'     => 0,
  },
);

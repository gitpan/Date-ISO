use ExtUtils::MakeMaker;

# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
  'NAME'         => 'Date::ISO',
  'VERSION_FROM' => 'lib/Date/ISO.pm',      # finds $VERSION
  'PREREQ_PM'    => {
      'Date::Leapyear' => 0,
      'Date::ICal'     => 0,
      'Pod::Tests'     => 0,
      'Test::More'     => 0,
  },
);

open(MANIFEST, "MANIFEST");
foreach my $file (grep /\.pm$/, <MANIFEST>) {
    chomp $file;
    my($module) = $file =~ m|^(.*)\.pm$|;
    $module =~ s|/|-|g;
    system("pod2test $file t/embedded-$module.t");
}


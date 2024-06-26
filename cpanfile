# This file is generated by Dist::Zilla
# Prereqs are detected automatically. You do not need to edit this file

requires "Carp" => "0";
requires "Class::XSAccessor" => "1.19";
requires "File::Spec" => "0";
requires "Filesys::Df" => "0.92";
requires "Hash::Util" => "0";
requires "POSIX" => "1.15";
requires "Regexp::Common" => "2017060201";
requires "Set::Tiny" => "0.04";
requires "Time::HiRes" => "1.9764";
requires "YAML::XS" => "0.88";
requires "perl" => "5.012000";

on 'test' => sub {
  requires "Exporter" => "0";
  requires "File::Copy" => "0";
  requires "File::Temp" => "0";
  requires "Scalar::Util" => "0";
  requires "Test::Kwalitee" => "1.28";
  requires "Test::More" => "0";
  requires "Test::Most" => "0.38";
  requires "Test::Perl::Critic" => "1.04";
  requires "Test::Pod" => "1.52";
  requires "Test::Pod::Coverage" => "1.10";
  requires "Test::TempDir::Tiny" => "0.018";
  requires "lib" => "0";
  requires "perl" => "5.012000";
};

on 'configure' => sub {
  requires "Devel::AssertOS" => "1.21";
  requires "ExtUtils::MakeMaker" => "0";
  requires "perl" => "5.012000";
};

on 'develop' => sub {
  requires "English" => "0";
  requires "Test::Kwalitee" => "1.21";
  requires "Test::More" => "0.88";
  requires "Test::Perl::Critic" => "0";
};

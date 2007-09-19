#!/usr/bin/perl -w

use strict;
use vars qw($test_dsn $test_user $test_password $mdriver $dbdriver);
$DBI::errstr = '';  # Make -w happy
require DBI;

# Include lib.pl
$mdriver = '';
my $file;
foreach $file ('lib.pl', 't/lib.pl') {
  do $file;
  if ($@) {
    print STDERR "Error while executing lib.pl: $@\n";
    exit 10;
  }
  if ($mdriver ne '') {
    last;
  }
}

sub ServerError() {
  print STDERR ("Cannot connect: ", $DBI::errstr, "\n");
  exit 10;
}

# Main loop; leave this untouched, put tests into the loop
use vars qw($state);
while (Testing()) {
  # Connect to the database
  my $dbh;
  Test($state or $dbh = DBI->connect($test_dsn, $test_user, $test_password))
      or ServerError();

  # Create some tables
  my $table1;
  Test($state or $table1 = FindNewTable($dbh))
      or DbiError($dbh->err, $dbh->errstr);
  my $create1;
  if (!$state) {
    ($create1 = TableDefinition($table1,
                                ["id",   "INTEGER",  4, 0],
                                ["name", "CHAR",    64, 0]));
    print "Creating table:\n$create1\n";
  }
  Test($state or $dbh->do($create1))
      or DbiError($dbh->err, $dbh->errstr);

  my $table2;
  Test($state or $table2 = FindNewTable($dbh))
      or DbiError($dbh->err, $dbh->errstr);
  my $create2;
  if (!$state) {
    ($create2 = TableDefinition($table2,
                                ["id",   "INTEGER",  4, 0],
                                ["name", "CHAR",    64, 0]));
    print "Creating table:\n$create2\n";
  }
  Test($state or $dbh->do($create2))
      or DbiError($dbh->err, $dbh->errstr);

  my $pid;
  if (!defined($pid = fork())) {
    die("fork: $!");
  } elsif ($pid == 0) {
    # Child: drop the second table
    if (!$state) {
      $dbh->do("DROP TABLE $table2")
          or DbiError($dbh->err, $dbh->errstr);
      $dbh->disconnect()
          or DbiError($dbh->err, $dbh->errstr);
    }
    exit(0);
  }

  # Parent: wait for the child to finish, then attempt to use the database
  Test(waitpid($pid, 0) >= 0) or print("waitpid: $!\n");

  Test($state or $dbh->do("DROP TABLE $table1"))
      or DbiError($dbh->err, $dbh->errstr);

  # Make sure the child actually deleted table2.  This will fail if
  # table2 still exists.
  Test($state or $dbh->do($create2))
      or DbiError($dbh->err, $dbh->errstr);

  # Disconnect
  Test($state or $dbh->disconnect())
      or DbiError($dbh->err, $dbh->errstr);
}

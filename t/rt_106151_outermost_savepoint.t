#!/usr/bin/perl

use strict;
BEGIN {
	$|  = 1;
	$^W = 1;
}

use t::lib::Test;
use Test::More;

BEGIN { requires_sqlite('3.6.8') }

plan tests => 7;
use Test::NoWarnings;

{ # simple case
	my $dbh = connect_ok(
		AutoCommit => 1,
		RaiseError => 1,
	);
	$dbh->do("SAVEPOINT svp_0");
	$dbh->selectall_arrayref("SELECT * FROM sqlite_master");
	$dbh->do("RELEASE svp_0");
	# should not spit the "Issuing rollback()" warning
}

{ # nested
	my $dbh = connect_ok(
		AutoCommit => 1,
		RaiseError => 1,
	);
	$dbh->do("SAVEPOINT svp_0");
	$dbh->do("SAVEPOINT svp_1");
	$dbh->selectall_arrayref("SELECT * FROM sqlite_master");
	$dbh->do("RELEASE svp_1");
	$dbh->do("RELEASE svp_0");
	# should not spit the "Issuing rollback()" warning
}

{ # end with commit
	my $dbh = connect_ok(
		AutoCommit => 1,
		RaiseError => 1,
	);
	$dbh->do("SAVEPOINT svp_0");
	$dbh->do("SAVEPOINT svp_1");
	$dbh->selectall_arrayref("SELECT * FROM sqlite_master");
	$dbh->do("COMMIT");
	# should not spit the "Issuing rollback()" warning
}

{ # end with rollback
	my $dbh = connect_ok(
		AutoCommit => 1,
		RaiseError => 1,
	);
	$dbh->do("SAVEPOINT svp_0");
	$dbh->do("SAVEPOINT svp_1");
	$dbh->selectall_arrayref("SELECT * FROM sqlite_master");
	$dbh->do("ROLLBACK");
	# should not spit the "Issuing rollback()" warning
}

{ # end with outermost release
	my $dbh = connect_ok(
		AutoCommit => 1,
		RaiseError => 1,
	);
	$dbh->do("SAVEPOINT svp_0");
	$dbh->do("SAVEPOINT svp_1");
	$dbh->selectall_arrayref("SELECT * FROM sqlite_master");
	$dbh->do("RELEASE svp_0");
	# should not spit the "Issuing rollback()" warning
}

{ # end by setting AutoCommit to true
	my $dbh = connect_ok(
		AutoCommit => 1,
		RaiseError => 1,
	);
	$dbh->do("SAVEPOINT svp_0");
	$dbh->do("SAVEPOINT svp_1");
	$dbh->selectall_arrayref("SELECT * FROM sqlite_master");
	$dbh->{AutoCommit} = 1;
	# should not spit the "Issuing rollback()" warning
}

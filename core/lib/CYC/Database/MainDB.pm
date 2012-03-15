package CYC::Database::MainDB;

=head1 SYNOPSIS

    use CYC::Database::MainDB;

    my $dbh = CYC::Database::MainDB->connect();

=head1 METHODS

=head2 connect

Connects to main database with read/write access.

=cut

use strict;
use warnings;

use Carp;
use DBI;
use CYC::Config;

sub default_options {
    return {
        RaiseError        => 1,
        PrintError        => 1,
        AutoCommit        => 1,
        ReadOnly          => 0,
        private_CacheKey  => $$,
        mysql_enable_utf8 => 1
    };
}

sub connect {
    my ($pkg, $attrs) = @_;
    unless (ref($attrs) eq 'HASH') {
        $attrs = $pkg->default_options;
    }
    my $dbh = DBI->connect_cached(
        CYC::Config->get("Database.MainDB.Driver"),
        CYC::Config->get("Database.MainDB.Username"),
        CYC::Config->get("Database.MainDB.Password"),
        $attrs
    ) or croak DBI->errstr;
    $dbh->ping or croak "Lost connection to DB 'MainDB'";
    return $dbh;
}

1;

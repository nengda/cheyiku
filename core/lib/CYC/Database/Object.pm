package CYC::Database::Object;

=head1 SYNOPSIS

    #
    # Creating a wrapper class
    #

    package Your::DB::Object;

    use base 'CYC::Database::Object';

    sub TABLE {
        return 'table_name';
    }

    1;


    #
    # Inserting an object into DB
    #

    use Your::DB::Object;

    my $obj = Your::DB::Object->new(
        field1 => 'abc',
        field2 => 'xyz'
    )->save;


    #
    # Fetching and updating an object
    #

    use Your::DB::Object;

    my $obj = Your::DB::Object->new(
        id => 123
    )->load;

    print "field1 = " . $obj->field1 . "\n";

    $obj->field2('ijk');

    $obj->save;


    #
    # Listing objects
    #

    use Your::DB::Object;

    my $array_ref = Your::DB::Object->get_objects(
        query => [
            field1 => { '=' => 'abc' },
            field2 => { 'like' => '%z' }
        ],
        sort_by => 'field1, field2' # Optional
    );


=head1 DESCRIPTION

CYC::Database::Object provides an simple way to create a wrapper class to represent a single row in MySQL table.

=head1 RESTRICTIONS

  1. The table must have a primary key and the primary key cannot be nullable.
  2. Date/time values must be in UTC. Format is 'YYYY-MM-DD HH:MM:SS'.
  3. get_objects only supports simple criteria.
  4. Referencing only works with primary key of the referenced table.

=head1 METHODS

=head2 new

Construct a DB object with initial values.

=head2 load

Read the object from DB.
The primary key value must be set before invoking this method.

=head2 save

Save the object into the DB.
If the primary key value is set, this will update the corresponding row in DB; otherwise, this will insert the object into the DB.

=head2 delete

Delete the object from DB.

=head2 get_value

Get the value for the given field.
To force the module to read the latest value from DB again, invoke with:
  $obj->get_value('field_name', no_cache => 1);

=head2 get_objects

Fetch multiple DB objects with simple criteria. See SYNOPSIS for usage.

=head2 delete_objects

Delete multiple DB objects with simple criteria. See SYNOPSIS for usage.

=head2 db_connect

Override this method if you need to connect to a different DB or if you wish to provide different DB connect options.

=head2 db_commit

Override this method if AutoCommit is enabled.

=head2 TABLE

Override this method to provide the table name.

=head2 REFERENCES

Override this method to provide info for referencing. Example:

    #
    # Wrapper class for ObjectA, with columns: id, field1, field2
    #

    package Your::DB::Object::A;

    use base 'CYC::Database::Object';

    sub TABLE {
        return 'TableA';
    }

    1;


    #
    # Wrapper class for ObjectB, with columns: id, object_a_id (references TableA.id), field3, field4
    #

    package Your::DB::Object::B;

    use base 'CYC::Database::Object';

    sub TABLE {
        return 'TableB';
    }

    sub REFERENCES {
        return {
            'object_a_ref' => { field => 'object_a_id', class => 'Your::DB::Object::A' }
        };
    }

    1;


    #
    # Usage
    #

    use Your::DB::Object::B;

    my $b = Your::DB::Object::B->new(id => 1)->load;

    my $a = $b->object_a_ref; # Returns an instance of Your::DB::Object::A

    print "TableA.field1 = " . $a->field1 . "\n";

    $a->field2('abc')->save;


=head2 EXCLUDED_COLUMNS

Override this method to provide list of fields that shouldn't be managed by the wrapper class.

=cut

use strict;
use warnings;

use Carp;
use DateTime::Format::MySQL;
use Scalar::Util qw/blessed/;
use CYC::Database::MainDB;

sub new {
    my ($pkg, %args) = @_;

    $pkg = ref($pkg) if (blessed($pkg));

    my $table_info = $pkg->_get_table_info($pkg->TABLE);
    my $columns = _remove_columns($table_info->{columns}, $pkg->EXCLUDED_COLUMNS);
    my %columns = map { $_ => 1 } @$columns;
    my %datetime_columns = map { $_ => 1 } @{$table_info->{datetime_columns}};
    my $references = $pkg->REFERENCES;

    foreach my $column (@$columns) {
        no strict 'refs';
        no warnings;
        *{$pkg . '::' . $column} = sub {
            my ($self, $value) = @_;
            if (@_ == 1) {
                return $self->{_values}->{$column};
            }
            elsif (@_ == 2) {
                $self->{_values}->{$column} = $value;
                $self->{_dirty_columns}->{$column} = 1;
                return $self;
            }
            else {
                croak "Unexpected number of arguments";
            }
        };
    }

    foreach my $reference (keys %$references) {
        no strict 'refs';
        no warnings;
        *{$pkg . '::' . $reference} = sub {
            my ($self, %args) = @_;
            return $self->_get_referenced_object($reference, %args);
        };
    }

    my $self = bless {
        _table => $pkg->TABLE,
        _columns => $columns,
        _primary_key => $table_info->{primary_key},
        _unique_keys => $table_info->{unique_keys},
        _datetime_columns => \%datetime_columns,
        _dirty_columns => { map { $_ => $columns{$_} } keys %args },
        _values => \%args,
        _references => $references,
        _referenced_objects => {}
    }, $pkg;

    return $self;
}

sub load {
    my $self = shift;
    my $dbh = $self->db_connect;

    my $table = $self->{_table};
    my $columns = $self->{_columns};
    my $primary_key = $self->{_primary_key};
    my $unique_keys = $self->{_unique_keys};
    my $datetime_columns = $self->{_datetime_columns};

    my @select_expr;
    foreach my $column (@$columns) {
        if ($datetime_columns->{$column}) {
            push @select_expr, "convert_tz($column, 'SYSTEM', '+00:00') as $column";
        }
        else {
            push @select_expr, "$column as $column";
        }
    }

    my $i = 0;
    my $lookup_key = $primary_key;
    while ((not defined $self->{_values}->{$lookup_key}) && $i < scalar(@$unique_keys)) {
        $lookup_key = $unique_keys->[$i++];
    }

    my $sth = $dbh->prepare_cached('select ' . join(', ', @select_expr) . ' from ' . $table . ' where ' . $lookup_key . ' = ?') or croak $dbh->errstr;
    $sth->execute($self->{_values}->{$lookup_key}) or croak $dbh->errstr;
    my $record = $sth->fetchrow_hashref;
    $sth->finish;
    $self->db_commit($dbh);

    croak "Unable to fetch object from database" unless $record;

    return $self->_load_from_hash($record);
}

sub _load_from_hash {
    my ($self, $hash) = @_;
    my $datetime_columns = $self->{_datetime_columns};
    foreach my $column (@{$self->{_columns}}) {
        my $value = $hash->{$column};
        if ($datetime_columns->{$column} && (defined $value) && ref($value) ne 'DateTime') {
            $value = DateTime::Format::MySQL->parse_datetime($value);
        }
        $self->$column($value);
    }
    return $self;
}

sub save {
    my $self = shift;
    my $dbh = $self->db_connect;

    my $table = $self->{_table};
    my $columns = $self->UPDATE_ALL_FIELDS_ON_SAVE ? $self->{_columns} : [ grep { $self->{_dirty_columns}->{$_} } keys %{$self->{_dirty_columns}} ];
    my $primary_key = $self->{_primary_key};
    my $datetime_columns = $self->{_datetime_columns};

    my $update = 0;
    if (defined $self->{_values}->{$primary_key}) {
        my $sth = $dbh->prepare_cached('select count(*) from ' . $table . ' where ' . $primary_key . ' = ?') or croak $dbh->errstr;
        $sth->execute($self->{_values}->{$primary_key}) or croak $dbh->errstr;
        if ($sth->fetchrow_hashref->{'count(*)'} > 0) {
            $update = 1;
        }
        $sth->finish;
    }

    if ($update) {
        my $statement = 'update ' . $table . ' set ' .
            join(', ', map { $_ . ' = ' . (($datetime_columns->{$_}) ? "convert_tz(?, '+00:00', 'SYSTEM')" : '?' ) } @$columns) .
            ' where ' . $primary_key . ' = ?';
        my $sth = $dbh->prepare_cached($statement) or croak $dbh->errstr;

        my @binds = map { $self->{_values}->{$_} } @$columns;
        push @binds, $self->{_values}->{$primary_key};
        $sth->execute(@binds) or croak $dbh->errstr;
        $sth->finish;
        $self->db_commit($dbh);
        $self->load;
    }
    else {
        my $columns_with_value = [];
        foreach my $column (@$columns) {
            if (defined $self->{_values}->{$column}) {
                push @$columns_with_value, $column;
            }
        }
        my $statement = 'insert into ' . $table . ' (' .
            join(', ', @$columns_with_value) . ') values (' .
            join(', ', map { ($datetime_columns->{$_}) ? "convert_tz(?, '+00:00', 'SYSTEM')" : '?' } @$columns_with_value) . ')';
        my $sth = $dbh->prepare_cached($statement) or croak $dbh->errstr;

        my @binds = map { $self->{_values}->{$_} } @$columns_with_value;
        $sth->execute(@binds) or croak $dbh->errstr;
        $self->$primary_key($dbh->{mysql_insertid})
            unless defined $self->$primary_key;
        $sth->finish;
        $self->db_commit($dbh);
        $self->load;
    }

    $self->{_dirty_columns} = {};
    return $self;
}

sub delete {
    my $self = shift;

    my $primary_key = $self->{_primary_key};

    if (defined $self->{_values}->{$primary_key}) {
        my $dbh = $self->db_connect;
        my $table = $self->{_table};
        my $statement = 'delete from ' . $table . ' where ' . $primary_key . ' = ?';
        my $sth = $dbh->prepare_cached($statement);
        $sth->execute($self->{_values}->{$primary_key}) or croak $dbh->errstr;
        $sth->finish;
        $self->db_commit($dbh);
        return 1;
    }

    return 0;
}

sub get_value {
    my ($self, $column, %args) = @_;
    if ($args{no_cache}) {
        my $dbh = $self->db_connect;
        my $primary_key = $self->{_primary_key};
        my $datetime_columns = $self->{_datetime_columns};
        my $select_expr = ($datetime_columns->{$column}) ? "convert_tz($column, 'SYSTEM', '+00:00') as $column" : $column;
        my $sth = $dbh->prepare_cached('select ' . $column . ' from ' . $self->{_table} . ' where ' . $primary_key . ' = ?') or croak $dbh->errstr;
        $sth->execute($self->{_values}->{$primary_key}) or croak $dbh->errstr;
        my $value = $sth->fetchrow_hashref->{$column};
        if ($datetime_columns->{$column} && (defined $value)) {
            $value = DateTime::Format::MySQL->parse_datetime($value);
        }
        $sth->finish;
        $self->db_commit($dbh);
        return $value;
    }
    return $self->{_values}->{$column};
}

sub delete_objects {
    my ($pkg, %args) = @_;

    my $dbh = $pkg->db_connect;
    return unless (defined $args{query});

    my $results = [];
    if (ref($args{query}) eq "ARRAY") {
        my $table = $pkg->TABLE;

        my $translated = [];
        my $binds = [];
        for (my $i = 0; $i < scalar(@{$args{query}}); $i += 2) {
            my $field = $args{query}->[$i];
            my $criteria = $args{query}->[$i + 1];
            foreach my $op (keys %$criteria) {
                push @$translated, $field . ' ' . $op . ' ?';
                push @$binds, $criteria->{$op};
            }
        }

        my $query = 'delete from ' . $table .
            ((scalar(@$translated) > 0) ? (' where ' . join(' and ', @$translated)) : '');
        my $sth = $dbh->prepare_cached($query) or croak $dbh->errstr;

        $sth->execute(@$binds) or croak $dbh->errstr;
        $sth->finish;
        $pkg->db_commit($dbh);
    }
    else {
        my $sth = $dbh->prepare_cached($args{query}) or croak $dbh->errstr;

        $sth->execute() or croak $dbh->errstr;
        $sth->finish;
        $pkg->db_commit($dbh);
    }
    return $results;
}

sub get_objects {
    my ($pkg, %args) = @_;

    my $dbh = $pkg->db_connect;
    $args{query} = [] unless (defined $args{query});

    my $results = [];
    if (ref($args{query}) eq "ARRAY") {
        my $table = $pkg->TABLE;
        my $table_info = $pkg->_get_table_info($table);
        my $primary_key = $table_info->{primary_key};
        my $columns = _remove_columns($table_info->{columns}, $pkg->EXCLUDED_COLUMNS);
        my %datetime_columns = map { $_ => 1 } @{$table_info->{datetime_columns}};

        my $translated = [];
        my $binds = [];
        for (my $i = 0; $i < scalar(@{$args{query}}); $i += 2) {
            my $field = $args{query}->[$i];
            my $criteria = $args{query}->[$i + 1];
            foreach my $op (keys %$criteria) {
                push @$translated, $field . ' ' . $op . ' ?';
                push @$binds, $criteria->{$op};
            }
        }

        my @select_expr;
        foreach my $column (@$columns) {
            if ($datetime_columns{$column}) {
                push @select_expr, "convert_tz($column, 'SYSTEM', '+00:00') as $column";
            }
            else {
                push @select_expr, "$column as $column";
            }
        }

        my $query = 'select ' . join(', ', @select_expr) . ' from ' . $table .
            ((scalar(@$translated) > 0) ? (' where ' . join(' and ', @$translated)) : '') .
            ((exists $args{sort_by}) ? (' order by ' . $args{sort_by}) : '') .
            ((exists $args{limit}) ? (' limit ' . $args{limit}) : '');
        my $sth = $dbh->prepare_cached($query) or croak $dbh->errstr;

        $sth->execute(@$binds) or croak $dbh->errstr;
        while (my $record = $sth->fetchrow_hashref) {
            push @$results, $pkg->new->_load_from_hash($record);
        }
        $sth->finish;
        $pkg->db_commit($dbh);
    }
    else {
        my $sth = $dbh->prepare_cached($args{query}) or croak $dbh->errstr;

        $sth->execute() or croak $dbh->errstr;
        while (my $record = $sth->fetchrow_hashref) {
            push @$results, $pkg->new->_load_from_hash($record);
        }
        $sth->finish;
        $pkg->db_commit($dbh);
    }
    return $results;
}

sub _get_referenced_object {
    my ($self, $name, %args) = @_;
    if ($args{no_cache} || (not defined $self->{_referenced_objects}->{$name})) {
        my $reference = $self->{_references}->{$name};

        my $reference_field = $reference->{field};
        my $referenced_class = $reference->{class};
        eval("use $referenced_class;");

        my $referenced_obj = eval("$referenced_class->new");
        my $referenced_key = $referenced_obj->{_primary_key};
        $referenced_obj->$referenced_key($self->{_values}->{$reference_field});
        $referenced_obj->load;

        $self->{_referenced_objects}->{$name} = $referenced_obj;
    }
    return $self->{_referenced_objects}->{$name};
}

my %_table_info;
sub _get_table_info {
    my ($pkg, $table, %args) = @_;
    if ($args{no_cache} || (not exists $_table_info{$table})) {
        my $dbh = $pkg->db_connect;
        my $columns = [];
        my $column_types = {};
        my $datetime_columns = [];
        my $primary_key = undef;
        my $unique_keys = [];
        my $sth = $dbh->prepare_cached('desc ' . $table) or croak $dbh->errstr;
        $sth->execute or croak $dbh->errstr;
        while (my $record = $sth->fetchrow_hashref) {
            my $column = $record->{Field};
            push @$columns, $column;
            if ($record->{Key} eq 'PRI') {
                $primary_key = $column;
            }
            elsif ($record->{Key} eq 'UNI') {
                push @$unique_keys, $column;
            }
            if ($record->{Type} eq 'datetime') {
                push @$datetime_columns, $column;
            }
            $column_types->{$column} = $record->{Type};
        }
        $sth->finish;
        $pkg->db_commit($dbh);
        $_table_info{$table} = {
            columns => $columns,
            primary_key => $primary_key,
            unique_keys => $unique_keys,
            column_types => $column_types,
            datetime_columns => $datetime_columns
        };
    }
    return $_table_info{$table};
}

sub _remove_columns {
    my ($columns, $excluded_columns) = @_;
    if (scalar(@$excluded_columns) > 0) {
        my $r = [];
        my %excluded = map { $_ => 1 } @$excluded_columns;
        foreach my $c (@$columns) {
            unless (exists $excluded{$c}) {
                push @$r, $c;
            }
        }
        return $r;
    }
    return $columns;
}

sub to_hash {
    my $self = shift;
    my $values = $self->{_values};
    return { map { $_ => $values->{$_} } keys %$values };
}

sub db_connect {
    my $pkg = shift;
    return CYC::Database::MainDB->connect;
}

sub db_commit {
    my ($pkg, $dbh) = @_;
    $dbh = $pkg->db_connect unless (defined $dbh);
    #$dbh->commit;
    return $dbh;
}

sub TABLE {
    die 'Not implemented';
}

sub COLUMNS {
    my $pkg = shift;
    $pkg = ref($pkg) if (blessed($pkg));
    my $table_info = $pkg->_get_table_info($pkg->TABLE);
    return _remove_columns($table_info->{columns}, $pkg->EXCLUDED_COLUMNS);
}

sub COLUMN_TYPES {
    my $pkg = shift;
    $pkg = ref($pkg) if (blessed($pkg));
    my $table_info = $pkg->_get_table_info($pkg->TABLE);
    my $columns = _remove_columns($table_info->{columns}, $pkg->EXCLUDED_COLUMNS);
    my $column_types = {};
    foreach my $column (@$columns) {
        $column_types->{$column} = $table_info->{column_types}->{$column};
    }
    return $column_types;
}

sub REFERENCES {
    return {};
}

sub EXCLUDED_COLUMNS {
    return [];
}

sub UPDATE_ALL_FIELDS_ON_SAVE {
    return 1;
}

1;

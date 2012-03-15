package CYC::Config;

=head1 SYNOPSIS

    # Create a config class:

    package CYC::Something::Config;

    use base 'CYC::Config';

    sub _config_file {
        return '/path/to/your/conf_file.yml';
    }


    # Use config value

    CYC::Something::Config->get('Namespace.Key');

=head1 METHODS

=head2 get

Gets the config value for the specified key from config file / KeyDB. See synopsis for usage.

=head2 get_all

Gets values for all keys under the specified namespace in the config file.

To avoid child processes to make DB connections for reading dynamic values, please invoke this method before forking.

=cut

use strict;
use warnings;

use Carp;
use Scalar::Util qw/blessed/;
use YAML qw/LoadFile/;

my %_configs;
my %_cache;

sub get {
    my ($pkg, $name, %options) = @_;

    if (blessed($pkg)) {
        $pkg = ref($pkg);
    }

    $options{no_cache} = 0 unless defined $options{no_cache};

    my $cache_key = $pkg . ',' . $name;
    if (exists $_cache{$cache_key} && $options{no_cache} == 0) {
        return $_cache{$cache_key};
    }

    my $value = $pkg->load_config_file;
    my @root = keys %$value;
    my $root = $root[0];
    $value = $value->{$root};

    my @path = split(/\./, $name);
    while (my $p = shift @path) {
        if (exists $value->{$p}) {
            $value = $value->{$p};
        }
        else {
            croak "No configuration value for '$name' in package '$pkg'";
        }
    }

    while (1) {
        last unless (defined $value);
        if ($value =~ /\<\<Dynamic\>\>/) {
            eval("use CYC::Database::MainDB;");
            my $dbh = CYC::Database::MainDB->connect;
            my $sth = $dbh->prepare_cached('select value from settings where name = ?');
            $sth->execute($root . '.' . $name);
            my $r = $sth->fetchrow_hashref;
            $sth->finish;
            croak "No value for dynamic setting '$name'" unless defined $r;
            $value = $r->{value};
        } elsif ($value =~ /\<\<Secret(,Name=(.+))?\>\>/) {
            my $secret_name = $2;
            unless (defined $secret_name) {
                $secret_name = $root . '.' . $name;
            }
            #$value = keydb_get_value($secret_name);
        } elsif ($value =~ /\<\<Reference=(.+?),(.+?)\>\>/) {
            my $referenced_package = $1;
            my $referenced_key = $2;
            eval("use $referenced_package;");
            $value = $referenced_package->get($referenced_key, %options);
        } else {
            last;
        }
    }

    $_cache{$cache_key} = $value;
    return $value;
}

sub get_all {
    my ($pkg, $namespace, %options) = @_;

    if (blessed($pkg)) {
        $pkg = ref($pkg);
    }

    unless (exists $_configs{$pkg}) {
        my $config_file = $pkg->_config_file;
        $_configs{$pkg} = LoadFile($config_file);
    }

    my $value = $_configs{$pkg};
    my @root = keys %$value;
    my $root = $root[0];
    $value = $value->{$root};

    $namespace = '' unless defined $namespace;
    my @path = split(/\./, $namespace);
    while (my $p = shift @path) {
        if (exists $value->{$p}) {
            $value = $value->{$p};
        }
        else {
            croak "Unknown namespace '$namespace' in package '$pkg'";
        }
    }

    my $values = {};
    $pkg->_get_all($value, $namespace, $values, %options);
    return $values;
}

sub _get_all {
    my ($pkg, $node, $path, $values, %options) = @_;
    $path .= '.' if (length($path) > 0);
    foreach my $k (keys %$node) {
        my $child_path = $path . $k;
        my $value = $node->{$k};
        if (ref($value) eq 'HASH') {
            $pkg->_get_all($value, $child_path, $values, %options);
        }
        else {
            eval {
                $values->{$child_path} = $pkg->get($child_path, %options);
            };
            if (my $e = $@) {
                die $e unless ($options{ignore_errors});
            }
        }
    }
}

sub load_config_file {
    my $pkg = shift;
    unless (exists $_configs{$pkg}) {
        my $config_file = $pkg->_config_file;
        $_configs{$pkg} = LoadFile($config_file);
    }
    return $_configs{$pkg};
}

sub _config_file {
    return '/home/y/conf/cyc_core.yml';
}

1;

package Params::Validate::Commandline;
use strict; use warnings;

use Params::Validate ':all';
use Data::Dumper;
use Params::Validate::Normalize 'normalize_parameters';

=head1 SYNOPSIS

    # In myscript.pl
    use Params::Validate::Commandline 'parse_commandline';

    my ($args, $positional) = validate_commandline(
        \@ARGV,
        # Validation specs
        {
            foo => 1, #mandatory
            bar => 0, #optional
        }
    );

    print "Foo is $args{foo}\n";
    print "Bar is $args{bar}\n";
    print "Positional arguments are: ".join(",", @$positional)."\n";


=head2 Now, from the commandline

perl myscript.pl 'some argument' -foo 12 -bar 20

=head1 DESCRIPTION

Works much like Params::Validate::validate, except
  - takes a list of command-line arguments (probably @ARGV), instead of a list of subroutine arguments in @_.  Parses arguments using Getopt::Long.
  - returns a hashref of the parsed arguments, plus an arrayref of any extra 'positional' parameters.

See Params::Validate for details on the validation spec.

See Getopt::Long for details on commandline parsing.


=head1 SEE ALSO

Params::Validate
GetOpt::Long
Params::Validate::Accessors

=head1 AUTHOR

Jonathan Warden <wardenj@yahoo-inc.com>

=cut


use base 'Exporter';

push our @EXPORT_OK, 'parse_commandline', 'validate_commandline', 'generate_usage';

use Log::Log4perl;
my $logger = Log::Log4perl->get_logger;

=head2 getopt_spec

  my $getopt_spec = getopt_spec($validate_spec);

  Converts a Params::Validate parameter spec (to be passed to Params::Validate::validate_spec) to a Getopt::Long parameter spec (to be passed to GetOptions).


=cut

sub getopt_spec {
    my($parameters) = @_;

    my @arguments;

    for my $param (keys %$parameters) {
        my $type;

        if(ref $parameters->{$param}) {
            $type = $parameters->{$param}->{type};
        }

        my $def;
        if(! defined $type or $type eq Params::Validate::SCALAR) {
            $def = "$param=s";
        }
        elsif($type eq Params::Validate::BOOLEAN) {
            $def = "$param";
        }
        elsif($type eq Params::Validate::ARRAYREF) {
            $def = "$param=s@";
        }
        elsif($type eq Params::Validate::HASHREF) {
            $def = "$param=s%";
        }

        push @arguments, $def;
    }
    # warn Dumper(\@arguments);
    return \@arguments;
}


=head2 generate_usage

  my $usage = generate_usage($validation_spec, "No way, man");
  print STDERR $usage;
  exit 1;

Takes a Params::Validate spec, and produce a nice 'usage' method.

=cut

sub generate_usage {
    my($parameters, $message) = @_;

    $message ||= '';
    chomp $message;
    $message .= "\n";

    my %required = map {
        my $definition  = $parameters->{$_};
        my $optional = !$definition || (
            ref $definition and (
                $definition->{optional} or $definition->{default}
            )
        );
        $_ => !$optional;
    } keys %$parameters;

    my @docs;
    for my $type ('required', 'optional') {
        $message .= "$type parameters\n-----------\n";
        PARAM: for my $param (sort {lc($a) cmp lc($b)} keys %$parameters) {
            next PARAM if $type eq 'required' and not $required{$param};
            next PARAM if $type eq 'optional' and $required{$param};

            my $definition  = $parameters->{$param};
            my $doc = $param;
            if(ref $definition and $definition->{doc}) {
                $doc = sprintf("%-20s", "$param:");
                $doc .= $definition->{doc};
            }
            $message .= "    $doc\n";
        }
    }

    return $message;
}

use Getopt::Long;

our $current_parameters;
Params::Validate::validation_options(
    on_fail => sub {
        my($message) = @_;

        $message =~ s/in call to \S+?/in commandline arguments/;
        $message =~ s/to Params::Validate::Commandline::parse_commandline?/in commandline arguments/;
        $message =~ s/to .+_try_as_caller?/in commandline arguments/;

        die generate_usage($current_parameters, $message);
    }
);


=head2 parse_commandline

Like validate_commandline, but not Params::Validate validation.

=cut

sub parse_commandline {
    my($argv, $parameters, $allow_unknown_parameter) = @_;

    my $getopt_spec = getopt_spec($parameters);

    my %options;

    # GetOptions expects options to be in @ARGV
    local @ARGV = @$argv;
    my $message;
    local $SIG{__WARN__} = sub { $message .= shift()."\n" };
    my $success = do {
        GetOptions(
            \%options,
            @$getopt_spec,
        );
    };
    $logger->debug( sub { "dumper command line options:\n" . Dumper(\%options) } );
    if(! $success) {
        if ( $allow_unknown_parameter ) {
            $logger->warn( generate_usage($parameters, $message) );
        } else {
            die generate_usage($parameters, $message);
        }
    }

    ### TODO: parse more complicated options, like:
    ###   filters => { accountID => [qw(123 456)], date => { '>=' => '20060405', '<=' => '20060405' } },
    ### so the commandline should be like:
    ###   --filters=accountID='123,456' --filters=date='>=,20060405,<=,200604005'

    my @remainder = @ARGV;
    return (\%options, \@remainder);
}

=head2 validate_commandline

See synopsis

=cut

sub validate_commandline {
    my($argv, $parameters) = @_;

    my ($options, $extra) = parse_commandline($argv, $parameters);

    $parameters = normalize_parameters($parameters);

    local $current_parameters = $parameters;
    my %args = validate_with(
        params => $options,
        stack_skip => 1,
        spec => $parameters,
    );

    return (\%args, $extra);
}





1;

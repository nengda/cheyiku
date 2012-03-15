package Params::Validate::ConfigFile;
use strict; use warnings;

use Params::Validate::Commandline 'parse_commandline', 'generate_usage';
use Config::Auto;
use Getopt::Long;
use Data::Dumper;
use Params::Validate::Normalize 'normalize_parameters';
use Params::Validate ':all';

use base 'Exporter';
push our @EXPORT_OK, 'validate_config_commandline', 'validate_config_file', 'parse_config_commandline', 'parse_config_file';

use Log::Log4perl;
my $logger = Log::Log4perl->get_logger;

=head1 SYNSOPSIS

    my $options = validate_config_commandline(\@ARGV,
        {
            # optional
            foo => 1,
            bar => 0,
        }
    );

=head2 Meanwhile, in a nearby config file my_config.conf

    ---
    foo: 10
    bar: 20

=head2 Now, from the commandline

    perl myscript.pl my_config.conf -foo 20

=head1 DESCRIPTION

What's the idea?

  - Define a bunch of parameters to your application in the same way you define parameters to subroutines using Params::Validate
  - Create config files containing parameters for your application
  - Invoke your application from the commandline.

  In other words, combine 3 great classes:
    - Params::Validate
    - Config::Auto
    - GetOpt::Long

  For more on config file format, see Config::Auto.
  For more on commandline format, see Getopt::Long.
  For more on validationhn specs, see Params::Validate

=head1 EXTRA OPTIONS

Any extra options passed after the validation spec will be passed to Config::Auto,
except for the one option specific to this class: enable_inheritance.

Most notably, you may be interested in:

=head3 format

(xml, perl, yaml, etc)

=head3 path

directory in which to search for config file.

=head1 INHERITENCE

This is a handy feature if you've got tons of config files, and they share lots of common options.

    # First, enable inheritance
    my $options = validate_config_commandline(\@ARGV, $spec, enable_inheritance => 1);

=head2 Now, config files can reference other config files to inherit from.

    # Contents of my_config.conf
    ---
    inherit: base_config.conf

=head1 SEE ALSO

Params::Validate::Commandline
Config::Auto
Getopt::Long
Params::Validate
Params::Validate::Accessors

=cut


our $current_parameters;
Params::Validate::validation_options(
    on_fail => sub {
        my($message) = @_;

        $message =~ s/in call to \S+?/in commandline arguments/;
        $message =~ s/to Params::Validate::ConfigFile::parse_commandline?/in commandline arguments/;
        $message =~ s/to .+_try_as_caller?/in commandline arguments/;

        die generate_usage($current_parameters, $message);
    }
);


=head2 parse_config_commandline

Same as validate_config_commandline, but doesn't check for valid parrameters.  Does, however, produces a usage message on unrecognized param names.

=cut

sub parse_config_commandline {
    my($argv, $parameters, %parse_args) = @_;

    $logger->info("Parsing commandline...");
    my ($commandline_options, $positional_args) = parse_commandline($argv, $parameters, $parse_args{allow_unknown_parameter});

    my $filename = $positional_args->[0];

    my $config_options;
    if($filename) {
        $logger->info("Parsing config file...");
        $config_options = parse_config_file($filename, %parse_args);
    } else {
        $config_options = {};
    }

    my $options = {
        %$config_options,
        %$commandline_options,
    };

    return $options;
}

=head2 validate_config_commandline

See synopsis.`

=cut


sub validate_config_commandline {
    my($argv, $parameters, %config_auto_args) = @_;

    my $options = parse_config_commandline(@_);

    $parameters = normalize_parameters($parameters);

    $logger->info("Validating all parameters...");

    local $current_parameters = $parameters;
    my %args;
    eval {
        %args = validate_with(
            params => $options,
            stack_skip => 1,
            spec => $parameters,
        );
    };
    if ( $@ ) {
        die "$@" unless $config_auto_args{'allow_unknown_parameter'};
        %args = %$options;
        $args{ERROR} = "$@\n$!";
    }

    $logger->debug( sub {"dumper config and/or commandline options:\n". Dumper(\%args) } );
    return \%args;
}


=head2 parse_config_file

  my $args = parse_config_file($filename, %options_for_getopt_auto);

  - Parses a config file without validating.
  - Recognizes the enable_inheritance argument.

=cut

sub parse_config_file {
    my($filename, %config_auto_args) = @_;

    my $enable_inheritance = $config_auto_args{enable_inheritance};

    $logger->info(" - parsing config file: $filename");
    my $config = Config::Auto::parse($filename, %config_auto_args);

    if($enable_inheritance and my $inherit = $config->{inherit}) {
        my $inherited_config = parse_config_file($inherit, %config_auto_args);
        $config = {
            %$inherited_config,
            %$config
        };
        delete $config->{inherit};
    }
    $logger->debug( sub { "dumer config file options:\n" . Dumper($config) } );

    return $config;
}

=head2 validate_config_file

  my $args = validate_config_file($filename, $parameters, %options_for_getopt_auto);

  - Parses a config file and validates
  - Recognizes the enable_inheritance argument.

=cut

sub validate_config_file {
    my($filename, $parameters, %config_auto_args) = @_;

    my $options = parse_config_file($filename, %config_auto_args);

    $parameters = normalize_parameters($parameters);

    local $current_parameters = $parameters;
    my %args = validate_with(
        params => $options,
        stack_skip => 1,
        spec => $parameters,
    );

    return \%args;


}



1;

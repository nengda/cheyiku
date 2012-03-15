package CYC::Web::Init;

use strict;
use warnings;

BEGIN {
    warn "  Initializing CYC Web Framework...\n";

    sub load_module {
        my $pkg = shift;
        warn "   Loading $pkg...\n";
        local $SIG{'__WARN__'} = sub {
            my $s = shift;
            my @lines = split(/\n/, $s);
            foreach my $line (@lines) {
                print STDERR "    $line\n";
            }
        };
        eval("use $pkg");
        if (my $e = $@) {
            die $e;
        }
    }

    # Preload web configs
    load_module('CYC::Web::Config');
    CYC::Web::Config->load_config_file;
    my $log_level = CYC::Web::Config->get('DefaultLogLevel');

    # Initializing Log4perl
    use Log::Log4perl;
    Log::Log4perl::init({
        'log4perl.rootLogger'                                      => "$log_level, SCREEN",
        'log4perl.appender.SCREEN'                                 => 'Log::Log4perl::Appender::Screen',
        'log4perl.appender.SCREEN.layout'                          => 'PatternLayout',
        'log4perl.appender.SCREEN.layout.ConversionPattern'        => '%d - %c:%L {%P} %m%n'
    });

    # Make DB connections persistent
    load_module('Apache::DBI');

    # Preload configs
    load_module('CYC::Config');
    CYC::Config->load_config_file;

    # Authentication module
    load_module('CYC::Web::Authentication');
}

1;

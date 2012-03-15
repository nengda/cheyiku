package CYC::TabularDataReader::CSV;

use strict;
use warnings;

use base 'CYC::TabularDataReader::GenericText';

use Encode 'decode';
use Text::CSV_XS;

my $csv_parser;

sub new {
    my ($class, %args) = @_;
    my $self = CYC::TabularDataReader::GenericText->new(%args);
    return bless($self, $class);
}

sub parse_line {
    my ($self, $line) = @_;
    $csv_parser ||= Text::CSV_XS->new({binary => 1});
    die "Error parsing CSV file.\n" unless ($csv_parser->parse($line));
    return [ $csv_parser->fields() ];
}

1;

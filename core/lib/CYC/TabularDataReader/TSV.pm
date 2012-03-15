package CYC::TabularDataReader::TSV;

use strict;
use warnings;

use base 'CYC::TabularDataReader::GenericText';


sub new {
    my ($class, %args) = @_;
    my $self = CYC::TabularDataReader::GenericText->new(%args);
    return bless($self, $class);
}


sub parse_line {
    my ($self, $line) = @_;
    return [ map {
        my $value = $_;
        if ($value =~ /^\"(.*)\"$/) {
            $value = $1;
            $value =~ s/\"\"/\"/g;
        }
        $value;
    } split("\t", $line) ];
}


1;

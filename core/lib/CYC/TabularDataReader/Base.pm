package CYC::TabularDataReader::Base;

use strict;
use warnings;

use Carp;


sub new {
    my ($class, %args) = @_;
    my $self = bless \%args, $class;
    return $self;
}


sub header_fields {
    die "Not implemented";
}


sub line_count {
    die "Not implemented";
}


sub get_row_hash {
    die "Not implemented";
}


sub close {
}


1;

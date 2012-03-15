package CYC::Web::Serializer;

use strict;
use warnings;
use CYC::Web::Serializer::XML;

my $serializer;
sub get_instance {
    $serializer = CYC::Web::Serializer::XML->new() 
        unless defined $serializer;

    return $serializer;
}

1;

package Params::Validate::Normalize;
use strict; use warnings;

use base 'Exporter';
push our @EXPORT_OK, 'normalize_parameters';

use Carp;

sub normalize_parameters {
    my($parameters, %args) = @_;

    confess "Missing attribute list" if not $parameters;
    if(ref($parameters) eq 'ARRAY') {
        $parameters = {
            map {
                $_ => {
                    optional => 1,
                }
            } @$parameters
        };
        return $parameters;
    }
    elsif(ref($parameters) eq 'HASH') {
        for my $attribute (keys %$parameters) {
            my $spec = $parameters->{$attribute};
            if(not ref $spec) {
                $parameters->{$attribute} = {optional => $args{all_optional} ? 1 : !$spec};
            }
            elsif($spec->{default_sub} or $spec->{default} or $args{all_optional}) {
                $spec->{optional} = 1;
            }
        }

    }

    return $parameters;
}

1;

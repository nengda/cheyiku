package CYC::Web::Serializer::XML;

use strict;
use warnings;

sub new {
    my ($pkg) = @_;

    my $self = bless {}, $pkg;
    return $self;
}

sub serialize {
    my ($self, %args) = @_;

    $args{status} ||= "Error";
    my $status = $args{status};
    my $data = _serialize($args{data});
    return "<response><status>$status</status><data>$data</data></response>";
}

sub _serialize {
    my ($obj) = @_;
    my $data = "";

    if (my $ref = (ref $obj)) {
        if ($ref eq 'ARRAY') {
            for (@$obj) {
                $data .= _serialize($_);
            }
        } elsif ($ref eq 'HASH') {
            for my $key (keys %$obj) {
                my $value = _serialize($obj->{$key});
                $data .= "<$key>$value</$key>";
            }
        }
    } else {
        $data = $obj;
    }
    return $data;
}

1;

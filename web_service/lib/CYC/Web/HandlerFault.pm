package CYC::Web::HandlerFault;

use strict;
use warnings;

sub new {
    my ($pkg, %args) = @_;
    $args{status} = 'Error' unless (defined $args{status});
    $args{message} = 'An unknown internal service error has occurred.' unless (defined $args{message});
    $args{displayable} = 0 unless (defined $args{displayable});
    return bless \%args, $pkg;
}

sub status {
    my $self = shift;
    if (scalar(@_) == 0) {
        return $self->{status};
    }
    else {
        $self->{status} = shift;
    }
    return $self;
}

sub message {
    my $self = shift;
    if (scalar(@_) == 0) {
        return $self->{message};
    }
    else {
        $self->{message} = shift;
    }
    return $self;
}

sub displayable {
    my $self = shift;
    if (scalar(@_) == 0) {
        return $self->{displayable};
    }
    else {
        $self->{displayable} = shift;
    }
    return $self;
}

1;

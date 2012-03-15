package Params::Validate::Constructor;
use strict; use warnings;

use Carp qw/cluck croak/;
use Exporter;
use Params::Validate ':all';
use Params::Validate::Normalize 'normalize_parameters';

our @EXPORT_OK    = (@Params::Validate::EXPORT_OK, 'check_parameters', 'install_constructor', 'build', 'clone', 'new');
our @ISA         = qw/Exporter/;
our %EXPORT_TAGS = (
    %Params::Validate::EXPORT_TAGS,
    all          => \@EXPORT_OK,
);

use Params::Validate::Accessors;

our $current_method;


Params::Validate::validation_options(
    on_fail => sub {
        my($message) = @_;


        # Params::Validate::validate expects to be called from within a sub taking params
        # But we're calling it from within an anonymous subroutine
        # That will replace the acessor
        # So we need to change error messages to show the name of the accessor
        my $package = __PACKAGE__;

        if($current_method) {
            $message =~ s/${package}::__ANON__/$current_method/g;
        }

        die $message;
    }
);



# Vanilla constructor.  Can be invoked on an object (in which case it clones) or a package.
# Builds object by calling accessors
# Dies on parameters that don't have accessors.

use Sub::Uplevel 'uplevel';
sub build {
    my($invocant, %args) = @_;

    my $pkg = ref $invocant || $invocant;

    # Construct instance
    my $newobject = bless {}, $pkg;

    local $current_method = __PACKAGE__.'::build';

    if(ref $invocant) {
        for my $key (keys %$invocant) {
            $newobject->$key($invocant->$key) if $pkg->can($key);
        }
    }
    for my $key (keys %args) {
        eval {
#            warn "SEtting value $key = $args{$key}";
            $newobject->$key($args{$key});
        };

        $@ and do {
            my $error = $@;
            $error =~ s/at .+Constructor\.pm line (\d+)\s*//sg;
            uplevel(2, sub {
                croak "Invalid parameter passed to constructor of $pkg: $error";
            })
        }
    }

    return $newobject;
}

sub new { shift()->Params::Validate::Constructor::build(@_); }
sub clone { shift()->Params::Validate::Constructor::build(@_); }

=old
sub clone {
    my($object, %args) = @_;

    my $pkg = ref($object) or croak "Clone must be called on a class";

    local $current_method = __PACKAGE__.'::clone';

    my $self = bless {}, $pkg;
    # Only set values for which there are accessors.
    for my $key (keys %$object) {
        $self->$key($object->$key) if $pkg->can($key);
    }

#    my $self = bless {
#        %$object,
#    }, $pkg;


    for my $key (keys %args) {
        eval {
            $self->$key($args{$key});
        };

        $@ and croak "Invalid parameter passed to clone in package $pkg: $@";
    }

    return $self;

}
=cut


sub install_constructor {
    my $package = shift;
    my %args = validate(@_, { parameters => 0, name => 0 } );


    my $method_name = $args{name} || 'new';

    local $current_method = 'constructor';

    my $method;
    if(not $args{parameters}) {
        no strict 'refs';
        $method = *{'clone'};
    } else {
        # Normalize params so they are all hashes
        # And all optional params have optional => 1
        my $parameters = normalize_parameters($args{parameters});

        use Data::Dumper;
        $method = sub {
            my $pkg = shift;

            return $pkg->Params::Validate::Constructor::build(@_) if ref($pkg);

            local $current_method = "${package}::${method_name}";
            my @args = validate_with(
                params => \@_,
                spec => $parameters,
                allow_extra => 1,
            );
            my $self = $pkg->Params::Validate::Constructor::build(@args);

            return $self;
        };
    }

    no strict 'refs';
    *{"${package}::${method_name}"} = $method;

    return $method;
}


=head1 SYNOPSIS

    package MyPackage;

    #...build some accessor methods using something like ...
    #  - Class::Acccessors
    #  - Params::Validate::Accessors;

    use Params::Validate::Constructor 'new';

    # Your package now has a kick-ass constructor!

=head1 DESCRIPTION

    Import the 'new', 'build', and 'clone' methods from this package.  These packages actually all behave the same way:
      - Take named parameters as arguuments (e.g. 'key' => $value)
      - Build your object by calling setters with the named argument (instead of just blessing a hash)
      - Clones and extends an existing object if called on an object

    To use this class, you have to have getter-setters that allow you to set a value by calling $object->$property($value)

=head1 VALIDATING REQUIRED PARAMTERS

These constructors don't know which parameters are required.  If you want
a constructor that does on missing required parameters, use 'install_constructor'.  Example:

    install_constructor(__PACKAGE__, parameters => { foo => 1, bar => 0}, name => 'new');

=head1 DO IT YOURSELF

The constructor that is installed for your class looks like this:

    sub new {
        my $pkg = shift;

        my @args = validate_with(
            params => \@_,
            spec => $parameters,
            allow_extra => 1,
        );

        return $pkg->Params::Validate::Constructor::build(@args);
    }

So you can mix and match if you need to....

=head1 SEE ALSO

Params::Validate
Params::Validate::Accessors

=cut


1;

package Params::Validate::Accessors;

use strict; use warnings;

use Carp qw/cluck croak/;
use strict;
use Exporter;
use Sub::Uplevel 'uplevel';
use Params::Validate ':all';
use Carp;
use Params::Validate::Normalize 'normalize_parameters';

our @EXPORT_OK    = (@Params::Validate::EXPORT_OK, 'install_accessors');
our @ISA         = qw/Exporter/;
our %EXPORT_TAGS = (
    %Params::Validate::EXPORT_TAGS,
    all          => \@EXPORT_OK,
);

our $current_method;
Params::Validate::validation_options(
    on_fail => sub {
        my($message) = @_;

        # Params::Validate::validate expects to be called from within a sub taking params
        # But we're calling it from within an anonymous subroutine
        # That will replace the acessor
        # So we need to change error messages to show the name of the accessor
        $message =~ s/(?<=Params::Validate::Accessors::)__ANON__/$current_method/g;

        die $message;
    }
);



sub _resolve_sub {
    my ($class, $sub_name) = @_;
    my $qualified_sub_name = "$class\::$sub_name";

    no strict 'refs';
    my $coderef = *{$qualified_sub_name}{CODE};
    return {
        class => $class,
        coderef => $coderef,
    } if $coderef;

    my @base_classes = @{"$class\::ISA"};
    foreach my $base_class (@base_classes) {
        my $result = _resolve_sub($base_class, $sub_name);
        return $result if $result;
    }

    return undef;
}

sub _get_default_sub_name {
    my ($class, $attribute, $default_sub_name) = @_;

    my $default_sub;
    if (not $default_sub_name =~ /\:\:/) {
        my $resolve_result = _resolve_sub($class, $default_sub_name) or
            croak "Unable to resolve sub $class\::$default_sub_name to use as default_sub for attribute $attribute";
        $class = $resolve_result->{class};
        $default_sub = $resolve_result->{coderef};
        $default_sub_name = "$class\::$default_sub_name";
    }
    else {
        no strict 'refs';
        $default_sub = *{$default_sub_name}{CODE} or
            croak "No such sub $default_sub_name to use as default_sub for attribute $attribute";
    }

    # If overriding sub that has same name of attribute
    # Then we need to re-install the default_sub undef a new ame
    if ($default_sub_name eq "${class}::${attribute}") {
        $default_sub_name = "${class}::default_${attribute}";
        no strict 'refs';
        *{$default_sub_name} = $default_sub;
    }

    return $default_sub_name;
}

sub install_accessors {
    my($class, $parameters, @extra) = @_;

    croak "Argument to install_accessors should be single arrayref or hashref" if @extra ;

    $parameters or confess "No attrib";

    $parameters = normalize_parameters($parameters);

    foreach my $attribute ( keys %$parameters ){
        no strict 'refs'; # referencing sub by name
        my $spec = $parameters->{ $attribute };
        my $sub_name = "${class}::${attribute}";
        my $default_sub_name;
        if($spec->{default_sub}) {
            $default_sub_name = _get_default_sub_name($class, $attribute, $spec->{default_sub});
        }
        my $new_accessor = _build_accessor(
            $attribute,
            $spec,
            $default_sub_name
        );
        # Override without warnings if one of these args is passed
        if($spec->{default_sub} or $spec->{override}) {
            no warnings; # redefined error
            *{$sub_name} = $new_accessor;
        }
        elsif(*{$sub_name}{CODE}) {
            croak "Trying to install accessor for existing subroutine '$sub_name'.  Define the accessor with override or default_sub if you really want to do this.  See 'perldoc ".__PACKAGE__."' for more info."
        } else {
            *{$sub_name} = $new_accessor;
        }
    }
}

sub _build_accessor {
    my ( $attribute, $validation_spec, $default_sub ) = @_;

#    my $default = $validation_spec->{default} if ref $validation_spec;
#    local $validation_spec->{default} = undef;

    croak unless ref($validation_spec) eq 'HASH' or not ref($validation_spec);
    $validation_spec = {} unless defined $validation_spec;

    my $default = $validation_spec->{default};
    my $optional = $validation_spec->{optional};

    return sub {
        my ( $self, $value ) = @_;

        croak "Too many arguments to accessor method $attribute" if @_ > 2;

        ### Package invocation
        if(not ref $self) {
            if(int(@_) == 1) {
                # Must have default
                if(defined $default) {
                    return $default;
                }
                elsif($default_sub) {
#                    return uplevel(2, sub {
                        return $self->$default_sub;
#                    },@_);
                }
                else {
                    croak "Getter method should be invoked on a reference, not $self";
                }
            } else {
               croak "Setter method should be invoked on a reference, not $self";
            }
        }

        ### For error message.  See Params::Validate::validation_options above.
        local $current_method = $attribute;

        ### If called as a getter
        if( @_ == 1  ) {

            # Set default value through Params::Validate
            # If there is a 'default' in the validation spec.
            if(not exists $self->{$attribute}) {
                if($default) {
                    ($self, $self->{ $attribute }) =
                        validate_pos( @_, 1, $validation_spec, undef )
                }
                # If there is not a default in validation spec, try a default sub
                elsif($default_sub) {
#                    $self->{$attribute} = $default_sub->($self);
                    $self->{ $attribute } = uplevel(2, sub {
                        $self->$default_sub($value);
                    },@_);

                }
                # Otherwise, this has better be optional.
                elsif($optional) {
#                    $self->{$attribute} = undef;
                    return undef;
                } else {
                    croak "Required attribute '$attribute' has not been set!";
                }
            }
            return $self->{ $attribute };
        }
        # Otherwise, it's a setter.  Validate first.
        elsif( @_ == 2 ) {
            ($self, $self->{ $attribute }) =
                validate_pos( @_, 1, $validation_spec );
            return $self;
        }
    };
}


1;

=head1 SYNOPSIS

    use Params::Validate::Accessors 'install_accessors';

    install_accessors(
         __PACKAGE__,
         {
            age => { regex => qr/^\d+$/ }
         }
    );

=head1 EVEN SIMPLER SYNOPSIS

    use Params::Validate::Accessors 'install_accessors';
    install_accessors(__PACKAGE__,  [qw(foo bar baz)] );

=head1 DESCRIPTION

This class creates accessors (getter-settors) based on Params::Validate validation specs.

  Features of note:
    - Accessors can be chained
    - Respects defaults defined in validation spec
    - For parameters that are not optional in validation sepc
      - croak if they are accessed before they is set.
      - if explicitly set as 'undef', considered valid.  This is how Params::Validate behaves.
    - Can use subs as default.
    - Allows package-invocation for getters with defaults
    - Optional vanilla constructor, and a method for validating required params that's useful for making your own constructors

=head1 OVERRIDING SUBROUTINES

    sub my_sub {
        return 'default value';
    }

    use Params::Validate::Accessors 'install_accessors';
    install_accessors(
         __PACKAGE__,
         # Override the existing my_sub
         # But, the overriden sub serves as the default value
         my_sub => {
            default_sub => 'my_sub',
         }
    );


=head1 VALIDATING CONSTRUCTOR

    use Params::Validate::Accessors 'install_accessors';
    sub accessors {
        return {
            foo => 1,
            bar => 0,
        }
    }
    install_accessors(__PACKAGE__, accessors());

    sub new {
        # Construct by calling accessors
        my $self = shift()->Params::Validate::Accessors::new(@_);

        # Check for presence of required attribs
        $self->check_required_parameters(accessors());

        return $self;
    }


=head1 SEE ALSO

Params::Validate


=head1 AUTHORS

 John Warden   L<wardenj@yahoo-inc.com>
 Jeff Lavallee L<lavallej@yahoo-inc.com>

=cut

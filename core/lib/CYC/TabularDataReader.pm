package CYC::TabularDataReader;

use strict;
use warnings;

=head1 SYNOPSIS

  # Create the reader
  my $reader = CYC::TabularDataReader->new(
      file => 'myfile.tsv',
      style => 'tsv'
  );

  # Read through the file.
  while (my $row = $reader->()) {
      # It's all parsed into a hash.
      $row->{column1};
  }

  $reader->close();

=head1 METHODS

=head2 new

Constructor. Parameters:

=head3 Mandatory

=over 4

=item file

Name or handle of input file.

=back

=head3 Optional

=over 4

=item style

Specifies file style: tsv, csv, xls, other_delimited.
If style is 'other_delimited', a delimiter must also be specified.
If the style is not provided, the reader will try to guess.

=item delimiter

Specifies the delimiter if style is 'other_delimited'.

=item encoding

Open file in specified encoding

=item allow_dos_format

Tells the reader to ignore CRLF.

=item schema

Defines the schema of the file in the syntax of Params::Validate.
  Example:
  schema => {
      column1 => 0,                                         # This column is optional
      column2 => 1,                                         # This column is required, but not necessarily contains data
      column3 => { optional => 0, type => SCALAR },         # This column is required and it must contain data.
      column4 => { optional => 1, type => SCALAR },         # This column is not required; but if exists, it must contain data.
      column5 => { optional => 0, type => UNDEF | SCALAR }, # Another way to say 'column5 => 1'
  },

=item allow_unknown_headers

If false, the reader will croak if there are unknown header fields (header fields that are not in the schema).

=item on_schema_validation_fails

Specifies the behavior when schema validation fails.
  none: Skip the invalid row, returns the next valid row.
  warn: Print a warning message to STDERR and returns undef.
  die: Die.

=item strip_enclosing_quotes

Tells the reader to strip enclosing quotes for the specified fields.
Values can be 'all' or an ARRAYREF.

=item default_value

Specifies the default value for empty cells.

=item worksheet_number

Specifies the worksheet number if input is an Excel file.

=item zip_ignore_pattern / zip_pattern

Since a zip file may contain multiple files, and the reader can only read from one, these two options allow you to specify exactly which file will be used.
They are regular expressions.

=back

=head2 header_fields

Gets the header fields.

=head2 line_count

Returns the total number of lines in the input file, if available.

=head2 get_stream

Returns CODEREF that return a row on each call.

=head2 slurp

Reads to the end and return an array of rows.

=head2 close

Close the file.

=cut

use overload '&{}' => 'get_stream', fallback => 'TRUE';

use Carp;
use Data::Dumper;
use Memoize;
use Archive::Zip  qw(:ERROR_CODES :CONSTANTS);
use Params::Validate ':all';
use Params::Validate::Accessors 'install_accessors';
use File::Temp qw/tempfile/;
use CYC::TabularDataReader::GenericText;

# Parameters' Spec
sub parameters {
    return {
        file                       => { type => SCALAR | GLOBREF },
        style                      => { optional => 1, type => SCALAR },
        encoding                   => { optional => 1, type => SCALAR },
        delimiter                  => { optional => 1, type => SCALAR },
        allow_dos_format           => { default => 1, type => BOOLEAN },
        schema                     => { optional => 1, type => HASHREF },
        allow_unknown_headers      => { default => 1, type => SCALAR },
        on_schema_validation_fails => {
            default => 'die',
            callbacks => {
                'validate' => sub { lc($_[0]) eq 'none' || lc($_[0]) eq 'warn' || lc($_[0]) eq 'die' }
            }
        },
        strip_enclosing_quotes     => { default => [], type => SCALAR | ARRAYREF | HASHREF },
        default_value              => { optional => 1, type => SCALAR },
        worksheet_number           => { default => 0, type => SCALAR | ARRAYREF },
        zip_ignore_pattern         => { optional => 1, type => SCALAR },
        zip_pattern                => { optional => 1, type => SCALAR },

        # Private
        _id => { default => 0 },
        _handler => { optional => 1 },
        _closed => { default => 0 }
    };
}
install_accessors(__PACKAGE__, parameters);


# Handlers
my %HANDLER_CLASSES = (
    other_delimited => 'CYC::TabularDataReader::GenericText',
    csv => 'CYC::TabularDataReader::CSV',
    tsv => 'CYC::TabularDataReader::TSV',
);

my %LOADED_HANDLERS;
sub _create_handler {
    my ($style, %args) = @_;
    my $handler_class = $HANDLER_CLASSES{lc($style)};
    unless ($LOADED_HANDLERS{$handler_class}) {
        eval "use $handler_class;";
        $LOADED_HANDLERS{$handler_class} = 1;
    }
    return $handler_class->new(%args);
}


# Constructor
my $_instance_id = 0;
sub new {
    my ($class, %args) = @_;
    %args = validate_with(params => \%args, spec => parameters);
    my $self = bless {}, $class;
    while (my ($k, $v) = each %args) {
        $self->$k($v);
    }
    $self->_id($_instance_id++);

    # unzip the file, if required
    if ($args{file} =~ /\.zip$/i) {
        $args{file} = _handle_zip($args{file}, $args{zip_ignore_pattern}, $args{zip_pattern});
    }

    # 'style' is not supplied, so let's guess
    if (! $self->style) {
        if ((not ref $args{file}) && $args{file} =~ /\.xlsx$/i) {
            $self->style('xlsx');
        } elsif ((not ref $args{file}) && $args{file} =~ /\.xls$/i) {
            $self->style('xls');
        }
        elsif ($args{delimiter}) {
            $args{delimiter} = quotemeta($args{delimiter});
            $self->style('other_delimited');
        }
        else {
            # Guess from the header line
            my $headerline;
            if (not ref $args{file}) {
                my ($filename, $handle) = CYC::TabularDataReader::GenericText::_open_file($args{file}, $args{encoding});
                $headerline = <$handle>;
                if ($filename eq '-') {
                    $args{_headerline} = $headerline;
                }
                else {
                    close $handle;
                }
            }
            else {
                my $handle = $args{file};
                $headerline = <$handle>;
                $args{_headerline} = $headerline;
            }
            $headerline or croak "No header line found file '$args{file}'";

            $self->style((my @a = split(/\t/, $headerline)) >= (my @b = split(/,/, $headerline)) ? 'tsv' : 'csv');
        }
    }

    unless ($HANDLER_CLASSES{$self->style}) {
        croak "Unkown style '" . $self->style . "'";
    }

    # Create the handler
    $self->_handler(_create_handler($self->style, %args));

    # Check schema
    if ($self->schema) {
        eval {
            validate_with(
                params => { map { $_ => 1 } @{$self->header_fields} },
                allow_extra => $self->allow_unknown_headers,
                spec => $self->schema,
            );
        };
        if ($@) {
            croak "File doesn't match the specified schema: $@";
        }
    }

    if ($self->strip_enclosing_quotes) {
        my @fields = ();
        if (ref($self->strip_enclosing_quotes) eq 'ARRAY') {
            @fields = @{$self->strip_enclosing_quotes};
        }
        elsif (ref($self->strip_enclosing_quotes) eq 'HASH') {
            @fields = keys %{$self->stripEnclosingQuotes};
        }
        elsif ($self->strip_enclosing_quotes eq 'all') {
            @fields = @{$self->header_fields};
        }
        else {
            croak "Value [ " . $self->strip_enclosing_quotes . " ] not valid for strip_enclosing_quotes";
        }
        $self->strip_enclosing_quotes(\@fields);
    }

    return $self;
}


# Gets the header fields
sub header_fields {
    my $self = shift;
    return $self->_handler->header_fields();
}


# Return the line count of the tabular data
sub line_count {
    my $self = shift;
    return $self->_handler->line_count();
}


# Gets CODEREF that returns a row on each call
memoize('get_stream', NORMALIZER => sub { shift->_id });
sub get_stream {
    my $self = shift;
    return sub {
        while (1) {
            return undef if $self->_closed;

            my $row_hash_ref = $self->_handler->get_row_hash();

            unless (defined $row_hash_ref) {
                # Perform clean up once EOF is reached
                $self->close;
                return undef;
            }

            # Verify existence of required fields
            eval {
                $row_hash_ref = $self->_verify_with_schema($row_hash_ref);
            };
            if ($@) {
                my $error = $@;
                croak $error unless $error =~ /^Required field/;
                croak $error unless lc($self->on_schema_validation_fails) eq 'none';
            }
            else {
                # Convert empty field to default value
                if (defined $row_hash_ref) {
                    foreach my $field_key (keys %$row_hash_ref) {
                        my $field_value = $row_hash_ref->{$field_key};
                        if ((not defined $field_value) || length($field_value) == 0) {
                            $row_hash_ref->{$field_key} = $self->default_value;
                        }
                    }
                }
                # De-quote some fields
                foreach my $f (@{$self->strip_enclosing_quotes}) {
                    next unless defined( $row_hash_ref->{$f} );
                    $row_hash_ref->{$f} =~ s/^"(.*)"$/$1/;

                    #if field value is empty string after de-quote, set field to undef
                    if ($row_hash_ref->{$f} eq '') {
                        $row_hash_ref->{$f} = undef;
                    }
                }
                return $row_hash_ref;
            }
        }
    }
}


# Reads to the end
sub slurp {
    my $self = shift;
    my $stream = $self->get_stream;
    my @results;
    my $line;
    while ($line = $stream->() and defined $line) {
        push @results, $line;
    }
    return @results;
}


# Close
sub close {
    my $self = shift;
    unless ($self->_closed) {
        $self->_closed(1);
        return $self->_handler->close();
    }
}


# (Private) Verify with schema
sub _verify_with_schema {
    my ($self, $row_hash_ref) = @_;

    if ($self->schema) {
        eval {
            validate_with(
                params => $row_hash_ref,
                allow_extra => $self->allow_unknown_headers,
                spec => $self->schema,
            );
        };
        if ($@) {
            if (lc($self->on_schema_validation_fails) eq 'warn') {
                carp "Required field not found in line: $@";
                return undef;
            }
            croak "Required field not found in line: $@";
        }
    }

    return $row_hash_ref;
}


# (Private) Handle zip files
sub _handle_zip {
    my ($filename, $zip_ignore_pattern, $zip_pattern) = @_;

    my $zipfile = Archive::Zip->new();
    unless ($zipfile->read($filename) == AZ_OK) {
        croak "Could not read zip file '$filename' - is it a valid zip file?";
    }

    # Iterate and count the members, we only want one file
    # so use the patterns supplied by the user to ignore/match
    # the relevant ones
    my @member_files = $zipfile->memberNames();
    my $last_file;
    my $file_count = 0;
    foreach my $member_file (@member_files) {
        next if ((defined $zip_ignore_pattern) && $member_file =~ /$zip_ignore_pattern/);
        next if ((defined $zip_pattern) && $member_file !~ /$zip_pattern/);
        $last_file = $member_file;
        $file_count++;
    }

    # How many members does this zip file have?
    croak "Zip has more than one file that match the zip_pattern" if ($file_count > 1);
    croak "Zip contains no file that match the zip_pattern"       if ($file_count < 1);

    # So we have one file, it's now in $last_file
    # We aren't going to trust the users name, but we will grab their extension, if it's pretty reasonable looking
    my $member_filename = $last_file;
    my ($member_suffix) = $member_filename =~ /(\.\w{3})$/; # 3 character extension only

    croak "The file inside the zip file does not seem to have a valid filename - '$member_filename' has no/invalid file extension"
        unless $member_suffix;

    # Let's extract this file to a temporary file
    my ($fh, $tmp_filename) = tempfile("tdrXXXXXX", SUFFIX => $member_suffix);
    unless ($zipfile->extractMemberWithoutPaths($member_filename, $tmp_filename) == AZ_OK) {
        croak "Archive::Zip failed to extract from $filename";
    }

    return $tmp_filename;
}


1;

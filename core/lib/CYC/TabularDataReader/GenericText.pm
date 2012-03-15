package CYC::TabularDataReader::GenericText;

use strict;
use warnings;

use base 'CYC::TabularDataReader::Base';

use Carp;
use File::BOM qw/open_bom/;
use CYC::TextReader;

sub new {
    my ($class, %args) = @_;
    my $self = CYC::TabularDataReader::Base->new(%args);
    $self = bless $self, $class;

    my ($filename, $handle, $encoding) = _open_file($self->{file}, $self->{encoding});
    $self->{_filename} = $filename;
    $self->{_filehandle} = $handle;
    $self->{_encoding} = $encoding;
    $self->{_cr_warned} = 0;

    my $headerline = (defined $self->{_headerline}) ? $self->{_headerline} : <$handle>;
    $headerline =~ s/\r//sg
        and not $self->{allow_dos_format}
        and croak "DOS carriage returns in header. Do dos2unix on the file first.";
    chomp $headerline;
    $self->{_headerline} = $headerline;

    return $self;
}

sub header_fields {
    my $self = shift;
    return $self->{_headerfields} if $self->{_headerfields};

    $self->{_headerfields} = $self->parse_line($self->{_headerline});
    my @fields = map { s/^\s*(\S.*\S)\s*$/$1/; $_; } @{$self->{_headerfields}};
    $self->{_headerfields} = \@fields;

    return $self->{_headerfields};
}


sub get_row_hash {
    my $self = shift;
    my $filehandle = $self->{_filehandle};

    my $data = '';
    while (defined $data and $data !~ /\S/) { # Skip empty lines
        $data = <$filehandle>;
    }
    return undef unless defined $data;

    my %row_hash;

    # Use ordered hash.
    if ($self->{ordered_hashes}) {
        tie %row_hash, 'Tie::IxHash';
    }

    # De-DOS the line
    $data =~ s/\r//sg and $self->warn_cr();
    chomp $data;

    # Parse line into hash
    my $values = $self->parse_line($data);

    # Convert empty field to undef
    foreach ( @$values ){
        if (defined $_) {
            if ($_ eq '') {
                #for empty string, change to undef as well
                $_ = undef;
            }
        } else {
            #for undefined, set to undef
            $_ = undef;
        }
    }

    @row_hash{ @{ $self->header_fields() } } = @$values;

    return \%row_hash;
}


sub parse_line {
    my ($self, $line) = @_;
    return [ split($self->{delimiter}, $line) ];
}


sub warn_cr {
    my $self = shift;
    return if ((defined $self->{_cr_warned}) && ($self->{_cr_warned} == 1));
    carp "DOS carriage returns in file" unless ( $self->{_encoding} eq 'windows-1252' );
    $self->{_cr_warned} = 1;
}


sub line_count {
    my $self = shift;
    my $filename = $self->{_filename};
    croak "Expected filename ($filename)" if not($filename) or ref $filename;
    croak "No such file $filename" if not -f $filename;
    my $lines = `wc -l $filename 2>&1`;
    $lines =~ /(\d+)/;
    return $1;
}


sub _open_file {
    my ($file, $encoding) = @_;
    my ($filename, $handle);

    if (not ref $file) {
        # Support convention of '-' meaning STDIN
        if ($file eq '-') {
            $filename = $file;
            $handle = \*STDIN;
            binmode(STDIN, ':utf8');
        }
        else {
            $filename = $file;

            # if an encoding is specified, 'try' to open in that encoding
            if ($encoding) {
                ($handle, $encoding) = eval {
                    _open_bom($file, ':encoding(' . $encoding . ')')
                };
            }
            else {
                $encoding = 'auto';
                $handle = open_text($file);
            }
            croak $@ if $@;
            croak "Error opening $file: $!" unless $handle;
        }
    }
    else {
        # If your passing in a handle, open in proper encoding and convert to utf8 your self
        $handle = $file;
    }
    return ($filename, $handle, $encoding);
}


sub _open_bom {
    my ($file, $encoding) = @_;
    if ($File::BOM::VERSION gt '0.09') {
        $encoding = open_bom(my $handle, $file, $encoding);
        return ($handle, $encoding);
    }
    return open_bom($file, $encoding);
}


sub close {
    my $self = shift;
    close $self->{_filehandle};
}

1;

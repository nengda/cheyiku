package CYC::TextReader;

=head1 SYNOPSIS

  use CYC::TextReader;

  my $fh = open_text($file_path);
  while (my $line = <$fh>) {
      ...
  }
  close($fh);

=head1 METHODS

=head2 open_text

Open a text file; also supports the "command |" syntax.

=cut

use strict;
use warnings;

use Carp;
use Encode;
use Exporter;
use Fcntl;
use File::Temp qw/tempdir/;

our @ISA = qw/Exporter/;
our @EXPORT = qw/open_text/;

sub open_text {
    my $file = shift;
    my $t = pack('U', 0x8A66);
    my $layer = '<:via(CYC::TextReader)' . ((Encode::is_utf8($t)) ? ':utf8' : '');
    open(my $fh, $layer, $file) || croak "Failed opening '$file'";
    return $fh;
}

sub PUSHED {
    my ($pkg, $mode, $fh) = @_;
    return bless {
        i => 0,
        b => [],
        l => 0,
        p => 0,
        e => 0,
        c => 0,
        s => \&_get_next_ascii_char
    }, $pkg;
}

sub POPPED {
}

sub UTF8 {
    return 1;
}

sub OPEN {
    my ($self, $path, $mode, $fh) = @_;

    croak "Missing parameter 'path'" unless (defined $path);
    if ($path =~ /^\s*(.+)\|$/) {
        my $command = $1;
        my @command_tokens = split(/\s/, $command);
        my $executable = $command_tokens[0];
        if ($executable =~ /\//) {
            croak "Unable to execute '$command' (1)" unless -x $executable;
        }
        else {
            my $found = 0;
            foreach my $bin_path (split(/:/, $ENV{PATH})) {
                if (-x $bin_path . "/$executable") {
                    $found = 1;
                    last;
                }
            }
            croak "Unable to execute '$command' (2)" unless $found;
        }

        my $pipe_path = tempdir(CLEANUP => 1) . "/sast_dts_text_file_reader.fifo";
        system("mkfifo $pipe_path");
        croak "Unable to create temporary pipe '$pipe_path'" unless -e $pipe_path;

        $self->{c} = fork;
        unless ($self->{c}) {
            { exec($command . " > $pipe_path"); };
            warn "Unable to execute '$command' (3)\n";
            eval("use POSIX; POSIX::_exit(0);");
            exit(0);
        }
        $path = $pipe_path;
    }
    else {
        croak "'$path' does not exist" unless -e $path;
    }

    sysopen($fh, $path, O_RDONLY);
    croak "Unable to open '$path'" unless (defined $fh);

    $self->{fh} = $fh;
    return 1;
}

sub BINMODE {
    return 0;
}

sub FILENO {
    my $self = shift;
    return fileno($self->{fh});
}

sub FILL {
    my $self = shift;
    unless ($self->{i}) {
        $self->_read_block;
        my $b = $self->{b};
        if ($self->{l} >= 3 && $b->[0] == 0xEF && $b->[1] == 0xBB && $b->[2] == 0xBF) {
            $self->{p} = 3;
            $self->{s} = \&_get_next_utf8_char;
        }
        elsif ($self->{l} >= 2 && $b->[0] == 0xFF && $b->[1] == 0xFE) {
            $self->{p} = 2;
            $self->{s} = \&_get_next_utf16le_char;
        }
        elsif ($self->{l} >= 2 && $b->[0] == 0xFE && $b->[1] == 0xFF) {
            $self->{p} = 2;
            $self->{s} = \&_get_next_utf16be_char;
        }
        $self->{i} = 1;
    }
    return $self->{s}->($self, $self->{fh});
}

sub WRITE {
    my $self = shift;
    my $pkg = ref($self);
    croak "Writing via '$pkg' is not supported";
}

sub FLUSH {
    return 0;
}

sub CLOSE {
    my $self = shift;
    close($self->{fh});
    if ($self->{c}) {
        kill(9, $self->{c});
        waitpid($self->{c}, 0);
    }
}

sub EOF {
    my $self = shift;
    return $self->{e};
}

sub _read_block {
    my $self = shift;
    unless ($self->{e}) {
        my $fh = $self->{fh};
        my $b = '';
        my $l = sysread($fh, $b, 1024);
        if (defined $l) {
            if ($l > 0) {
                my @bytes = unpack("C*", $b);
                $self->{b} = \@bytes;
                $self->{l} = $l;
                $self->{p} = 0;
            }
            else {
                $self->{b} = undef;
                $self->{l} = 0;
                $self->{p} = 0;
                $self->{e} = 1;
                $self->CLOSE;
            }
        }
        else {
            $self->{b} = undef;
            $self->{l} = 0;
            $self->{p} = 0;
            $self->{e} = 1;
            $self->CLOSE;
            croak "Error reading file handle: $!";
        }
    }
}

sub _get_next_byte {
    my $self = shift;
    unless ($self->{e}) {
        if ($self->{p} >= $self->{l}) {
            $self->_read_block;
        }
        if ($self->{p} < $self->{l}) {
            my $byte = $self->{b}->[$self->{p}];
            $self->{p} += 1;
            return $byte;
        }
    }
    return -1;
}

sub _get_next_ascii_char {
    my $self = shift;

    my $b1 = $self->_get_next_byte;
    return undef if ($b1 == -1);

    if ($b1 < 0x80) {
        return pack('U', $b1);
    }
    elsif (($b1 & 0xE0) == 0xC0) {
        my $b2 = $self->_get_next_byte;
        if ($b2 != -1) {
            if (($b2 & 0xC0) == 0x80) {
                my $v = (($b1 & 0x1F) << 6) | ($b2 & 0x3F);
                if ($v < 0x80) {
                    warn "Invalid code point '$v'\n";
                    return pack('U*', $b1, $b2);
                }
                else {
                    return pack('U', $v);
                }
            }
            else {
                return pack('U*', $b1, $b2);
            }
        }
        else {
            return pack('U', $b1);
        }
    }
    elsif (($b1 & 0xF0) == 0xE0) {
        my $b2 = $self->_get_next_byte;
        if ($b2 != -1) {
            if (($b2 & 0xC0) == 0x80) {
                my $b3 = $self->_get_next_byte;
                if ($b3 != -1) {
                    if (($b3 & 0xC0) == 0x80) {
                        my $v = (($b1 & 0x0F) << 12) | (($b2 & 0x3F) << 6) | ($b3 & 0x3F);
                        if ($v < 0x800) {
                            warn "Invalid code point '$v'\n";
                            return pack('U*', $b1, $b2, $b3);
                        }
                        else {
                            return pack('U', $v);
                        }
                    }
                    else {
                        return pack('U*', $b1, $b2, $b3);
                    }
                }
                else {
                    return pack('U*', $b1, $b2);
                }
            }
            else {
                return pack('U*', $b1, $b2);
            }
        }
        else {
            return pack('U', $b1);
        }
    }
    elsif (($b1 & 0xF8) == 0xF0) {
        my $b2 = $self->_get_next_byte;
        if ($b2 != -1) {
            if (($b2 & 0xC0) == 0x80) {
                my $b3 = $self->_get_next_byte;
                if ($b3 != -1) {
                    if (($b3 & 0xC0) == 0x80) {
                        my $b4 = $self->_get_next_byte;
                        if ($b4 != -1) {
                            if (($b4 & 0xC0) == 0x80) {
                                my $v = (($b1 & 0x07) << 18) | (($b2 & 0x3F) << 12) | (($b3 & 0x3F) << 6) | ($b4 & 0x3F);
                                if ($v < 0x10000) {
                                    warn "Invalid code point '$v'\n";
                                    return pack('U*', $b1, $b2, $b3, $b4);
                                }
                                else {
                                    return pack('U', $v);
                                }
                            }
                            else {
                                return pack('U*', $b1, $b2, $b3, $b4);
                            }
                        }
                        else {
                            return pack('U*', $b1, $b2, $b3);
                        }
                    }
                    else {
                        return pack('U*', $b1, $b2, $b3);
                    }
                }
                else {
                    return pack('U*', $b1, $b2);
                }
            }
            else {
                return pack('U*', $b1, $b2);
            }
        }
        else {
            return pack('U', $b1);
        }
    }
    return pack('U', $b1);
}

sub _get_next_utf8_char {
    my $self = shift;

    my $b1 = $self->_get_next_byte;
    return undef if ($b1 == -1);

    if ($b1 < 0x80) {
        return pack('U', $b1);
    }
    elsif (($b1 & 0xE0) == 0xC0) {
        my $b2 = $self->_get_next_byte;
        if ($b2 == -1) {
            warn "Premature termination of UTF-8 encoded stream\n";
            return undef;
        }
        return pack('U', (($b1 & 0x1F) << 6) | ($b2 & 0x3F));
    }
    elsif (($b1 & 0xF0) == 0xE0) {
        my $b2 = $self->_get_next_byte;
        my $b3 = $self->_get_next_byte;
        if ($b2 == -1 || $b3 == -1) {
            warn "Premature termination of UTF-8 encoded stream\n";
            return undef;
        }
        return pack('U', (($b1 & 0x0F) << 12) | (($b2 & 0x3F) << 6) | ($b3 & 0x3F));
    }
    elsif (($b1 & 0xF8) == 0xF0) {
        my $b2 = $self->_get_next_byte;
        my $b3 = $self->_get_next_byte;
        my $b4 = $self->_get_next_byte;
        if ($b2 == -1 || $b3 == -1 || $b4 == -1) {
            warn "Premature termination of UTF-8 encoded stream\n";
            return undef;
        }
        return pack('U', (($b1 & 0x07) << 18) | (($b2 & 0x3F) << 12) | (($b3 & 0x3F) << 6) | ($b4 & 0x3F));
    }
}

sub _get_next_utf16le_char {
    my $self = shift;
    my $b1 = $self->_get_next_byte;
    my $b2 = $self->_get_next_byte;
    if ($b1 == -1) {
        return undef;
    }
    if ($b2 == -1) {
        warn "Odd number of bytes in UTF-16LE encoded stream\n";
        return undef;
    }
    return pack('U', ($b2 << 8) | $b1);
}

sub _get_next_utf16be_char {
    my $self = shift;
    my $b1 = $self->_get_next_byte;
    my $b2 = $self->_get_next_byte;
    if ($b1 == -1) {
        return undef;
    }
    if ($b2 == -1) {
        warn "Odd number of bytes in UTF-16BE encoded stream\n";
        return undef;
    }
    return pack('U', ($b1 << 8) | $b2);
}

1;

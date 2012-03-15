package CYC::Web::HandlerBase;

=head1 NAME

CYC::Web::HandlerBase - Base class for all web service handlers

=head1 IMPLEMEMTING A WEB SERVICE HANDLER

Implementing a web service handler is similar to writing a PERL module. However, there's no need to give the handler a module name and to add the '1;' statement at the end.

The web services framework will take the code of the handler, generate a temporary class name for it, compile the code, and instantiate the handler.

A handler can inherit from another handler but all handlers are inherited from this HandlerBase class at the bottom level without any exception.

A typical handler will override three methods: 'args', 'return_type', and 'process_request'. Please see the documentation on individual method for detailed descriptions.

=head1 METHODS

=cut

use strict;
use warnings;

use Carp;
use Cwd;
use File::Basename;
use File::Spec;
#use SAST::DTS::MIMETypes;
use CYC::Web::Config;
use CYC::Web::HandlerFault;
use Scalar::Util qw/blessed/;

use Log::Log4perl;
my $_logger = Log::Log4perl::get_logger(__PACKAGE__);

my $_next_class_id = 0;
my %_handler_class_names;
my %_handler_instances;
my $_cache_compiled_code = CYC::Web::Config->get('CacheCompiledCode');

=head2 get_handler

Gets the handler of the specified path.

=cut

sub get_handler {
    my ($pkg, $path, $r) = @_;

    my $self = undef;
    if (blessed($pkg)) {
        $self = $pkg;
        $pkg = ref($pkg);
        $r = $self->r;
    }

    $_logger->debug("Start to construct hanlder");

    my $base_path = $r->document_root;
    if ($path !~ /^\//) {
        unless (defined $self) {
            die CYC::Web::HandlerFault->new(
                status => 'NotFound',
                message => 'The request URL is invalid.',
                displayable => 1
            );
        }

        my ($volume, $dir) = File::Spec->splitpath($self->handler_path);
        $base_path = $dir;
    }

    my $filename = Cwd::realpath($base_path . '/' . $path);
    unless (-e $filename) {
        die CYC::Web::HandlerFault->new(
            status => 'NotFound',
            message => 'The request URL is invalid.',
            displayable => 1
        );
    }

    my $handler = $_handler_instances{$filename};
    unless (defined $handler) {
        my $base_class = __PACKAGE__;
        my $class_name = 'WS' . $filename;
        $class_name =~ s/[^A-Za-z0-9\/]//g;
        $class_name =~ s/\/+/\//g;
        $class_name =~ s/\/+$//g;
        $class_name =~ s/\//::/g;
        $class_name .= $_next_class_id++;

        open(FH, $filename);
        my @lines = <FH>;
        if (scalar(@lines) > 0) {
            foreach my $line (@lines) {
                chomp($line);
                if ($line =~ /^#inherit\s+(\S+)/) {
                    my $inherit_path = $1;
                    $inherit_path =~ s/^['"](.*?)['"]$/$1/;
                    if ($inherit_path =~ /^\//) {
                        $inherit_path = $r->document_root . $inherit_path;
                    }
                    else {
                        my ($volume, $dir) = File::Spec->splitpath($filename);
                        $inherit_path = $dir . '/' . $inherit_path;
                    }
                    $inherit_path = Cwd::realpath($inherit_path);
                    my $base_handler = $pkg->get_handler('/' . File::Spec->abs2rel($inherit_path, $r->document_root), $r);
                    $base_class = ref($base_handler);
                }
            }
        }
        close(FH);

        eval(join("\n", "package $class_name;\nuse base '$base_class';", @lines, "1;\n"));
        if (my $e = $@) { die $e; }

        $handler = eval("$class_name->new(\$filename)");
        if (my $e = $@) { die $e; }

        if ($_cache_compiled_code) {
            $_handler_class_names{$filename} = $class_name;
            $_handler_instances{$filename} = $handler;
        }
    }

    if (defined $self) {
        $handler->r($self->r);
        $handler->user($self->user);
        $handler->generate_response(1);
    }

    return $handler;
}

=head2 new

Creates an instance of the web service handler.

To override the constructor:

    sub new {
        my ($pkg, $handler_path, %args) = @_;
        my $self = $pkg->SUPER::new($handler_path);

        # Perform additional initialization here

        return $self;
    }

=cut

sub new {
    my ($pkg, $handler_path) = @_;
    my $self = bless {
        __api_base__ => {
            r => undef,
            user => undef,
            generate_response => 0,
            handler_path => $handler_path
        }
    }, $pkg;
    return $self;
}

=head2 handler_path

=cut

sub handler_path {
    my $self = shift;
    return $self->{__api_base__}->{handler_path};
}

=head2 args

Parameters to accept and to validate. Please see Params::Validate for detailed documentation on the syntax.

=cut

sub args {
    return undef;
}

=head2 admin_only

Flag to indicate whether this handler is allowed for admin only

=cut

sub admin_only {
    return 0;
}

=head2 r

Gets the Apache request instance.

=cut

sub r {
    my $self = shift;
    if (scalar(@_) == 0) {
        return $self->{__api_base__}->{r};
    }
    else {
        $self->{__api_base__}->{r} = shift;
    }
    return $self;
}

=head2 user

Gets the current user info.

=cut

sub user {
    my $self = shift;
    if (scalar(@_) == 0) {
        return $self->{__api_base__}->{user};
    }
    else {
        $self->{__api_base__}->{user} = shift;
    }
    return $self;
}

=head2 generate_response

Tells the framework to generate response or not.

=cut

sub generate_response {
    my $self = shift;
    if (scalar(@_) == 0) {
        return $self->{__api_base__}->{generate_response};
    }
    else {
        $self->{__api_base__}->{generate_response} = shift;
    }
    return $self;
}

=head2 process_request

Processes an incoming request. Must be implemented in the handler.

=cut

sub process_request {
    die "Not implemented";
}

=head2 send_file

Sends a file in the file system to the client as an attachment. This will turn off generate_response automatically.

=cut

=head
sub send_file {
    my ($self, $file_path, $display_name) = @_;

    confess "File '$file_path' does not exist" unless (-e $file_path);

    $display_name = basename($file_path) unless (defined $display_name);

    $self->generate_response(0);

    my $r = $self->r;
    $r->content_type(CYC::Web::MIMETypes->get_type_by_file_name($display_name));
    $r->header_out('Content-Length' => -s $file_path);
    $r->header_out('Content-Disposition' => 'attachment; filename=' . $display_name);
    $r->header_out("Expires" => "Sat, 26 Jul 1997 05:00:00 GMT");
    $r->header_out("Cache-Control" => "private, max-age=0, must-revalidate");
    $r->send_http_header;

    open(my $fh, $file_path);
    $r->send_fd($fh);
    close($fh);
}
=cut

=head2 error

Dies with error message. The second parameter indicates if the error message should be displayed to the user.

If the error message should not be displayed to the user, the framework will generate a reference code for the error and save the error message in the error log. The framework will then replaces the error message with the default error message before sending it to the client.

=cut

sub error {
    my ($self, $message, $displayable, $status) = @_;
    die CYC::Web::HandlerFault->new(status => $status, message => $message, displayable => $displayable);
}

1;

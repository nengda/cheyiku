package CYC::Web::RequestHandler;

use strict;
use warnings;

use Apache::Constants qw/:common :http/;
use Apache::Request;
use Carp;
use Data::Dumper;
use File::Basename qw/basename/;
use File::Spec;
use Params::Validate qw/validate_with/;
use CYC::Web::HandlerBase;
use CYC::Web::HandlerFault;
use CYC::Web::Serializer;
use Scalar::Util qw/blessed/;
use Log::Log4perl;

my $_logger = Log::Log4perl::get_logger(__PACKAGE__);

sub process_request {
    my $r = shift;
    my $apr = undef;
    my $args = undef;
    my $generate_response = 0;
    my $response_text = '';
    
    $_logger->debug('Start to process request');
    eval {
        my $handler = CYC::Web::HandlerBase->get_handler('/' . File::Spec->abs2rel($r->filename, $r->document_root), $r);
        $_logger->debug('Got the handler');

        $handler->generate_response(1);
        $handler->r($r);
        $handler->user($r->pnotes()->{current_user});

        # Parse parameters
        $apr = Apache::Request->instance($r);
        unless ($apr->parse == OK) {
            die $apr->notes('error-notes') . "\n";
        }

        $args = { $r->args };
        my @post_params = $apr->param;
        foreach my $p (@post_params) {
            $args->{$p} = $apr->param($p);
        }

        # Validate if admin only 
        if ($handler->admin_only && defined $handler->user && not $handler->user->is_admin) {
            die CYC::Web::HandlerFault->new(
                message => "Not Authorized",
                displayable => 1
            );
        }

        # Validate parameters
        my $args_spec = $handler->args;
        if (defined $args_spec) {
            $args = {
                validate_with(
                    params => $args,
                    spec => $args_spec,
                    allow_extra => 1,
                    called => basename($r->filename),
                    on_fail => sub {
                        my $e = shift;
                        die CYC::Web::HandlerFault->new(
                            message => $e,
                            displayable => 1
                        );
                    }
                )
            };
        }

        # Execute
        my $response = $handler->process_request($r, $args);

        # Generate response
        $generate_response = $handler->generate_response;
        if ($generate_response) {
            $response_text = CYC::Web::Serializer->get_instance()->serialize(status => 'OK', data => $response);
            #"<cyc><status>OK</status><data>$response</data></cyc>";
        }
    };
    if (my $e = $@) {
        if (ref($e) ne 'CYC::Web::HandlerFault') {
            if (blessed($e)) {
                local $Data::Dumper::Sortkeys = 1;
                $e = Dumper($e);
            }
            $e = CYC::Web::HandlerFault->new(message => $e, displayable => 0);
        }

        my $display_message = $e->message;

        unless ($e->displayable) {
            # Sends undisplayable error messages apache log
            $_logger->warn($e->message);
            #$reference_code = CYC::Web::Logger->log_web_service_error(
            #    $r->filename,
            #    $args,
            #    ((defined $apr) && (defined $apr->upload)) ? $apr->upload->filename : undef,
            #    $e->message
            #);
            $display_message = 'An internal error has occurred.';
        }

        $r->status(HTTP_OK);
        $r->header_out("Expires" => "Sat, 26 Jul 1997 05:00:00 GMT");
        $r->header_out("Cache-Control" => "private, max-age=0, must-revalidate");
        $r->content_type('text/xml');
        $r->send_http_header;

        my $status = $e->status;
        $r->print(CYC::Web::Serializer->get_instance()->serialize(status => $status, data => $display_message));
        #$r->print("<cyc><status>$status</status><data>$display_message</data></cyc>");
        return OK;
    }

    if ($generate_response) {
        $r->status(HTTP_OK) unless (defined $r->status);
        $r->header_out("Expires" => "Sat, 26 Jul 1997 05:00:00 GMT");
        $r->header_out("Cache-Control" => "private, max-age=0, must-revalidate");
        $r->content_type('text/xml');
        $r->send_http_header;
        $r->print($response_text);
    }

    return OK;
}

1;

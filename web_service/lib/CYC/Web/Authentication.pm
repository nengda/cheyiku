package CYC::Web::Authentication;

use strict;
use warnings;

use Log::Log4perl;
my $_logger = Log::Log4perl::get_logger(__PACKAGE__);

use Apache::Constants qw/:response/;
use Apache::Cookie;
use Digest::SHA1 qw/sha1_hex/;
use Carp;
use Data::Dumper;
use CYC::Web::Model::Session;
use CYC::Web::Model::User;
use CYC::Web::Serializer;

my $_config = undef;

BEGIN {
    use CYC::TabularDataReader;

    my $config_path = "/home/y/conf/cyc_web/auth";
    warn "Processing authentication config directory: $config_path\n";

    opendir(CD, $config_path);
    my @files = sort(readdir(CD));
    closedir(CD);

    $_config = {
        exact_match => { '/error/auth' => 'Skip' },
        regex_match => []
    };

    foreach my $file (@files) {
        next if ($file eq '.' || $file eq '..');
        my $full_path = $config_path . '/' . $file;
        warn " Processing authentication config file: $full_path\n";
        my $reader = CYC::TabularDataReader->new(file => $full_path);
        while (my $row = $reader->()) {
            if ($row->{MatchType} eq 'Exact') {
                $_config->{exact_match}->{$row->{URI}} = $row->{Action};
            }
            elsif ($row->{MatchType} eq 'Regex') {
                push @{$_config->{regex_match}}, {
                    uri => $row->{URI},
                    action => $row->{Action}
                };
            }
            else {
                warn "Unknown match type '" . $row->{MatchType} . "'";
            }
        }
        $reader->close;
    }
}

sub login {
    my ($pkg, $e, $p, $ip) = @_;

    my $email = lc($e);
    $_logger->debug("Authenticating user '$email', password '$p'");

    # Authorize user through user module
    my $user;
    eval {
        $user = CYC::Web::Model::User->new(email => $email)->load;
    };
    if ($@ || (not defined $user) || $user->password ne sha1_hex($p) || $user->is_deleted) {
        die "Login failed for '$email'\n ";
    }

    # create a new session
    my $session = CYC::Web::Model::Session->create_session(
        user_email => $email,
        ip => $ip,
    );

    return $session;
}

sub validate_session($$) {
    my ($pkg, $r) = @_;

    my $uri = $r->uri;
    my $action = $pkg->_get_action($uri);
    $_logger->debug("Validating session: uri = $uri; action = $action");
    return DECLINED if ($action eq 'Skip');

    my %cookies = Apache::Cookie->fetch;
    if (defined $cookies{cyc_session}) {
        $_logger->debug("- session found");
        my $session = undef;
        eval {
            $session = CYC::Web::Model::Session->get_session_by_cookie_value($cookies{cyc_session}->value, $r->connection->remote_ip);
        };
        if (my $e = $@) {
            $_logger->debug("- WARNING: $e");
        }
        if (defined $session) {
            $_logger->debug("- Session is valid");
            eval {
                my $user = $session->user;
                $r->pnotes()->{current_user} = $user;
            };
            if (my $e = $@) {
                $_logger->debug("- WARNING: $e");
            }
            else {
                return DECLINED;
            }
        }
        $_logger->debug("- Session is invalid");
    }

    if ($action eq 'Redirect') {
        $r->status(REDIRECT);
        $r->header_out("Location", "/login/?redirect=$uri");
        $r->send_http_header;
        return REDIRECT;
    }

    if ($action eq 'JSON') {
        $r->content_type('text/plain');
        $r->send_http_header;
        $r->print(encode_json({ status => 'AuthenticationFailed' }));
        return DONE;
    }

    elsif ($action eq 'XML') {
        $r->content_type('text/xml');
        $r->send_http_header;
        $r->print(CYC::Web::Serializer->get_instance()->serialize(status => 'Error', data => 'AuthenticationFailed'));
        return DONE;
    }

    $r->status(REDIRECT);
    $r->header_out("Location", "/login/");
    $r->send_http_header;
    return REDIRECT;
}

my %_get_action_cache;
sub _get_action {
    my ($pkg, $uri) = @_;

    my $action = $_get_action_cache{$uri};
    return $action if (defined $action);

    $action = $_config->{exact_match}->{$uri};
    if (defined $action) {
        $_get_action_cache{$uri} = $action;
        return $action;
    }

    foreach my $match (@{$_config->{regex_match}}) {
        eval {
            my $regex = $match->{uri};
            if ($uri =~ /$regex/) {
                $action = $match->{action};
            }
        };
        if (my $e = $@) {
            warn $e;
        }
        if (defined $action) {
            $_get_action_cache{$uri} = $action;
            return $action;
        }
    }

    $_get_action_cache{$uri} = 'Redirect';
    return 'Redirect';
}

1;

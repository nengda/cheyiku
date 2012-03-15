package CYC::Web::Model::Session;

use strict;
use warnings;

use Log::Log4perl;
my $_logger = Log::Log4perl::get_logger(__PACKAGE__);

use CGI::Cookie;
use Data::Dumper;
use Digest::SHA1 qw/sha1_hex/;
use DateTime;
use CYC::Web::Config;

use base 'CYC::Database::Object';

my @_salt_chars = ('a'..'z', 'A'..'Z', '0'..'9');

sub create_session {
    my ($pkg, %args) = @_;

    unless ($args{salt}) {
        my $salt = '';
        my $salt_chars = scalar(@_salt_chars);
        for (my $i = 0; $i < 20; $i++) {
            $salt .= $_salt_chars[int(rand($salt_chars))];
        }
        $args{salt} = $salt;
    }

    unless ($args{creation_time}) {
        $args{create_timestamp} = DateTime->now();
    }

    # remove previous sessions
    $pkg->delete_objects(query => [user_email => {'=' => $args{user_email}}]);

    $args{checksum} = sha1_hex(join("\n", $args{user_email}, $args{ip}, $args{create_timestamp}->epoch(), $args{salt}));

    return $pkg->new(%args)->save;
}

sub get_session_by_cookie_value {
    my ($pkg, $cookie_value, $remote_ip) = @_;
    if ($cookie_value =~ /^s=(.*?);u=(.*?);c=([0-9a-f]{40})$/) {
        my $session_id = $1;
        my $user_email = $2;
        my $checksum = $3;
        my $session = undef;
        eval {
            $session = $pkg->new(id => $session_id)->load;
        };
        if (my $e = $@) {
            $_logger->debug($e);
        }
        unless (defined $session) {
            $_logger->debug("Session not found");
            return undef;
        }
        unless ($session->user_email eq $user_email) {
            $_logger->debug("User email mismatch: " . $session->user_email. " / $user_email");
            return undef;
        }
        unless ($session->checksum eq $checksum) {
            $_logger->debug("Checksum mismatch");
            return undef;
        }
        unless ($session->ip eq $remote_ip || $remote_ip eq '127.0.0.1') {
            $_logger->debug("IP mismatch");
            return undef;
        }
        unless ((DateTime->now()->epoch() - $session->create_timestamp->epoch()) < CYC::Web::Config->get('SessionExpireTime')) {
            $_logger->debug("Session expired");
            $session->delete();
            return undef;
        }

        # update session time
        $session->create_timestamp(DateTime->now());
        $session->save();
        return $session;
    }

    $_logger->debug("Invalid cookie format: $cookie_value");
    return undef;
}

sub cookie {
    my $self = shift;
    return CGI::Cookie->new(-name => 'cyc_session', -value => $self->cookie_value);
}

sub cookie_value {
    my $self = shift;
    my $session_id = $self->id;
    my $user_email= $self->user_email;
    my $checksum = $self->checksum;
    return "s=$session_id;u=$user_email;c=$checksum";
}

sub TABLE {
    return 'cyc_session';
}

sub REFERENCES {
    return {
        'user' => { field => 'user_email', class => 'CYC::Web::Model::User' }
    };
}

1;

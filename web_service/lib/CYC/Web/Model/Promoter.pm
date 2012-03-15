package CYC::Web::Model::Promoter;

use strict;
use warnings;

use base 'CYC::Database::Object';

sub TABLE {
    return 'cyc_promoter';
}

sub REFERENCES {
    return {
        'user' => { field => 'created_by', class => 'CYC::Web::Model::User' }
    };
}

1;

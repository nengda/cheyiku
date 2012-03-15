package CYC::Web::Model::Client;

use strict;
use warnings;

use base 'CYC::Database::Object';

sub TABLE {
    return 'cyc_client';
}

sub REFERENCES {
    return {
        'promoter' => { field => 'promoter_id', class => 'CYC::Web::Model::Promoter' },
        'district' => { field => 'district_id', class => 'CYC::Web::Model::District' },
        'car' => { field => 'car_id', class => 'CYC::Web::Model::Car' },
        'profession' => { field => 'profession_id', class => 'CYC::Web::Model::Profession' },
    };
}

1;

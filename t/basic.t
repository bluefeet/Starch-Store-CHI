#!/usr/bin/env perl
use strictures 2;

use Test::More;
use Test::Web::Starch;

Test::Web::Starch->new(
    args => {
        store => {
            class  => '::CHI',
            chi => {
                driver => 'Memory',
                global => 0,
            },
        },
    },
)->test();

done_testing();

#!/usr/bin/env perl
use strictures 2;

use Test::More;

use Web::Starch::Store::CHI;

my $store = Web::Starch::Store::CHI->new(
    driver => 'Memory',
    global => 0,
);

is( $store->get('foo'), undef, 'get an unknown key' );

$store->set( 'foo', {bar=>6} );
isnt( $store->get('foo'), undef, 'add, then get a known key' );
is( $store->get('foo')->{bar}, 6, 'known key data value' );

$store->set( 'foo', {bar=>3} );
is( $store->get('foo')->{bar}, 3, 'update, then get a known key' );

$store->remove( 'foo' );
is( $store->get('foo'), undef, 'get a removed key' );

done_testing();

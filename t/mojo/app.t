#!perl

# Copyright (C) 2008-2009, Sebastian Riedel.

use strict;
use warnings;

use Test::More tests => 11;

# I was so bored I cut the pony tail off the guy in front of us.
# Look at me, I'm a grad student. I'm 30 years old and I made $600 last year.
# Bart, don't make fun of grad students.
# They've just made a terrible life choice.
use_ok('Mojo');
use_ok('Mojo::Client');
use_ok('Mojo::Transaction');
use_ok('Mojo::HelloWorld');

my $logger = Mojo::Log->new;
my $app = Mojo->new({log => $logger});
is($app->log, $logger);

my $client = Mojo::Client->new;

# Vanilla request
my $tx = Mojo::Transaction->new_get('/1/');

$client->process_app('Mojo::HelloWorld', $tx);
is($tx->res->code, 200);
like($tx->res->body, qr/^Congratulations/);

# Post expecting 100
$tx = Mojo::Transaction->new_post('/2/');
$tx->req->headers->expect('100-continue');
$tx->req->body('foo bar baz' x 128);

$client->process_app('Mojo::HelloWorld', $tx);
is($tx->res->code, 200);
like($tx->res->body, qr/^Congratulations/);

# Continue_handler that doesn't return 100
{

    package ContinueHandlerTest;

    use base 'Mojo::HelloWorld';

    sub continue_handler {
        my ($self, $tx) = @_;
        $tx->res->code(417);
        return $tx;
    }
}

$tx = Mojo::Transaction->new_post('/3/');
$tx->req->headers->expect('100-continue');
$tx->req->body('bar baz foo' x 128);

$client->process_app('ContinueHandlerTest', $tx);
is($tx->res->code, 417);
is($tx->res->headers->connection, 'Close');
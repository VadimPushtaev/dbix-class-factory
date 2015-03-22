#!/usr/bin/env perl

use strict;
use warnings FATAL => 'all';
use inc::Module::Install;

test_requires 'DBIx::Class' => 0;
test_requires 'SQL::Translator' => 0;
test_requires 'Test::More' => 0;
test_requires 'Test::Deep' => 0;

all_from 'lib/DBIx/Class/Factory.pm';

WriteAll;

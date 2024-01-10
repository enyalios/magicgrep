#!/usr/bin/perl

use warnings;
use strict;
use CGI::Carp 'fatalsToBrowser';
use FindBin '$Bin';
use lib "$Bin/../lib";
use Magic;

print "Content-Type: text/html\n\n";
print "$_\n" for @{get_db_handle()->selectcol_arrayref("SELECT name FROM cards")};

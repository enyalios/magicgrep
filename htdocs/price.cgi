#!/usr/bin/perl

use warnings;
use strict;
use CGI::Carp 'fatalsToBrowser';
use CGI 'param';
use FindBin '$Bin';
use lib "$Bin/../lib";
use Magic;

print "Content-Type: text/html\n\n";
my $card = param("q") // "";
my $dbh = get_db_handle();
my @array = $dbh->selectrow_array("SELECT name, price FROM cards WHERE name LIKE ?", {}, $card);
$dbh->disconnect;
printf("%s|%s\n", $array[0], $array[1]) if @array;

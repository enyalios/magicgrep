#!/usr/bin/perl

use strict;
use warnings;
use CGI::Carp 'fatalsToBrowser';
use FindBin '$Bin';
use lib "$Bin/secure/lib";
use Magic;
use URI::Escape;

my $header = generate_header('Lists');
my $staples_file = "/home/enyalios/magic/staples.txt";
my %staples;
my $tag;

open my $fh, "<", $staples_file or die;
while(<$fh>) {
    chomp;
    next unless length $_;
    
    if(/^# (.*)$/) {
        $tag = $1;
    } else {
        push @{$staples{$tag}}, $_;
    }
}
$staples{"Dual Lands"} = "";

print <<EOF;
Content-Type: text/html

<!DOCTYPE html>
<html>
    <head>
        <link rel="stylesheet" type="text/css" href="mystyle.css">
    </head>
    <body>
        <div class="main">
        $header
        <ul style="columns:300px auto;">
EOF
for(sort keys %staples) {
    if($_ eq "Dual Lands") {
        print "<li><a href='lands.html'>Dual Lands</a><br /></li>\n";
        next;
    }
    my $link = join "|", map { uri_escape($_) } sort @{$staples{$_}};
    $link =~ s/'/%27/g;
    $link =~ s/%20%2F%2F%20/\|/g; # change ' // ' to '|'
    my $count = @{$staples{$_}};
    print "<li><a href='index.cgi?q=\"^name: *($link)\$\"'>$_</a>\n";
    #print "$count cards\n";
    print "<br /></li>\n";
}
print "</ul></div></body></html>\n";

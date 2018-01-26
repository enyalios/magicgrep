#!/usr/bin/perl

use strict;
use warnings;
use CGI::Carp 'fatalsToBrowser';
use CGI 'param';
use URI::Escape;
use FindBin '$Bin';
use lib "$Bin/secure/lib";
use Magic;

my $deck = param("deck") // "";
if(length $deck) {
    # do work
    my @cards = split /\r?\n/, $deck;
    for(@cards) {
        s/#.*//; # remove comments
        s/^\s*\d+\s?x?\s+//; # remove number before card names with optional 'x'
        s/\*CMDR\*//; # remove the string *CMDR* which marks commanders
        s/^\s+//; # remove leading whitespace
        s/\s+$//; # remove trailing whitespace 
        s/ \/\/ /|/; # fix split card names
        s/"/./g; # "escape" double quotes
        $_ = uri_escape($_);
    }
    @cards = grep { !/^$/ } @cards; # skip blank lines
    #print "Content-type: text/html\n\n";
    #print "&lt;$_&gt;<br />\n" for @cards;

    print "Status: 307\n";
    my $url = "index.cgi";
    $url = "stats.cgi" if defined param('stats');
    print "Location: $url?q=\"^name: *(", join("|", @cards), ")\$\"\n\n";
} else {
    # show a form
    my $header = generate_header("Bulk");
    print <<EOF;
Content-type: text/html

<html>
    <head>
        <title>Bulk Import</title>
        <link rel="stylesheet" type="text/css" href="mystyle.css">
    </head>
    <body>
        $header
        <div class="main">
            <form method="GET">
                Copy and paste a decklist below to view it.
                <br />
                <textarea name="deck" rows="36" cols="80"></textarea>
                <br />
                <input type="submit" value="View Deck!" name="index">
                <input type="submit" value="View Stats!" name="stats">
            </form>
        </div>
    </body>
</html>
EOF
}

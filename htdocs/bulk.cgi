#!/usr/bin/perl

use strict;
use warnings;
use CGI::Carp 'fatalsToBrowser';
use CGI 'param';
use URI::Escape;
use FindBin '$Bin';
use lib "$Bin/../lib";
use Magic;

my $deck = param("deck") // "";
if(length $deck) {
    # do work
    my $dbh = get_db_handle();
    my %name_list = map { lc($_) => 1 } @{$dbh->selectcol_arrayref("SELECT name FROM cards")};

    my @cards = split /\r?\n/, $deck;
    for(@cards) {
        s/#.*//; # remove comments
        s/^\s*\d+\s?x?\s+//; # remove number before card names with optional 'x'
        s/\*CMDR\*//; # remove the string *CMDR* which marks commanders
        s/^\s+//; # remove leading whitespace
        s/\s+$//; # remove trailing whitespace 
        if(/^(.*) \/\/ (.*)$/) { # fix split card names
            $_ = $1;
            push @cards, $2;
        }
    }
    @cards = grep { !/^$/ } @cards; # skip blank lines
    my @bad_names = grep { ! $name_list{lc($_)} } @cards;
    if(@bad_names) {
        print "Content-Type: text/html\n\n";
        print "Could not find the following cards:<br />\n<br />\n";
        print "$_<br />\n" for @bad_names;
        exit;
    }
    for(@cards) {
        s/"/./g; # "escape" double quotes
        $_ = uri_escape($_);
    }

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
        <script>
            function trim() {
                var string = document.getElementById("deck").value;
                var output = string.split('\\n').map(s => s.substr(1)).join('\\n');
                document.getElementById("deck").value = output;
            }
        </script>
    </head>
    <body>
        $header
        <div class="main">
            <form method="GET">
                Copy and paste a decklist below to view it.
                <br />
                <textarea name="deck" id="deck" rows="36" cols="80"></textarea>
                <br />
                <input type="submit" value="View Deck!" name="index">
                <input type="submit" value="View Stats!" name="stats">
                <input type="button" onclick="trim()" value="Trim Text">
            </form>
        </div>
    </body>
</html>
EOF
}

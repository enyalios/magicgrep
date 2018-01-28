#!/usr/bin/perl

use strict;
use warnings;
use CGI::Carp 'fatalsToBrowser';
use URI::Escape;
use CGI 'param';
use FindBin '$Bin';
use lib "$Bin/../lib";
use Magic ':all';

my $string = param("q") // "";

print "Content-Type: text/html\n\n";

if(length $string < 4) {
    print "Your query is too short.  Please type something in the <a href='index.cgi'>search field</a>, and then click 'Stats'.";
    exit;
}
my @queries = get_fields($string);

my $num_cards = my $total_price = 0;
my $name_list = my $price_list = "";

my $dbh = connect_to_db();
my $sth  = $dbh->prepare("SELECT full_text, price_name, price FROM cards ORDER BY name");
$sth->execute();

my $high = my $low = 0;

while((my $full_text, my $price_name, my $price) = $sth->fetchrow_array) {
    next unless match_against_list($full_text, \@queries);
    $num_cards++;
    $total_price += $price;
    $name_list .= "1x $price_name<br />\n";
    $price_list .= sprintf "\$%.2f<br />\n", $price;
    $high = $price if $price > $high;
    $low = $price if $low == 0 || $price < $low;
}

my $avg      = sprintf "%.2f", $total_price / $num_cards;
$high        = sprintf "%.2f", $high;
$low         = sprintf "%.2f", $low;
$total_price = sprintf "%.2f", $total_price;
my $plural = ($num_cards == 1) ? "" : "s";
my $header = generate_header("Stats");
print <<EOF;
<!DOCTYPE html>
<html>
    <head>
        <link rel="stylesheet" type="text/css" href="mystyle.css">
        <script>
            function copy() {
                var range = document.createRange();
                range.selectNodeContents(document.getElementById("list"));
                var sel = window.getSelection();
                sel.removeAllRanges();
                sel.addRange(range);
                document.execCommand('copy');  
                sel.removeAllRanges();
            }
        </script>
    </head>
    <body>
        $header
        <div class="main">
            <button onclick="copy()">Copy Cardlist</button><br />
            <br />
            <div class="side">
                <div id="list">$name_list
                </div>
                <div class="total">
                    $num_cards card${plural}
                </div>
            </div>
            <div class="side">
                <div class="right">
                    $price_list
                </div>
                <div class="total right">
                    \$$total_price
                </div>
            </div>
            <br />
            <br />
            <table>
                <tr>
                    <td>Lowest Price</td>
                    <td>\$$low</td>
                </tr>
                <tr>
                    <td>Average Price</td>
                    <td>\$$avg</td>
                </tr>
                <tr>
                    <td>Highest Price</td>
                    <td>\$$high</td>
                </tr>
            </table>
        </div>
    </body>
</html>
EOF

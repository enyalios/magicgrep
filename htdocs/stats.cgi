#!/usr/bin/perl

use strict;
use warnings;
use CGI 'param';
use CGI::Carp 'fatalsToBrowser';
use HTML::Entities;
use FindBin '$Bin';
use lib "$Bin/../lib";
use Magic ':all';

my $string = param("q") // "";
my $sort = param("sort") // "name";
my $sort_dir = "ASC";
$sort_dir = "DESC" if $sort eq "price";

print "Content-Type: text/html\n\n";

if(length $string < 4) {
    print "Your query is too short.  Please type something in the <a href='index.cgi'>search field</a>, and then click 'Stats'.";
    exit;
}
my @queries = get_fields($string);
tilde_expand(@queries);
$string = encode_entities($string);

my $num_cards = my $total_price = 0;
my $name_list = my $price_list = "";

my $dbh = get_db_handle();
my $sth  = $dbh->prepare("SELECT full_text, price_name, price FROM cards ORDER BY " . $dbh->quote_identifier($sort) . " $sort_dir");
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
my $sort_block = "";
for(qw"Name CMC Color Date Price Type") {
    if(lc($_) eq $sort) {
        $sort_block .= "<b>$_</b>\n";
    } else {
        $sort_block .= sprintf "<a href=\"?q=%s&sort=%s\">%s</a>\n", $string, lc($_), $_;
    }
}
$sort = encode_entities($sort);

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
            <a href="index.cgi?q=$string&sort=$sort">Return to Search</a><br /><br />
            Sort by:
            $sort_block
            <br /><br />
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
            <div class="side" style="margin-left:30px;">
                <button onclick="copy()">Copy Cardlist</button><br />
                <br />
                <table>
                    <tr>
                        <td>Card Count</td>
                        <td><div class="right">$num_cards</div></td>
                    </tr>
                    <tr>
                        <td>Lowest Price</td>
                        <td><div class="right">\$$low</div></td>
                    </tr>
                    <tr>
                        <td>Average Price</td>
                        <td><div class="right">\$$avg</div></td>
                    </tr>
                    <tr>
                        <td>Highest Price</td>
                        <td><div class="right">\$$high</div></td>
                    </tr>
                    <tr>
                        <td>Total Cost</td>
                        <td><div class="right">\$$total_price</div></td>
                    </tr>
                </table>
            </div>
        </div>
    </body>
</html>
EOF

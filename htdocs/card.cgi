#!/usr/bin/perl

use strict;
use warnings;
use CGI::Carp 'fatalsToBrowser';
use CGI 'param';
use FindBin '$Bin';
use lib "$Bin/../lib";
use Magic;
use HTML::Entities;

my $card = param("card") // "";
my $safe_name = encode_entities($card);

my $dbh = get_db_handle();
my $card_ref = $dbh->selectrow_arrayref("SELECT full_text FROM cards WHERE name = ?", {}, $card);
my $card_text = $card_ref->[0];
#$card_text =~ s/^(CMC|CID|Name): .*\n//mg; # dont show some fields
$card_text =~ s/^Name: .*\n//mg; # dont show some fields
# this craziness wraps the lines to 80 columns
1 while $card_text =~ s/^(?=.{81})(.{0,80})( +.*)/$1\n              $2/m;

my $printings_sth = $dbh->prepare("SELECT card_name, set_name, mid, price, fprice FROM printings WHERE card_name = ? ORDER BY mid");
$printings_sth->execute($card);

my $card_list;
my $lowest_price = my $lowest_fprice = 0;
while((my $card_name, my $set_name, my $mid, my $price, my $fprice) = $printings_sth->fetchrow_array) {
    my $price_string = "";
    if($price != 0 && $fprice != 0) {
        $price_string = sprintf "\$%.2f / \$%.2ff", $price, $fprice;
    } elsif($fprice != 0) {
        $price_string = sprintf "\$%.2ff", $fprice;
    } elsif($price != 0) {
        $price_string = sprintf "\$%.2f", $price;
    } else {
        $price_string = "???";
    }
    
    if($set_name !~ /^(International|Collector's) Edition$/) {
        # ignore these sets for lowest price since they arent tourney legal
        $lowest_price = $price if $lowest_price == 0;
        if($price != 0 && $price < $lowest_price) {
            $lowest_price = $price;
        }
        $lowest_fprice = $fprice if $lowest_fprice == 0;
        if($fprice != 0 && $fprice < $lowest_fprice) {
            $lowest_fprice = $fprice;
        }
    }

    $card_list .= sprintf "<div class=\"cardpane2\"><img src=\"%s?multiverseid=%d&type=card\"><br />\n", image_handler(), $mid;
    $card_list .= sprintf "<span class=\"cardpane_price\">(%s)</span><span class=\"cardpane_set\" title=\"%s\">%s</span></div>\n", $price_string, $set_name, $set_name;
}

$lowest_price  = $lowest_price  == 0 ? "" : sprintf "Low price:   \$%.2f\n", $lowest_price;
$lowest_fprice = $lowest_fprice == 0 ? "" : sprintf "Foil price:  \$%.2f\n", $lowest_fprice;

my $header = generate_header();

print <<EOF
Content-Type: text/html

<!DOCTYPE html>
<html>
    <head>
        <link rel="stylesheet" type="text/css" href="mystyle.css">
        <title>$safe_name</title>
    </head>
    <body>
        $header
        <div class="main">
            <div class="big">$safe_name</div>
            <div class="carddetail">${card_text}${lowest_price}${lowest_fprice}</div>
            <div>
                $card_list
            </div>
        </div>
    </body>
</html>
EOF

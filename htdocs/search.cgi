#!/usr/bin/perl

use strict;
use warnings;
use CGI::Carp 'fatalsToBrowser';
use URI::Escape;
use CGI 'param';
use FindBin '$Bin';
use lib "$Bin/../lib";
use Magic ':all';

my $cards_per_page = 20; my $compact = 0;
#$cards_per_page = 50; $compact = 1;
my $string = param("q") // "";
my $escaped_query = uri_escape($string);
my $page = param("page") // 1;
my $sort = param("sort") // "name";
my $card_start = ($page - 1) * $cards_per_page + 1;
my $epoch = time;
my $one_week = 7 * 24 * 60 * 60;

print "Content-Type: text/html\n\n" if $ENV{SCRIPT_NAME} =~ /search\.cgi$/;
my $content;
$content .= "<table>\n" unless $compact;

my @queries = get_fields($string);
tilde_expand(@queries);

# make it read in 1 card at a time
my $num_cards = my $shown_cards = 0;

my $dbh = get_db_handle();
my $sort_dir = "ASC";
$sort_dir = "DESC" if $sort eq "price";
my $sth  = $dbh->prepare("SELECT full_text, name, art_name, price_name, price, price_updated FROM cards ORDER BY " . $dbh->quote_identifier($sort) . " $sort_dir");
$sth->execute();

while((my $full_text, my $name, my $art_name, my $price_name, my $price, my $price_updated) = $sth->fetchrow_array) {
    next unless match_against_list($full_text, \@queries);

    $num_cards++;
    next if $num_cards < $card_start;
    next if $num_cards > $page * $cards_per_page;
    $shown_cards++;

    my $escaped_name = uri_escape($name);
    my $art_name = uri_escape($art_name);
    my $price_name = uri_escape($price_name);
    if(defined $price && $price > 0 && defined $price_updated && $epoch - $price_updated < $one_week) {
        $price = sprintf "\$%4.2f", $price;
    } else {
        $price = "<span onclick='price(this, \"$price_name\")'><a href='javascript:return false;'>Click to Lookup</a></span>"
    }
    $full_text =~ s/^(CMC|CID|Legality): .*\n//mg; # dont show some fields
    # this craziness wraps the lines to 80 columns
    1 while $full_text =~ s/^(?=.{81})(.{0,80})( +.*)/$1\n              $2/m;
    chomp $full_text;
    if($compact) {
        $content .= "<div class='cardpane'><a href='card.cgi?card=$escaped_name'><img class='cardimage' src='http://gatherer.wizards.com/Handlers/Image.ashx?name=$art_name&type=card&.jpg'></a><br/>";
    } else {
        $content .= "<tr><td><a href='card.cgi?card=$escaped_name'><img class='cardimage' src='http://gatherer.wizards.com/Handlers/Image.ashx?name=$art_name&type=card&.jpg'></a></td>";
        $content .= "<td><div class='text'>$full_text\n";
        $content .= "Price:       $price</div>\n";
    }
    $content .= "<a class='link' href='http://magiccards.info/query?q=!$escaped_name'>MC</a>";
    $content .= "<a class='link' href='https://edhrec.com/route?cc=$escaped_name'>EDH</a>";
    $content .= "<a class='link' href='http://shop.tcgplayer.com/magic/product/show?ProductName=$price_name&IsProductNameExact=true'>TCG</a>";
    $content .= "<a class='link' href='http://enyalios.net/cgi-bin/mtgstocks.cgi?q=$price_name'>MS</a>";
    if($compact) {
        $content .= "</div>\n";
    } else {
        $content .= "</td></tr>\n";
    }
}
$content .= "</table>\n" unless $compact;

$dbh->disconnect;

# print out a count at the end
$sort = ($sort eq "name") ? "" : "&sort=$sort";
my $prev = sprintf "<a href='?page=%d%s&q=%s'>&lt; prev</a> ", $page - 1, $sort, $escaped_query;
$prev = "" if $page == 1;
my $next = sprintf " <a href='?page=%d%s&q=%s'>next &gt;</a>", $page + 1, $sort, $escaped_query;
$next = "" if $card_start + $shown_cards - 1 == $num_cards;
my $showing = sprintf "%d - %d of ", $card_start, $card_start + $shown_cards - 1;
$showing = "" if $shown_cards == $num_cards;
my $pager = sprintf "<table><tr><td class='pager'>%s</td><td class='pager pager-center'>%s%d card%s</td><td class='pager'>%s</td></tr></table>",
    $prev,
    $showing,
    $num_cards,
    $num_cards != 1?"s":"",
    $next;
print "<div class='header2'>$pager</div>\n$content\n<div class='footer'>$pager</div>";

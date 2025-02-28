#!/usr/bin/perl

use strict;
use warnings;
use CGI::Carp 'fatalsToBrowser';
use URI::Escape;
use CGI 'param';
use FindBin '$Bin';
use lib "$Bin/../lib";
use Magic ':all';

my $cards_per_page = 20;
my $string = param("q") // "";
my $escaped_query = uri_escape($string);
my $page = param("page") // 1;
my $sort = param("sort") // "name";
my $output = param("output") // "normal";
$output = "normal" unless $output =~ /^(compact|text)$/;
$cards_per_page = 60 if $output eq "compact";
$cards_per_page = 200 if $output eq "text";
$cards_per_page = 999999 if $output eq "text" && $ENV{HTTP_X_REAL_IP} =~ /^192\.168\.0\./;
my $card_start = ($page - 1) * $cards_per_page + 1;
my $epoch = time;
my $one_week = 7 * 24 * 60 * 60;

print "Content-Type: text/html\n\n" if $ENV{SCRIPT_NAME} =~ /search\.cgi$/;
my $content;
$content .= "<table>\n" if $output eq "normal";

my @queries = get_fields($string);
tilde_expand(@queries);

# make it read in 1 card at a time
my $num_cards = my $shown_cards = 0;

my $dbh = get_db_handle();
my $sort_dir = "ASC";
$sort_dir = "DESC" if $sort eq "price";
my $sth  = $dbh->prepare("SELECT full_text, name, art_name, price_name, price, price_updated, date FROM cards ORDER BY " . $dbh->quote_identifier($sort) . " $sort_dir");
$sth->execute();

while((my $full_text, my $name, my $art_name, my $price_name, my $price, my $price_updated, my $date) = $sth->fetchrow_array) {
    next unless match_against_list($full_text, \@queries);

    $num_cards++;
    next if $num_cards < $card_start;
    next if $num_cards > $page * $cards_per_page;
    $shown_cards++;

    my $escaped_name = uri_escape($name);
    my $art_name = uri_escape($art_name);
    my $price_name = uri_escape($price_name);
    if(defined $price && $price > 0) {
        $price = sprintf "\$%4.2f", $price;
    } else {
        $price = "???"
    }
    if($output eq "normal") {
        $full_text =~ s/^(CMC|Color|CID|Legality|Reserved|Timeshifted): .*\n//mg; # dont show some fields
        $full_text =~ s/^(Name: .*\n)Name: .*\n/$1/mg; # only show the first name field
        # this craziness wraps the lines to 80 columns
        1 while $full_text =~ s/^(?=.{81})(.{0,80})( +.*)/$1\n              $2/m;
    }
    chomp $full_text;
    my $image_handler = image_handler();
    if($output eq "compact") {
        $content .= "<div class='cardpane'><a href='card.cgi?card=$escaped_name'><img class='cardimage' src='$image_handler?name=$art_name&type=card&.jpg'></a><br/>$price ";
    } elsif($output eq "text") {
        $content .= "$full_text\nPrice:       $price\nDate:        $date\n\n";
    } else {
        $content .= "<tr><td><a href='card.cgi?card=$escaped_name'><img class='cardimage' src='$image_handler?name=$art_name&type=card&.jpg'></a></td>";
        $content .= "<td><div class='text'>$full_text\n";
        $content .= "Price:       $price</div>\n";
    }
    if($output ne "text") {
        $content .= "<a class='link' href='https://edhrec.com/route?cc=$escaped_name'>EDH</a>";
        $content .= "<a class='link' href='http://shop.tcgplayer.com/magic/product/show?ProductName=$price_name&IsProductNameExact=true'>TCG</a>";
        $content .= "<a class='link' href='http://enyalios.net/cgi-bin/mtgstocks.cgi?q=$price_name'>MS</a>";
    }
    if($output eq "compact") {
        $content .= "</div>\n";
    } elsif($output eq "normal") {
        $content .= "</td></tr>\n";
    }
}
$content .= "</table>\n" if $output eq "normal";

$dbh->disconnect;

# print out a count at the end
$sort = ($sort eq "name") ? "" : "&sort=$sort";
my $output_query_string = ($output eq "normal") ? "" : "&output=$output";
my $prev = sprintf "<a href='?page=%d%s%s&q=%s'>&lt; prev</a> ", $page - 1, $sort, $output_query_string, $escaped_query;
$prev = "" if $page == 1;
my $next = sprintf " <a href='?page=%d%s%s&q=%s'>next &gt;</a>", $page + 1, $sort, $output_query_string, $escaped_query;
$next = "" if $card_start + $shown_cards - 1 == $num_cards;
my $showing = sprintf "%d - %d of ", $card_start, $card_start + $shown_cards - 1;
$showing = "" if $shown_cards == $num_cards;
my $pager = sprintf "<table><tr><td class='pager'>%s</td><td class='pager pager-center'>%s%d card%s</td><td class='pager'>%s</td></tr></table>",
    $prev,
    $showing,
    $num_cards,
    $num_cards != 1?"s":"",
    $next;
if($output eq "text") {
    print $content;
} else {
    print "<div class='header2'>$pager</div>\n$content\n<div class='footer'>$pager</div>";
}

#!/usr/bin/perl

use warnings;
use strict;
use CGI::Carp 'fatalsToBrowser';
use CGI 'param';
use LWP::Simple;
use XML::Simple;
use URI::Escape;
use FindBin '$Bin';
use lib "$Bin/../lib";
use Magic;

$| = 1;
$SIG{ALRM} = sub { die "request timed out\n" };
alarm 30;
my $dbh = get_db_handle();
my $cgi = defined $ENV{REMOTE_ADDR} ? 1 : 0;
my $sth = $dbh->prepare("UPDATE printings SET price = ?, fprice = ? WHERE price_name = ? AND set_name = ?");

sub get_set_list {
    my $card = shift;
    my $ary_ref = $dbh->selectcol_arrayref("SELECT set_name FROM printings WHERE price_name = ?", {}, $card);
    return @$ary_ref;
}

sub get_price {
    my ($card, $set) = @_;
    my $extra = "";
    $extra .= " (IE)" if $set eq "International Edition";
    $extra .= " (CE)" if $set eq "Collector's Edition";
    $extra .= " (Oversize)" if $set eq "Vanguard";

    my $url = sprintf "http://partner.tcgplayer.com/x3/phl.asmx/p?pk=GATHPRICE&s=%s&p=%s%s", uri_escape($set), uri_escape($card), uri_escape($extra);
    my $content = get $url;
    #print "getting <$url>\n";
    my $tree = XMLin $content;
    print "card = $card\nset = $set\nurl = $url\ncontent = $content\n" unless $tree;

    my $price = $tree->{product}->{avgprice} // 0;
    my $fprice = $tree->{product}->{foilavgprice} // 0;

    printf "%-40s  %-40s  %7.2f  %7.2f\n", $card, $set, $price, $fprice unless $cgi;

    $sth->execute($price, $fprice, $card, $set);

    # dont count these in the low price, since they arent tournament legal
    return 0 if $set =~ /^(International|Collector's) Edition$/;

    if($price > 0 && $fprice > 0) {
        # if both are non-zero return the lower one
        return $price < $fprice ? $price : $fprice;
    } else {
        # if both are zero it doesnt matter which we return
        # if fprice is zero return the other one
        return $fprice == 0 ? $price : $fprice;
    }
}

sub update_db {
    my ($card, $price) = @_;
    $dbh->do("UPDATE cards SET price = ?, price_updated = ? WHERE price_name = ?", {}, $price, time, $card);
}


my $card = param("q") // "";
my $lowest = 0;
for my $set (get_set_list($card)) {
    my $price = get_price($card, $set);
    next if $price == 0;
    if($lowest == 0 || $price < $lowest) {
        $lowest = $price;
    }
}

update_db($card, $lowest);
$dbh->disconnect;

exit unless $cgi;

print "Content-Type: text/html\n\n";
if($lowest == 0) {
    print "???\n";
} else {
    printf "\$%4.2f\n", $lowest;
}

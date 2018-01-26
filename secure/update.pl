#!/usr/bin/perl
#
# this script updates the card database

use strict;
use warnings;
use LWP::Simple;
use JSON;
use FindBin '$Bin';
use lib "$Bin/lib";
use Magic;

# tweak this depending on where you want to store your data
my $url = "https://mtgjson.com/json/AllSets.json.zip";
my $version_url = "http://mtgjson.com/json/version.json";
my $version_file = "$Bin/version.txt";
$| = 1;

my %set_trans = (
    "Modern Masters 2015 Edition" => "Modern Masters 2015",
    "Modern Masters 2017 Edition" => "Modern Masters 2017",
    "Magic 2010" => "Magic 2010 (M10)",
    "Magic 2011" => "Magic 2011 (M11)",
    "Magic 2012" => "Magic 2012 (M12)",
    "Magic 2013" => "Magic 2013 (M13)",
    "Magic 2014 Core Set" => "Magic 2014 (M14)",
    "Magic 2015 Core Set" => "Magic 2015 (M15)",
    "Limited Edition Alpha" => "Alpha Edition",
    "Limited Edition Beta" => "Beta Edition",
    "Time Spiral \"Timeshifted\"" => "Timeshifted",
    "Prerelease Events" => "Prerelease Cards",
    "Launch Parties" => "Launch Party %26 Release Event Promos",
    "Release Events" => "Launch Party %26 Release Event Promos",
    "Planechase 2012 Edition" => "Planechase 2012",
    "Friday Night Magic" => "FNM Promos",
    "Media Inserts" => "Media Promos",
    "15th Anniversary" => "Media Promos",
    "Dragon Con" => "Media Promos",
    "Magic Game Day" => "Game Day Promos",
    "Seventh Edition" => "7th Edition",
    "Eighth Edition" => "8th Edition",
    "Ninth Edition" => "9th Edition",
    "Tenth Edition" => "10th Edition",
    "Judge Gift Program" => "Judge Promos",
    "International Collector's Edition" => "International Edition",
    "Deckmasters" => "Deckmasters Garfield vs Finkel",
    "Grand Prix" => "Grand Prix Promos",
    "Ravnica: City of Guilds" => "Ravnica",
    "Magic: The Gathering-Commander" => "Commander",
    "Duel Decks Anthology, Divine vs. Demonic" => "Duel Decks: Divine vs. Demonic",
    "Magic: The Gathering--Conspiracy" => "Conspiracy",
    "Commander 2013 Edition" => "Commander 2013",
    "Wizards Play Network" => "WPN %26 Gateway Promos",
    "Gateway" => "WPN %26 Gateway Promos",
    "Summer of Magic" => "WPN %26 Gateway Promos",
    "Super Series" => "JSS/MSS Promos",
    "Duel Decks Anthology, Jace vs. Chandra" => "Duel Decks: Anthology",
    "Duel Decks Anthology, Elves vs. Goblins" => "Duel Decks: Anthology",
    "Duel Decks Anthology, Garruk vs. Liliana" => "Duel Decks: Anthology",
    "From the Vault: Annihilation (2014)" => "From the Vault: Annihilation",
    "Coldsnap Theme Decks" => "Coldsnap Theme Deck Reprints",
    "Pro Tour" => "Pro Tour Promos",
    "Modern Event Deck 2014" => "Magic Modern Event Deck",
    "Arena League" => "Arena Promos",
    "Clash Pack" => "Unique and Miscellaneous Promos",
    "Worlds" => "Judge Promos",
    "World Magic Cup Qualifiers" => "WMCQ Promo Cards",
    "Two-Headed Giant Tournament" => "Arena Promos",
    "Happy Holidays" => "Special Occasion",
    "Champs and States" => "Champs Promos",
);

my %char_trans = (
    "\xE2\x80\x94" => "--",
    "\xE2\x80\xA2" => "-",
    "\xE2\x88\x92" => "-",
    "\xE2\x80\x98" => "'",
    "\xE2\x80\x99" => "'",
    "\xE2\x88\x9E" => "infinity",
    "\xC3\xBA" => "u",
    "\xC3\xA0" => "a",
    "\xC3\xA1" => "a",
    "\xC3\xA2" => "a",
    "\xC3\xB6" => "o",
    "\xC3\xBB" => "u",
    "\xC3\xA9" => "e",
    "\xC2\xBD" => ".5",
    "\xC2\xAE" => "(R)",
    "\xC3\xAD" => "i",
);

sub uniq {
    my %seen;
    return grep { !$seen{$_}++ } @_;
}

sub colors_to_string {
    my $string = "";
    my %colors = qw(
        White W
        Blue  U
        Black B
        Red   R
        Green G
    );
    $string .= $colors{$_} for @_;
    return $string;
}

sub cost_to_colors {
    my $string = "";
    return "" unless length $_[0];
    for(split //, "WUBRG") {
        $string .= $_ if $_[0] =~ /$_/i;
    }
    return $string;
}

sub check_version {
    my $local_version = "";
    if(-f $version_file) {
        open my $fh, "<", $version_file or die;
        chomp($local_version = <$fh>);
        close $fh;
    }
    chomp(my $remote_version = get $version_url);
    if($local_version eq $remote_version ) {
        if(!defined $ARGV[0] || $ARGV[0] ne "-f") {
            print "mtgjson version hasn't changed, exiting\n";
            exit;
        } else {
            print "forcing update\n";
        }
    }
    if(defined $remote_version) {
        open my $fh, ">", $version_file or die;
        print $fh "$remote_version\n";
        close $fh;
    }
}


my $num_cards = "0";

check_version();

print "downloading...\n";

my (%cards, @by_set);
my $blob = join "", `wget -O - "$url" | funzip`;
#my $blob = join "", `cat AllSets.json.zip | funzip`;
while(my ($key, $value) = each %char_trans) {
    $blob =~ s/$key/$value/g;
}
print "parsing...\n";
my $tree = decode_json($blob);
for my $set_code (keys %$tree) {
    my $set_name = $tree->{$set_code}->{name};
    my $set_release = $tree->{$set_code}->{releaseDate};
    for my $card (@{$tree->{$set_code}->{cards}}) {
        next if $card->{layout} eq "token";
        my $name = $card->{name};
        $cards{$name}{name} = $name;
        $cards{$name}{art_name} = $name;
        $cards{$name}{price_name} = $name;
        $cards{$name}{cost} = $card->{manaCost};
        $cards{$name}{type_line} = $card->{type};
        $cards{$name}{simple_type} = join " ", @{$card->{types}};
        if(defined $card->{power}) {
            $cards{$name}{size}  = $card->{power} . "/" . $card->{toughness};
        }
        $cards{$name}{text} = $card->{text};
        push @{$cards{$name}{set}}, [ $set_release, $set_name . " " . $card->{rarity} ];
        $cards{$name}{cmc}  = $card->{cmc};
        $cards{$name}{cid}  = join "", @{$card->{colorIdentity}} if defined $card->{colorIdentity};
        $cards{$name}{loyal} = $card->{loyalty};
        $cards{$name}{extras} = undef;
        if(defined $card->{colors} && (colors_to_string(@{$card->{colors}}) ne cost_to_colors($card->{manaCost}))) {
            push @{$cards{$name}{extras}}, join("/", @{$card->{colors}}) . " color indicator.";
        }
        if($card->{layout} eq "vanguard") {
            my $hand = $card->{hand};
            my $life = $card->{life};
            $hand = "+$hand" if $hand >= 0;
            $life = "+$life" if $life >= 0;
            $cards{$name}{text} = "$hand cards / $life life\n" . $cards{$name}{text};
        }
        if(defined $card->{names}) {
            if($card->{layout} eq "split" || $card->{layout} eq "aftermath") {
                push @{$cards{$name}{extras}}, "This is half of the split card " . join(" // ", @{$card->{names}}) . ".";
                $cards{$name}{art_name} = $cards{$name}{price_name} = join(" // ", @{$card->{names}});
            } elsif($card->{layout} eq "double-faced") {
                if($card->{names}->[0] eq $name) {
                    push @{$cards{$name}{extras}}, "Front face. Transforms into " . $card->{names}->[1] . ".";
                } else {
                    push @{$cards{$name}{extras}}, "Back face. Transforms into " . $card->{names}->[0] . ".";
                    $cards{$name}{price_name} = $card->{names}->[0];
                }
            } elsif($card->{layout} eq "flip") {
                if($card->{names}->[0] eq $name) {
                    push @{$cards{$name}{extras}}, "Flips into " . $card->{names}->[1] . ".";
                } else {
                    push @{$cards{$name}{extras}}, "Flips from " . $card->{names}->[0] . ".";
                    $cards{$name}{art_name} = $cards{$name}{price_name} = $card->{names}->[0];
                }
            } elsif($card->{layout} eq "meld") {
                if($card->{names}->[0] eq $name) {
                    push @{$cards{$name}{extras}}, "Melds with " . $card->{names}->[1] . " into " . $card->{names}->[2] . ".";
                } elsif($card->{names}->[1] eq $name) {
                    push @{$cards{$name}{extras}}, "Melds with " . $card->{names}->[0] . " into " . $card->{names}->[2] . ".";
                } else {
                    push @{$cards{$name}{extras}}, "Melds from " . $card->{names}->[0] . " and " . $card->{names}->[1] . ".";
                }
            } else {
                push @{$cards{$name}{extras}}, "Related to " .
                join(", ", grep { $_ ne $name } @{$card->{names}}) . ".";
            }
        }
        unless($tree->{$set_code}->{onlineOnly}) {
            my $set = $set_name;
            $set = $set_trans{$set} if $set_trans{$set};
            if($cards{$name}{simple_type} =~ /^(Scheme|Plane|Phenomenon)$/) {
                $cards{$name}{price_name} = "$name ($set)";
                $set = "Oversize Cards";
            }
            my $mid = $card->{multiverseid};
            $mid = 0 unless defined $mid;
            push @by_set, [ $name, $cards{$name}{price_name}, $set, $mid ];
        }
    }
}

print "inserting cards...\n";
my $dbh = connect_to_db();
my %card_names = map { $_ => 1 } @{$dbh->selectcol_arrayref("SELECT name FROM cards")};
my $insert = $dbh->prepare("INSERT INTO cards (name, cmc, color, type, date, full_text, art_name, price_name) VALUES (?, ?, ?, ?, ?, ?, ?, ?)");
my $update = $dbh->prepare("UPDATE cards SET name = ?, cmc = ?, color = ?, type = ?, date = ?, full_text = ?, art_name = ?, price_name = ? WHERE name = ?");
$dbh->do("BEGIN TRANSACTION");
my $i = 0;
my $total = keys %cards;
for(sort keys %cards) {
    my %card = %{$cards{$_}};
    $card{text} //= "";
    if($card{extras}) {
        $card{text} .= "\n" if $card{text};
        $card{text} .= "[" . join(" ", @{$card{extras}}) . "]";
    }
    $card{text} =~ s/\n/\n             /g;
    $card{cost} //= "";
    $card{cost} =~ s/\{([WUBRGXC\d]+)\}/$1/g;
    $card{text} =~ s/\{?(CHAOS)\}?/{$1}/g;
    $card{cmc} //= "";
    $card{cid} //= "";
    # find the first printing that wasnt in a 'Special' set
    my $date = (sort map { $_->[0] } grep { $_->[1] !~ /(Prerelease Events|Media Inserts|Launch Parties|Arena League) Special/ } @{$card{set}})[0];

    my $fulltext = "Name:        $card{name}\n";
    $fulltext .= "Cost:        $card{cost}\n" unless $card{cost} eq "";
    $fulltext .= "CMC:         $card{cmc}\n";
    $fulltext .= "CID:         $card{cid}\n";
    $fulltext .= "Type:        $card{type_line}\n";
    $fulltext .= "Pow/Tgh:     $card{size}\n" if defined $card{size};
    $fulltext .= "Loyalty:     $card{loyal}\n" if defined $card{loyal};
    $fulltext .= "Rules Text:  $card{text}";
    $fulltext .= "\n";
    $fulltext .= "Set/Rarity:  " . join(", ", uniq map { $_->[1] } sort { $a->[0] cmp $b->[0] } @{$card{set}});
    $fulltext .= "\n";

    if($card_names{$_}) {
        $update->execute($card{name}, $card{cmc}, $card{cid}, $card{simple_type}, $date, $fulltext, $card{art_name}, $card{price_name}, $_);
    } else {
        $insert->execute($card{name}, $card{cmc}, $card{cid}, $card{simple_type}, $date, $fulltext, $card{art_name}, $card{price_name});
    }
    #printf "\r%d/%d %.1f%% ", ++$i, $total, $i/$total*100;
}
#print "\n";
$dbh->do("COMMIT");

print "inserting sets...\n";
my $sth = $dbh->prepare("INSERT OR IGNORE INTO printings (card_name, price_name, set_name, mid) VALUES (?, ?, ?, ?)");
$dbh->do("BEGIN TRANSACTION");
$sth->execute($_->[0], $_->[1], $_->[2], $_->[3]) for @by_set;
$dbh->do("COMMIT");

$dbh->disconnect;

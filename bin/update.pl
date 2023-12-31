#!/usr/bin/perl
#
# this script updates the card database

use strict;
use warnings;
use LWP::UserAgent;
use JSON;
#use List::Util 'any'; # needs version 1.33
use FindBin '$Bin';
use lib "$Bin/../lib";
use Magic;
use utf8;

# tweak this depending on where you want to store your data
my $printings_url = "https://mtgjson.com/api/v5/AllPrintings.json.bz2";
my $prices_url = "https://mtgjson.com/api/v5/AllPricesToday.json.bz2";
my $version_url = "https://mtgjson.com/api/v5/Meta.json";
my $version_file = "$Bin/../db/version.txt";
$| = 1;

my $ua = LWP::UserAgent->new(agent => "Mozilla");
sub get { return $ua->get($_[0])->decoded_content; }

my %set_trans = (
    "Magic 2010" => "Magic 2010 (M10)",
    "Magic 2011" => "Magic 2011 (M11)",
    "Magic 2012" => "Magic 2012 (M12)",
    "Magic 2013" => "Magic 2013 (M13)",
    "Magic 2014" => "Magic 2014 (M14)",
    "Magic 2015" => "Magic 2015 (M15)",
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
    "Magic: The Gathering-Commander" => "Commander",
    "Duel Decks Anthology, Divine vs. Demonic" => "Duel Decks: Divine vs. Demonic",
    "Magic: The Gathering--Conspiracy" => "Conspiracy",
    "Commander 2011" => "Commander",
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
    "Ultimate Box Topper" => "Ultimate Masters: Box Toppers",
    "Time Spiral Timeshifted" => "Timeshifted",
    "Time Spiral Remastered" => "Time Spiral: Remastered",
    "Forgotten Realms Commander" => "Commander: Adventures in the Forgotten Realms",
    "Crimson Vow Commander" => "Commander: Innistrad: Crimson Vow",
    "Midnight Hunt Commander" => "Commander: Innistrad: Midnight Hunt",
    "Neon Dynasty Commander" => "Commander: Kamigawa: Neon Dynasty",
    "Zendikar Rising Commander" => "Commander: Zendikar Rising",
    "RNA Guild Kit" => "Ravnica Allegiance: Guild Kits",
    "GRN Guild Kit" => "Guilds of Ravnica: Guild Kits",
    "Kaldheim Commander" => "Commander: Kaldheim",
    "Secret Lair Drop" => "Secret Lair Drop Series",
    "Strixhaven Mystical Archive" => "Strixhaven: Mystical Archives",
    "Kaladesh Inventions" => "Masterpiece Series: Kaladesh Inventions",
    "Amonkhet Invocations" => "Masterpiece Series: Amonkhet Invocations",
    "New Capenna Commander" => "Commander: Streets of New Capenna",
    "Dominaria United Commander" => "Commander: Dominaria United",
    "Warhammer 40,000 Commander" => "Universes Beyond: Warhammer 40,000",
    "The Brothers' War Commander" => "Commander: The Brothers' War",
    "Phyrexia: All Will Be One Commander" => "Commander: Phyrexia: All Will Be One",
    "March of the Machine Commander" => "Commander: March of the Machine",
    "The Lord of the Rings: Tales of Middle-earth" => "Universes Beyond: The Lord of the Rings: Tales of Middle-earth",
    "Tales of Middle-earth Commander" => "Commander: The Lord of the Rings: Tales of Middle-earth",
);

my %char_trans = (
    "à" => "a",
    "á" => "a",
    "â" => "a",
    "ä" => "a",
    "í" => "i",
    "ó" => "o",
    "ö" => "o",
    "û" => "u",
    "ü" => "u",
    "ú" => "u",
    "é" => "e",
    "É" => "E",
    "ñ" => "n",
    "®" => "(R)",
);

sub uniq {
    my %seen;
    return grep { !$seen{$_}++ } @_;
}

sub cost_to_colors {
    my @array = ();
    return "" unless length $_[0];
    for(split //, "WUBRG") {
        push(@array, $_) if $_[0] =~ /$_/i;
    }
    return color_array_to_sorted_string(\@array);
}

sub check_version {
    my $local_version = "";
    if(-f $version_file) {
        open my $fh, "<", $version_file or die;
        chomp($local_version = <$fh>);
        close $fh;
    }
    chomp(my $remote_version = decode_json(get $version_url)->{data}->{version});
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

sub color_sort_order {
    # 0 = colorless non-land, non-artifiact
    # 1 = white
    # 2 = blue
    # 3 = black
    # 4 = red
    # 5 = green
    # 6 = gold
    # 7 = hybrid
    # 8 = split
    # 9 = colorless artifact
    # 10 = non-basic lands
    # 11 = basic lands

    my $card = $_[0];

    return 8 if $card->{layout} eq "split";
    # we check for lands before colored-ness so dryad arbor sorts correctly
    return 11 if(defined $card->{supertypes} && (grep { $_ eq 'Basic' } @{$card->{supertypes}})); # basic land
    return 10 if(defined $card->{types}      && (grep { $_ eq "Land" }  @{$card->{types}}));      # non-basic land

    # we use the union of the colors array and the mana cost so that devoid cards sort correctly
    my @colors = ();
    @colors = @{$card->{colors}} if defined $card->{colors};
    if(defined $card->{manaCost}) {
        for(split //, $card->{manaCost}) {
            push @colors, $_ if $_ =~ /^[WUBRG]$/;
        }
        @colors = uniq @colors;
    }

    if(@colors){
        if(@colors == 1){
            # if it has exactly one color
            # put the colors in the right order
            return 1 if $colors[0] eq "W";
            return 2 if $colors[0] eq "U";
            return 3 if $colors[0] eq "B";
            return 4 if $colors[0] eq "R";
            return 5 if $colors[0] eq "G";
            die "unknown color '$colors[0]' for card $card->{name}";
        } else {
            # if we have more than one color
            # is this a hybrid card?
            return 7 if(defined $card->{manaCost} && $card->{manaCost} =~ m|/|);
            return 6; # gold
        }
    } else {
        # if this card has no color
        return 9 if(defined $card->{types} && (grep { $_ eq "Artifact" } @{$card->{types}})); # colorless artifact
        return 0; # colorless spell
    }
    die "should not have gotten here";
}

sub color_array_to_sorted_string {
    my $array = [@{$_[0]}];
    my %letter_to_sort_index = qw(
        W 1
        U 2
        B 3
        R 4
        G 5
    );
    my %reorder = qw(
        WR RW
        WG GW
        UG GU
        WUG GWU
        WUR UWR
        WBR RWB
        WRG RGW
        UBG BGU
        URG GUR
        WUBG GWUB
        WURG RGWU
        WBRG BRGW
    );

    my $string = join "",
    map { $_->[0] }
    sort { $a->[1] <=> $b->[1] }
    map { [ $_, $letter_to_sort_index{$_} ] }
    @$array;

    $string = $reorder{$string} // $string;

    return $string;
}

sub download_and_parse {
    my $url = $_[0];
    my $quiet = "--quiet";
    $quiet = "" if -t STDOUT;
    my $localpath = $url;
    $localpath =~ s/.*\//\/var\/www\/local\//;
    my $blob;
    if(-e $localpath) {
        print "using local copy of $localpath\n";
        $blob = join "", `bzcat $localpath`;
    } else {
        $blob = join "", `wget $quiet -O - "$url" | bzcat`;
    }
    print "parsing...\n";
    my $tree = decode_json($blob);
    return $tree
}

sub min {
    my @array = sort { $a <=> $b } grep { defined } @_;
    return $array[0];
}


my $num_cards = "0";

check_version();

my (%cards, @by_set, $tree);

print "downloading price data...\n";
$tree = download_and_parse($prices_url);
my $date = $tree->{meta}->{date};
$tree = $tree->{data};
my %prices;
for my $uuid (keys %$tree) {
    $prices{$uuid}{normal} = $tree->{$uuid}->{paper}->{tcgplayer}->{retail}->{normal}->{$date};
    $prices{$uuid}{foil}   = $tree->{$uuid}->{paper}->{tcgplayer}->{retail}->{foil}->{$date};
}

print "downloading card data...\n";
$tree = download_and_parse($printings_url)->{data};
for my $set_code (keys %$tree) {
    my $set_name = $tree->{$set_code}->{name};
    my $set_release = $tree->{$set_code}->{releaseDate};
    for my $card (@{$tree->{$set_code}->{cards}}) {
        next if $card->{layout} eq "token";
        my $name = $card->{name};
        if(defined $card->{otherFaceIds}) {
            my $fullname = $name;
            $name = $card->{faceName};
            my @names = split " // ", $fullname;
            if($card->{layout} eq "split" || $card->{layout} eq "aftermath") {
                push @{$cards{$name}{extras}}, "This is half of the split card $fullname.";
                $cards{$name}{art_name} = $cards{$name}{price_name} = $fullname;
            } elsif($card->{layout} eq "transform") {
                if($card->{side} eq "a") {
                    push @{$cards{$name}{extras}}, "Front face. Transforms into $names[1].";
                } else {
                    push @{$cards{$name}{extras}}, "Back face. Transforms from $names[0].";
                    $cards{$name}{price_name} = $names[0];
                }
            } elsif($card->{layout} eq "flip") {
                if($card->{side} eq "a") {
                    push @{$cards{$name}{extras}}, "Flips into $names[1].";
                } else {
                    push @{$cards{$name}{extras}}, "Flips from $names[0].";
                    $cards{$name}{art_name} = $cards{$name}{price_name} = $names[0];
                }
            } elsif($card->{layout} eq "meld") {
                if(defined $card->{cardParts}) { # Bruna, the Fading Light // Brisela, Voice of Nightmares is missing this
                    @names = @{$card->{cardParts}};
                    if($card->{side} eq "a") {
                        my $other = ($names[0] eq $name) ? $names[1] : $names[0];
                        push @{$cards{$name}{extras}}, "Melds with $other into $names[2].";
                    } else {
                        push @{$cards{$name}{extras}}, "Melds from $names[0] and $names[1].";
                    }
                }
            } elsif($card->{layout} eq "adventure") {
                if($card->{side} eq "a") {
                    push @{$cards{$name}{extras}}, "Related to $names[1].";
                } else {
                    $cards{$name}{art_name} = $cards{$name}{price_name} = $names[0];
                    push @{$cards{$name}{extras}}, "Related to $names[0].";
                }
            } elsif($card->{layout} eq "modal_dfc") {
                if($card->{side} eq "a") {
                    push @{$cards{$name}{extras}}, "Front face. Related to $names[1].";
                } else {
                    $cards{$name}{price_name} = $names[0];
                    push @{$cards{$name}{extras}}, "Back face. Related to $names[0].";
                }
            } elsif($card->{layout} eq "reversible_card") {
                # do nothing
            } else {
                push @{$cards{$name}{extras}}, "Related to " .
                join(", ", grep { $_ ne $name } @names) . "." if @names > 1;
            }
        }
        $cards{$name}{name} = $name;
        $cards{$name}{simple_name} = $name;
        while(my ($key, $value) = each %char_trans) {
            $cards{$name}{simple_name} =~ s/$key/$value/g;
        }
        $cards{$name}{art_name} //= $name;
        $cards{$name}{price_name} //= $name;
        $cards{$name}{cost} = $card->{manaCost};
        $cards{$name}{type_line} = $card->{type};
        $cards{$name}{simple_type} = join " ", @{$card->{types}};
        if(defined $card->{power}) {
            $cards{$name}{size}  = $card->{power} . "/" . $card->{toughness};
        }
        $cards{$name}{text} = $card->{text};
        push @{$cards{$name}{set}}, [ $set_release, $set_name . " " . $card->{rarity} ];
        $cards{$name}{cmc}  = $card->{convertedManaCost};
        $cards{$name}{cid} = color_array_to_sorted_string($card->{colorIdentity}) if defined $card->{colorIdentity};
        $cards{$name}{color} = color_array_to_sorted_string($card->{colors}) if defined $card->{colors};
        $cards{$name}{color_sort} = color_sort_order($card);
        $cards{$name}{loyal} = $card->{loyalty};
        $cards{$name}{legal} = join ", ", map { $card->{legalities}->{$_} . " in " . $_ } keys %{$card->{legalities}};
        $cards{$name}{reserved} = 1 if defined $card->{isReserved};
        $cards{$name}{timeshifted} = 1 if defined $card->{isTimeshifted};
        if(defined $card->{colors} && @{$card->{colors}} && $card->{layout} ne "flip" && (color_array_to_sorted_string($card->{colors}) ne cost_to_colors($card->{manaCost}))) {
            push @{$cards{$name}{extras}}, join("/", @{$card->{colors}}) . " color indicator.";
        }
        if($card->{layout} eq "vanguard" && 0) {
            my $hand = $card->{hand};
            my $life = $card->{life};
            $hand = "+$hand" if $hand >= 0;
            $life = "+$life" if $life >= 0;
            $cards{$name}{text} = "$hand cards / $life life\n" . $cards{$name}{text};
        }
        if($set_name !~ /^World Championship Decks .*$/ && $set_name !~ /^.*Collectors' Edition$/) {
            $cards{$name}{price} = min($cards{$name}{price}, $prices{$card->{uuid}}{normal}, $prices{$card->{uuid}}{foil});
        }
        unless($tree->{$set_code}->{isOnlineOnly}) {
            my $set = $set_name;
            $set = $set_trans{$set} if $set_trans{$set};
            if($cards{$name}{simple_type} =~ /^(Scheme|Plane|Phenomenon)$/) {
                $cards{$name}{price_name} = "$name ($set)";
                $set = "Oversize Cards";
            }
            my $mid = $card->{identifiers}->{multiverseId};
            $mid = 0 unless defined $mid;
            my $jsonid = $card->{uuid};
            push @by_set, [ $name, $cards{$name}{price_name}, $set, $mid, $jsonid ];
        }
    }
}

print "inserting cards...\n";
my $dbh = get_db_handle();
my $sth = $dbh->prepare("INSERT OR REPLACE INTO cards (name, cmc, color, type, date, full_text, art_name, price_name, price, stale) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, 0)");
$dbh->do("BEGIN TRANSACTION");
$dbh->do("UPDATE cards SET stale = 1");
my $i = 0;
my $total = keys %cards;
for(sort keys %cards) {
    my %card = %{$cards{$_}};
    $card{text} //= "";
    if($card{extras}) {
        $card{extras} = [ uniq(@{$card{extras}}) ];
        $card{text} .= "\n" if $card{text};
        $card{text} .= "[" . join(" ", @{$card{extras}}) . "]";
    }
    $card{text} =~ s/\n/\n             /g;
    $card{text} =~ s/—/--/g;
    $card{type_line} =~ s/—/--/g;
    $card{cost} //= "";
    $card{cost} =~ s/\{([WUBRGXC\d]+)\}/$1/g;
    $card{text} =~ s/\{?(CHAOS)\}?/{$1}/g;
    $card{cmc} //= "";
    $card{color} //= "";
    $card{cid} //= "";
    # find the first printing that wasnt in a 'Special' set
    my $date = (sort map { $_->[0] } grep { $_->[1] !~ /((Prerelease Events|Media Inserts|Launch Parties|Arena League|Judge Gift Program|Friday Night Magic|Magic Player Rewards) Special|\bPromos\b)/ } @{$card{set}})[0];

    my $fulltext = "Name:        $card{name}\n";
    $fulltext .= "Name:        $card{simple_name}\n" if $card{name} ne $card{simple_name};
    $fulltext .= "Cost:        $card{cost}\n" unless $card{cost} eq "";
    $fulltext .= "CMC:         $card{cmc}\n";
    $fulltext .= "Color:       $card{color}\n";
    $fulltext .= "CID:         $card{cid}\n";
    $fulltext .= "Type:        $card{type_line}\n";
    $fulltext .= "Pow/Tgh:     $card{size}\n" if defined $card{size};
    $fulltext .= "Loyalty:     $card{loyal}\n" if defined $card{loyal};
    $fulltext .= "Rules Text:  $card{text}";
    $fulltext .= "\n";
    $fulltext .= "Set/Rarity:  " . join(", ", uniq map { $_->[1] } sort { $a->[0] cmp $b->[0] } @{$card{set}}) . "\n";
    $fulltext .= "Legality:    $card{legal}\n";
    $fulltext .= "Reserved:    True\n" if defined $card{reserved};
    $fulltext .= "Timeshifted: True\n" if defined $card{timeshifted};

    $sth->execute($card{name}, $card{cmc}, $card{color_sort}, $card{simple_type}, $date, $fulltext, $card{art_name}, $card{price_name}, $card{price});
    #printf "\r%d/%d %.1f%% ", ++$i, $total, $i/$total*100;
}
#print "\n";
$dbh->do("COMMIT");

print "inserting sets...\n";
$sth = $dbh->prepare("INSERT OR REPLACE INTO printings (card_name, price_name, set_name, mid, jsonid, price, fprice) VALUES (?, ?, ?, ?, ?, ?, ?)");
$dbh->do("BEGIN TRANSACTION");
$dbh->do("UPDATE printings SET stale = 1");
$sth->execute($_->[0], $_->[1], $_->[2], $_->[3], $_->[4], $prices{$_->[4]}{normal}, $prices{$_->[4]}{foil}) for @by_set;
$dbh->do("UPDATE printings SET stale = 0 WHERE card_name = ? AND set_name = ? AND mid = ?", {}, $_->[0], $_->[2], $_->[3]) for @by_set;
$dbh->do("COMMIT");

(my $stale) = $dbh->selectrow_array("SELECT count(*) FROM cards WHERE stale = 1");
print "deleted $stale stale card(s)\n" if $stale;
$dbh->do("DELETE FROM cards WHERE stale = 1");
($stale) = $dbh->selectrow_array("SELECT count(*) FROM printings WHERE stale = 1");
print "deleted $stale stale printing(s)\n" if $stale;
$dbh->do("DELETE FROM printings WHERE stale = 1");

$dbh->disconnect;

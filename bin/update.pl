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

# tweak this depending on where you want to store your data
my $url = "https://mtgjson.com/api/v5/AllPrintings.json.bz2";
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
    "\xC3\xA4" => "a",
    "\xC3\xB3" => "o",
    "\xC3\xB6" => "o",
    "\xC3\xBB" => "u",
    "\xC3\xA9" => "e",
    "\xC3\x89" => "E",
    "\xC2\xBD" => ".5",
    "\xC2\xAE" => "(R)",
    "\xC3\xAD" => "i",
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


my $num_cards = "0";

check_version();

print "downloading...\n";

my (%cards, @by_set);
my $quiet = "--quiet";
$quiet = "" if -t STDOUT;
my $blob = join "", `wget $quiet -O - "$url" | bzcat`;
#my $blob = join "", `bzcat local/AllPrintings.json.bz2`;
while(my ($key, $value) = each %char_trans) {
    $blob =~ s/$key/$value/g;
}
print "parsing...\n";
my $tree = decode_json($blob)->{data};
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
        $cards{$name}{cmc}  = $card->{convertedManaCost};
        $cards{$name}{cid} = color_array_to_sorted_string($card->{colorIdentity}) if defined $card->{colorIdentity};
        $cards{$name}{color} = color_array_to_sorted_string($card->{colors}) if defined $card->{colors};
        $cards{$name}{color_sort} = color_sort_order($card);
        $cards{$name}{loyal} = $card->{loyalty};
        $cards{$name}{extras} = undef;
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
        if(defined $card->{names}) { # this should be changed to $card->{otherFaceIds}
            if($card->{layout} eq "split" || $card->{layout} eq "aftermath") {
                push @{$cards{$name}{extras}}, "This is half of the split card " . join(" // ", @{$card->{names}}) . ".";
                $cards{$name}{art_name} = $cards{$name}{price_name} = join(" // ", @{$card->{names}});
            } elsif($card->{layout} eq "transform") {
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
                join(", ", grep { $_ ne $name } @{$card->{names}}) . "." if @{$card->{names}};
            }
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
            push @by_set, [ $name, $cards{$name}{price_name}, $set, $mid ];
        }
    }
}

print "inserting cards...\n";
my $dbh = get_db_handle();
my %card_names = map { $_ => 1 } @{$dbh->selectcol_arrayref("SELECT name FROM cards")};
my $insert = $dbh->prepare("INSERT INTO cards (name, cmc, color, type, date, full_text, art_name, price_name, stale) VALUES (?, ?, ?, ?, ?, ?, ?, ?, 0)");
my $update = $dbh->prepare("UPDATE cards SET name = ?, cmc = ?, color = ?, type = ?, date = ?, full_text = ?, art_name = ?, price_name = ?, stale = 0 WHERE name = ?");
$dbh->do("BEGIN TRANSACTION");
$dbh->do("UPDATE cards SET stale = 1");
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
    $card{color} //= "";
    $card{cid} //= "";
    # find the first printing that wasnt in a 'Special' set
    my $date = (sort map { $_->[0] } grep { $_->[1] !~ /((Prerelease Events|Media Inserts|Launch Parties|Arena League|Judge Gift Program|Friday Night Magic|Magic Player Rewards) Special|\bPromos\b)/ } @{$card{set}})[0];

    my $fulltext = "Name:        $card{name}\n";
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

    if($card_names{$_}) {
        $update->execute($card{name}, $card{cmc}, $card{color_sort}, $card{simple_type}, $date, $fulltext, $card{art_name}, $card{price_name}, $_);
    } else {
        $insert->execute($card{name}, $card{cmc}, $card{color_sort}, $card{simple_type}, $date, $fulltext, $card{art_name}, $card{price_name});
    }
    #printf "\r%d/%d %.1f%% ", ++$i, $total, $i/$total*100;
}
#print "\n";
$dbh->do("COMMIT");

print "inserting sets...\n";
my $sth = $dbh->prepare("INSERT OR IGNORE INTO printings (card_name, price_name, set_name, mid) VALUES (?, ?, ?, ?)");
$dbh->do("BEGIN TRANSACTION");
$dbh->do("UPDATE printings SET stale = 1");
$sth->execute($_->[0], $_->[1], $_->[2], $_->[3]) for @by_set;
$dbh->do("UPDATE printings SET stale = 0 WHERE card_name = ? AND set_name = ? AND mid = ?", {}, $_->[0], $_->[2], $_->[3]) for @by_set;
$dbh->do("COMMIT");

(my $stale) = $dbh->selectrow_array("SELECT count(*) FROM cards WHERE stale = 1");
print "deleted $stale stale card(s)\n" if $stale;
$dbh->do("DELETE FROM cards WHERE stale = 1");
($stale) = $dbh->selectrow_array("SELECT count(*) FROM printings WHERE stale = 1");
print "deleted $stale stale printing(s)\n" if $stale;
$dbh->do("DELETE FROM printings WHERE stale = 1");

$dbh->disconnect;

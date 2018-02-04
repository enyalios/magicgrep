#!/usr/bin/perl

use strict;
use warnings;
use CGI::Carp 'fatalsToBrowser';
use FindBin '$Bin';
use lib "$Bin/../lib";
use Magic;

my $header = generate_header("Help");

print <<EOF;
Content-Type: text/html

<!DOCTYPE html>
<html>
    <head>
        <title>Magic Card Search Help, Tips, & Tricks</title>
        <link rel="stylesheet" type="text/css" href="mystyle.css">
    </head>
    <body>
        $header
        <div class="main" style="max-width:640px;">
            <h2>Magic Card Search Help, Tips, & Tricks</h2>
            This website uses regular expressions to search for Magic Cards.  Regular expressions (or regexs) are a flexible, powerful way to match text.
            To learn more about regexes check out <a href="https://www.regular-expressions.info/quickstart.html">this guide</a>.
            All matching is case-insensitive.
            <br /><br />
            When searching, the text box is split apart on spaces into multiple patterns and returns only cards that match all patterns.
            <a class="code" href="index.cgi?q=fire elemental">fire elemental</a> returns cards that have both 'fire' and 'elemental' in their text.
            To find cards that have either 'fire' or elemental use the pattern <a class="code" href="index.cgi?q=(fire|elemental)">(fire|elemental)</a>.
            <br /><br />
            If your pattern has a space in it use single or double quotes to keep to from getting split up.
            <a class="code" href='index.cgi?q="fire elemental"'>"fire elemental"</a> finds cards with the exact string 'fire elemental' in them.
            <br /><br />
            You can negate a regular expression by prefacing it with an exclamation point.
            <a class="code" href="index.cgi?q=!fire elemental">!fire elemental</a> finds cards that mention word 'elemental', but not 'fire'.
            <br /><br />
            To search for a word only in the name of a card use something like <a class="code" href="index.cgi?q=^name:.*fire">^name:.*fire</a>.
            This can be used to search for cards with specific names, card types, rarity, cost, etc...
            <br /><br />
            In expressions, ~ is expanded to the name of the card.
            To find legendary dragons with ETB triggers, try <a class="code" href="index.cgi?q=^type.*legendary.*dragon 'when ~ enters the battlefield'">^type.*legendary.*dragon 'when ~ enters the battlefield'</a>.
            <br /><br />
            Due to technical reasons, you can't match against the price field, but there are some hidden fields that you can match against.
            'CMC' has a card's converted mana cost, 'CID' is its color identity (used for the <a href="http://mtgcommander.net">commander format</a>), and 'Legality' is its status in each format.
            <a class="code" href="index.cgi?q='^cmc: *10\$' ^cid:.*g">'^cmc: *10\$' ^cid:.*g</a> searches for 10 mana cards with green in their color identity.
            <br /><br />
            To find cards to go in your white and black commander deck try searching for something like <a class="code" href="index.cgi?q='^cid%3A *[wb]*%24' 'legal in commander'">'^cid: *[wb]*\$' 'legal in commander'</a>.
            This will match cards with white, black, white-black, and colorless color identities.
            <br /><br />
            To search for a word only in the rules text but not in other fields, use a pattern like <a class="code" href="index.cgi?q='^(rules text:)? .*cipher'">'^(rules text:)? .*cipher'</a>.
            This looks for the word 'cipher' when it's on a line that started with 'rules text:' or a space (only rules text lines can start with a space).
            <br /><br />
            These patterns can be combined into arbitrarily complex searches like: <a class="code" style="white-space:normal;" href="index.cgi?q=^type.*(merfolk|elf) !type.*legendary '(\\bother (elf|merfolk)|tap.*untapped)' cmc.*[2-4]">^type.*(merfolk|elf) !type.*legendary '(\\bother (elf|merfolk)|tap.*untapped)' cmc.*[2-4]</a>.
            This searches for non-legendary merfolk and elves, that cost between 2 and 4 mana, and mention 'other merfolk', 'other elf', or tapping untapped things.
            <br /><br />
            The enter selects and deselects the search field.
            This is really useful so that you can search, press enter and start scrolling through the results with the arrow keys or page up/page down.
            When you want to refine your search, press enter and start typing to change the search parameters.
            If you are typing in a search and change your mind and want to start over, press enter twice to highlight the whole field and start typing to replace it all with a new query.
            <br /><br />
            You can get a copy/pasteable card list from the Stats tab for easy pasting into TCGplayer or other purchase website.
        </div>
    </body>
</html>
EOF

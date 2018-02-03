package Magic;
use strict;
use warnings;
use DBI;

use Exporter qw(import);

our @EXPORT = qw(connect_to_db generate_header);
our @EXPORT_OK = qw(get_fields match_against_list tilde_expand);
our %EXPORT_TAGS = ( # export as a group
    all => [qw(connect_to_db get_fields match_against_list generate_header tilde_expand)],
);

sub connect_to_db {
    (my $path = __FILE__) =~ s/[^\/]*$//;
    my $dbh = DBI->connect("dbi:SQLite:dbname=$path/../db/magic.db","","") or die;
	return $dbh;
}

sub get_field {
    if($_[0] =~ /^(['"])/) {
        $_[0] =~ s/^$1(.*?)($1|$)\s*//;
        return $1;
    } else {
        $_[0] =~ s/^(.*?)($|\s+)//;
        return $1;  
    }
}

sub get_fields {
    my $string = $_[0];
    my @fields = ();                                                                                                                                                                                                        
    push @fields, get_field($string) while length $string;                                                                                                                  
    return @fields;
}

sub tilde_expand {
    for(@_) {
        if(index($_, "~") != -1) {
            s/~/(\\1|\\2)/g;
            $_ = "^Name: *+(([^,\\n]*+).*)\$[\\s\\S]*" . $_;
        }
    }
}

sub match_against_list {
	(my $string, my $list) = @_;

	for my $arg (@{$list}) {
        if ((my $regex = $arg) =~ s/^!//) {
            # invert matches for regexs that start with a '!'
            return 0 if $string =~ /$regex/im;
        } else {
            # otherwise just match normally
            return 0 unless $string =~ /$regex/im;
        }
    }

    return 1;
}

sub generate_header {
    my $page = $_[0];
	my $items = [
		[ "Search" => "index.cgi" ],
		[ "Stats"  => "stats.cgi" ],
		[ "Bulk"   => "bulk.cgi"  ],
        [ "Lists"  => "lists.cgi" ],
        [ "Help"   => "help.cgi"  ],
    ];
    # only print the stats tab on the stats page
    # (its hardcoded on the search page)
    $items = [ grep { $page eq "Stats" || $_->[0] ne "Stats" } @$items ];

    my $string = "<div class=\"header3\">\n<span class=\"spacer\"></span>\n";
    for(@$items) {
        my $color = "orange";
        my $link = "href=\"$_->[1]\"";
        if($_->[0] eq $page) {
            $color = "white";
            $link = "";
        }
        $string .= "[ <a $link class=\"$color\">$_->[0]</a> ]\n";
    }
    $string .= "</div>\n";

    return $string;
}

1;

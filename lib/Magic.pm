package Magic;
use strict;
use warnings;
use DBI;
use CGI 'cookie';

use Exporter qw(import);

our @EXPORT = qw(get_db_handle generate_header image_handler);
our @EXPORT_OK = qw(get_fields match_against_list tilde_expand get_username);
our %EXPORT_TAGS = ( # export as a group
    all => [qw(get_db_handle get_fields match_against_list generate_header tilde_expand get_username image_handler)],
);

(my $path = __FILE__) =~ s/[^\/]*$//;
my $dbh = DBI->connect("dbi:SQLite:dbname=$path/../db/magic.db","","") or die;

sub get_db_handle {
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
    my $username = get_username();
    if(defined $username) {
        push @{$items}, [ "Logout", "logout.cgi" ];
    } else {
        push @{$items}, [ "Login", "secure/login.cgi" ];
    }
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

sub get_username {
    my $key = cookie('key');
    return undef unless defined $key;

    my $ref = $dbh->selectcol_arrayref("SELECT username FROM users WHERE key = ?", {}, $key);
    return undef if @{$ref} != 1;
    return $ref->[0];
}

sub image_handler {
    return "http://gatherer.wizards.com/Handlers/Image.ashx";
}

1;

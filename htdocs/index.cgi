#!/usr/bin/perl

use strict;
use warnings;
use CGI::Carp 'fatalsToBrowser';
use CGI 'param';
use URI::Escape;
use FindBin '$Bin';
use lib "$Bin/../lib";
use Magic 'get_username';

my @sort_options = qw"Name CMC Color Date Price Type";

sub js_safe {
    my $string = $_[0];
    $string =~ s/\\/\\\\/g;
    $string =~ s/'/\\'/g;
    return $string;
}

sub html_safe {
    my $string = $_[0];
    $string =~ s/&/\&amp;/g;
    $string =~ s/'/\&apos;/g;
    $string =~ s/</\&lt;/g;
    $string =~ s/>/\&gt;/g;
    return $string;
}

sub safe_backticks {
    my $string;
    die "Can't fork: $!" unless defined(my $pid = open(KID, "-|"));
    if($pid) { # parent
        $string = join "", <KID>;
        close KID;
    } else {
        exec { $_[0] } @_ or die "can't exec '@_': $!";
    }
    return $string;
}

my $q = param("q") // "";
my $sort = param("sort") // "name";
my $js_safe_q = js_safe($q);
my $html_safe_q = html_safe($q);
my $content = "";
my $autofocus = " autofocus";
my $title = "Magic Smart Search";
if(length $q) {
    $content = safe_backticks("./search.cgi");
    $autofocus = "";
    $title = $html_safe_q;
}
my $sort_string = join "\n                        ", map {
    sprintf "<option value='%s'%s>%s</option>",
    lc $_,
    lc $_ eq $sort ? " selected='selected'" : "",
    $_;
} @sort_options;
my $login = defined get_username() ? '<a href="logout.cgi" class="orange">Logout</a>' : '<a href="secure/login.cgi" class="orange">Login</a>';

print <<EOF;
Content-Type: text/html

<!DOCTYPE html>
<html>
    <head>
        <meta charset="UTF-8">
        <meta name="viewport" content="width=device-width, initial-scale=1, user-scalable=yes">
        <title>$title</title>
        <link rel="stylesheet" type="text/css" href="mystyle.css">
        <script>
            var last_search = "";
            var last_update = 0;

            function update() {
                // return immediately if the search string hasnt changed
                var q = encodeURIComponent(document.getElementById("q").value);
                var sort = document.getElementById("sort").value;
                if(sort == "name") {
                    sort = "";
                } else {
                    sort = "sort=" + sort + "&";
                }
                var query_string = "?" + sort + "q=" + q
                if(last_search == query_string) return;
                last_search = query_string;

                // update the url
                var newurl = window.location.protocol + "//" + window.location.host + window.location.pathname + query_string;
                var epoch = new Date() / 1000;
                if(epoch - last_update > 3) {
                    window.history.pushState({path:newurl}, '', newurl);
                } else {
                    window.history.replaceState({path:newurl}, '', newurl);
                }
                last_update = epoch;

                // change the page title
                document.title = document.getElementById("q").value;

                // return if the search string is too short
                var content = document.getElementById("content");
                if(q.length < 4) { 
                    content.innerHTML = "";
                    return;
                }

                // otherwise do a search
                document.getElementById("status").style.display = "block";
                if(content.innerHTML == "") {
                    content.innerHTML = "<div class='header2'></div>";
                }
                var xmlhttp = new XMLHttpRequest();
                xmlhttp.onreadystatechange = function() {
                    if(xmlhttp.readyState == 4) {
                        document.getElementById("status").style.display = "none";
                        content.innerHTML = xmlhttp.responseText;
                    }
                }
                xmlhttp.open("GET", "search.cgi" + query_string, true);
                xmlhttp.send();
            }

            function price(obj, name) {
                obj.innerHTML = "Loading...";
                var xmlhttp = new XMLHttpRequest();
                xmlhttp.onreadystatechange = function() {
                    if(xmlhttp.readyState == 4) {
                        obj.innerHTML = xmlhttp.responseText;
                    }
                }
                xmlhttp.open("GET", "price.cgi?q="+name, true);
                xmlhttp.send();
            }

            function stats() {
                var q = encodeURIComponent(document.getElementById("q").value);
                var sort = encodeURIComponent(document.getElementById("sort").value);
                window.location.assign("stats.cgi?q=" + q + "&sort=" + sort);
            }
            
            window.addEventListener('popstate', function(event) {
                window.location.href = window.location.href;
            }, false);
            
            window.addEventListener('keydown', function(event) {
                if(event.which == 13 || event.keyCode == 13) {
                    var elem = document.getElementById("q");
                    if(elem == document.activeElement) {
                        elem.blur()
                    } else {
                        elem.select()
                    }
                }
            }, false);
        </script>
    </head>
    <body style="overflow-y:scroll;">
        <div class="wrapper">
            <div class="header1">
                <form onSubmit="return false;">
                    <div class="spacer2">&nbsp;</div>
                    <div class="tabs">
                        [ <a href="javascript:stats()" class="orange">Stats</a> ]
                        [ <a href="bulk.cgi" class="orange">Bulk</a> ]
                        [ <a href="lists.cgi" class="orange">Lists</a> ]
                        [ <a href="help.cgi" class="orange">Help</a> ]
                        [ $login ]
                    </div>
                    <select name="sort" onchange="update();this.blur()" id="sort">
                        $sort_string
                    </select>
                    <span class="search"><input type="text" name="q" id="q" placeholder="Card Query" onkeyup="update()" value='$html_safe_q' autocomplete="off"$autofocus></span>
                </form>
            </div>
            <div id="content">$content</div>
            <span id="status"><img height='71px' width='71px' src='spin_large.gif'></span>
        </div>
    </body>
</html>
EOF

#!/usr/bin/perl

use strict;
use warnings;
use CGI::Carp 'fatalsToBrowser';
use UUID::Tiny ':std';
use CGI ':standard';
use FindBin '$Bin';
use lib "$Bin/../../lib";
use Magic;

my $dbh = get_db_handle();

sub print_form {
    my $error = $_[0] // "";
    $error = "<div class=\"alert\">$error</div><br />" if $error ne "";
    print <<EOF;
Content-Type: text/html

<!DOCTYPE html>
<html>
    <head>
        <link rel="stylesheet" type="text/css" href="../mystyle.css">
    </head>
    <body style="background:#ddd;">
        <form method="get">
            <div class="small-window">
                $error
                <div>Please choose a username:</div>
                <input type="text" name="username" placeholder="Username" autofocus>
                <br /><br />
                <button type="submit" class="button">Submit</button>
            </div>
        </form>
    </body>
</html>
EOF
    exit;
}

sub username_exists {
    return scalar @{$dbh->selectcol_arrayref("SELECT id FROM users WHERE username = ?", {}, $_[0])};
}


my $oauth_account = $ENV{REMOTE_USER};
my $ref = $dbh->selectcol_arrayref("SELECT key FROM users WHERE oauth_account = ?", {}, $oauth_account);
my $key;
my $one_week = 7*24*60*60; # one week in seconds

if(@{$ref} == 0) {
    # user not in the database
    # request a username, create a new uuid, and update the db
    my $username = param('username') // "";
    print_form() if $username eq "";
    print_form("Invalid username.  Usernames must be at least 3 characters long and only contain letters, numbers, and underscores.") unless $username =~ /^\w{3,}$/;
    print_form("The username '$username' is already taken.") if username_exists($username);

    while(1) {
        $key = create_uuid_as_string(UUID_RANDOM);
        last if @{$dbh->selectcol_arrayref("SELECT key FROM users WHERE key = ?", {}, $key)} == 0;
    }

    $dbh->do("INSERT INTO users (username, oauth_account, key) VALUES (?, ?, ?)", {}, $username, $oauth_account, $key);
} else {
    # user is in the db, just set the key
    $key = $ref->[0];
}

# TODO redirect to value of ?r= or something
print <<EOF;
Set-Cookie: key=$key; Max-Age=$one_week; Path=/; HttpOnly
Status: 307
Location: /

EOF

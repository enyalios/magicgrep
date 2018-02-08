#!/usr/bin/perl

use strict;
use warnings;
use CGI::Carp 'fatalsToBrowser';

print <<EOF;
Set-Cookie: key=; Max-Age=-1; Path=/; HttpOnly
Status: 307
Location: /secure/redirect_uri?logout=http%3A%2F%2Fmagic.enyalios.net%2F

EOF

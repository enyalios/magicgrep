#!/bin/bash

# this script caches the price of the 1/7 least recently updated cards in the db
# run everyday it will cache prices for everything over the course of a week

# kill other runs of this script
pgrep -f ${BASH_SOURCE[0]} | grep -v $$ | xargs -r kill
cd `dirname $0`/..
echo 'select distinct price_name from cards order by price_updated limit (select count(distinct price_name) / 7 from cards);' \
    | sqlite3 db/magic.db \
    | shuf \
    | perl -MURI::Escape -lne 'print uri_escape($_)' \
    | while read i; do ./htdocs/price.cgi q=$i; done

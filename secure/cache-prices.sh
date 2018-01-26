#!/bin/bash

# this script caches the price of the 1/7 least recently updated cards in the db
# run everyday it will cache prices for everything over the course of a week

cd `dirname $0`/..
echo 'select distinct price_name from cards order by price_updated limit (select count(distinct price_name) / 7 from cards)' \
    | sqlite3 secure/magic.db \
    | shuf \
    | perl -MURI::Escape -lne 'print uri_escape($_)' \
    | while read i; do ./price.cgi q=$i; done

#! /usr/bin/env bash
find data/ -name *.json | while read FILE; do cat $FILE | sed -n 's/"name"\s*:\s*"\(.*\)",*$/\1/p' | sed -n 's/\s*//p'  >> strings.txt; done
find data/ -name *.json | while read FILE; do cat $FILE | sed -n 's/"userMessage"\s*:\s*"\(.*\)",/\1/p' | sed -n 's/\s*//p' >> strings.txt; done
sort -u strings.txt | while read STR; do printf "i18nc(\"technical term, do you have a musician friend?\", \"$STR\")\n" >> rc.cpp; done
$XGETTEXT `find . -name \*.cpp -o -name \*.qml` -o $podir/minuet.pot
rm -f strings.txt

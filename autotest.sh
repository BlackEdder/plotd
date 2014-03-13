#!/bin/bash
# Immediately run once
dub test

trap "dub test" INT

function watch_tests() {
while : 
do
	#file=`inotifywait -q -e CREATE bin/ --format %f`
	file=`inotifywait -q -e ATTRIB src/plotd/ --format %f`
	sleep 1
	dub test
done
}

watch_tests

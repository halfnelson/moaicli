#!/usr/bin/env bash
ROOT=`dirname $0`

java  -XX:+TieredCompilation -XX:TieredStopAtLevel=1 -Djruby.compile.mode=OFF -jar $ROOT/lib/java/jruby-complete.jar $ROOT/src/moaicli.rb $*

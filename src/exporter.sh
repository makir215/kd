#!/bin/bash
echo "require './lib.includes.coffee'"
echo "require './core/utils.coffee'"
echo "KD = require './core/kd.coffee'"
echo "KD.classes = {}"

grep "module.exports\s*=\s*class " * -R | awk -F':' '{ print $1,$2 }' | awk '{ print "KD.classes."$5,"= require \"./"$1"\" " }'

echo "KD = require './core/kd.coffee'"
echo "KD.exportKDFramework()"
echo "console.timeEnd 'Framework loaded'"

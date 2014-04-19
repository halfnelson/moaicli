#!/usr/bin/env bash
echo "building linux"
cd ..
rake rawr:clean
rake rawr:jar
mkdir package/linux
cp -R package/jar/* package/linux
cp -R config package/linux/config
cp -R hosts package/linux/hosts
cp -R templates package/linux/templates
cp dist/linux/moaicli package/linux/moaicli
chmod a+X package/linux/moaicli

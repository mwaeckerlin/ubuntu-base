#!/bin/bash

git checkout master
git pull
for i in jammy noble; do
    git checkout $i 2>/dev/null || git checkout -b $i
    git pull origin $i
    git reset --hard origin/master
    sed -i 's/ARG VERSION="latest.*"/ARG VERSION="'$i'"/g' Dockerfile
    date > rebuilt
    git add .
    git commit -m "Update to latest-$i"
    git push -f origin $i
done
git checkout master
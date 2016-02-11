#!/bin/bash

set -e -o pipefail

dub test --compiler=${DC}
dub test -c unittest-gtk --compiler=${DC}

if [[ $TRAVIS_BRANCH == 'master' ]] ; then
    if [ ! -z "$GH_TOKEN" ]; then
        git checkout master
        dub build -b release --compiler=${DC}
        bin/plotcli < examples/1/data.txt
        bin/plotcli < examples/2/data.txt
        bin/plotcli < examples/3/data.txt
        bin/plotcli < examples/4/data.txt
        bin/plotcli < examples/5/data.txt
        dub build -b docs --compiler=${DC}
        cd docs
        mkdir images
        #cp ../*.{png,svg,pdf} images/
        cp ../*.png images/
        bin/plotcli --help > images/help.txt
        git init
        git config user.name "Travis-CI"
        git config user.email "travis@nodemeatspace.com"
        git add .
        git commit -m "Deployed to Github Pages"
        #git push --force --quiet "https://${GH_TOKEN}@github.com/${TRAVIS_REPO_SLUG}" HEAD:gh-pages > /dev/null 2>&1
        git push --force --quiet "https://${GH_TOKEN}@github.com/${TRAVIS_REPO_SLUG}" master:gh-pages > /dev/null 2>&1
        #git push --force "https://${GH_TOKEN}@github.com/${TRAVIS_REPO_SLUG}" HEAD:gh-pages
    fi
fi

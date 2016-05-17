#!/bin/bash

set -e -o pipefail

BM="--build-mode=singleFile"

if [[ "$DC" == "ldc2" ]]; then 
    BM="--build-mode=separate"
fi

dub test --compiler=${DC} ${BM}
dub test -c unittest-gtk --compiler=${DC} ${BM}

if [[ $TRAVIS_BRANCH == 'master' ]] ; then
    if [ ! -z "$GH_TOKEN" ]; then
        git checkout master
        dub build -b release --compiler=${DC} ${BM}
        bin/plotcli < examples/1/data.txt
        bin/plotcli < examples/2/data.txt
        bin/plotcli < examples/3/data.txt
        bin/plotcli < examples/4/data.txt
        bin/plotcli < examples/5/data.txt
        dub build -b docs --compiler=${DC} ${BM}
        cd docs
        mkdir images
        #cp ../*.{png,svg,pdf} images/
        cp ../*.png images/
        ../bin/plotcli --help > images/help.txt
        git init
        git config user.name "Travis-CI"
        git config user.email "travis@nodemeatspace.com"
        git add .
        git commit -m "Deployed to Github Pages"
        #git push --force --quiet "https://${GH_TOKEN}@github.com/${TRAVIS_REPO_SLUG}" HEAD:gh-pages > /dev/null 2>&1
        git push --force --quiet "https://${GH_TOKEN}@github.com/${TRAVIS_REPO_SLUG}" master:gh-pages > /dev/null 2>&1
        #git push --force "https://${GH_TOKEN}@github.com/${TRAVIS_REPO_SLUG}" HEAD:gh-pages
        cd ..
    fi
fi

if [ -n "$TRAVIS_TAG" ]; then
    git checkout $TRAVIS_TAG
    if [[ "$TRAVIS_OS_NAME" == "osx" ]]; then 
        dub build --compiler=$DC -b release ${BM}
        strip bin/plotcli
        tar -czf plotcli-osx.tar.gz -C bin/ plotcli
        dub build --compiler=$DC -b release -c plotcli-gtk ${BM}
        strip bin/plotcli
        tar -czf plotcli-osx-gtk.tar.gz -C bin/ plotcli
    fi
    if [[ "$TRAVIS_OS_NAME" == "linux" && "$DC" == "ldc2" ]]; then 
        dub build --compiler=$DC -b release ${BM}
        strip bin/plotcli
        tar caf plotcli-linux.tar.gz -C bin/ plotcli
        dub build --compiler=$DC -b release -c plotcli-gtk ${BM}
        strip bin/plotcli
        tar caf plotcli-linux-gtk.tar.gz -C bin/ plotcli
    fi
fi

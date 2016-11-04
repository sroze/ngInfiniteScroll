#!/usr/bin/env bash
set -e # Exit with nonzero exit code if anything fails

SOURCE_BRANCH="master"
TARGET_BRANCH="master"

# Run only test cases if this is not a release
if [ -z "$TRAVIS_TAG" ]; then
    exit 0
fi

# Get the deploy key by using Travis's stored variables to decrypt deploy_key.enc
ENCRYPTED_KEY_VAR="encrypted_${ENCRYPTION_LABEL}_key"
ENCRYPTED_IV_VAR="encrypted_${ENCRYPTION_LABEL}_iv"
ENCRYPTED_KEY=${!ENCRYPTED_KEY_VAR}
ENCRYPTED_IV=${!ENCRYPTED_IV_VAR}
openssl aes-256-cbc -K $ENCRYPTED_KEY -iv $ENCRYPTED_IV -in id_rsa_nginfinite.enc -out deploy_key -d
chmod 600 deploy_key
eval `ssh-agent -s`
ssh-add deploy_key

BOWER_REPO='git@github.com:ng-infinite-scroll/ng-infinite-scroll-bower.git'

BOWER_REPO_DIR='out'
CWD="$PWD"

git clone $BOWER_REPO $BOWER_REPO_DIR
cd $BOWER_REPO_DIR
git checkout $TARGET_BRANCH || git checkout -b $TARGET_BRANCH

git config user.name "Travis CI"
git config user.email "$COMMIT_AUTHOR_EMAIL"

# Copy all build content to the bower repo
cp -r ../build .
cp ../inert-bower.json bower.json
cp ../LICENSE LICENSE

git add build
git add bower.json

git commit -am "Release version $TRAVIS_TAG"
git tag -d "$TRAVIS_TAG" || true
git tag "$TRAVIS_TAG"
git push origin -f $TARGET_BRANCH $TRAVIS_TAG

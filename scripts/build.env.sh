#!/bin/bash

##############################################################
##                      GLOBAL ENV VARS                     ##
##############################################################

export GIT_TAG=$(git describe --abbrev=0 --tags 2> /dev/null)
export GIT_BRANCH=$(basename $(git branch -r --contains HEAD))
export GIT_COMMIT=$(git rev-parse --short HEAD)
export GIT_COMMIT_SHORT=$(git rev-parse HEAD)

if [ -z $GIT_TAG ]
then 
    export BASE_VERSION="1.0.0";
else 
    export BASE_VERSION=$GIT_TAG
fi

if [ "$GIT_BRANCH" = "main" ]
then 
    export VERSION="v"$BASE_VERSION
else 
    export VERSION=$BASE_VERSION"-SNAPSHOT"
fi

export DOCKER_IMAGE="pjgg/osin:$VERSION"

# Check if can run docker without sudo
docker ps > /dev/null
if [ $? -eq 0 ]; then
    export DOCKER="docker"
else
    export DOCKER="sudo docker"
fi
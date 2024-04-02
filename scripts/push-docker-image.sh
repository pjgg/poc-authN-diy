#!/bin/bash 

source scripts/build.env.sh

echo $DOCKER_PASSWORD | docker login -u $DOCKER_USERNAME --password-stdin

$DOCKER push $DOCKER_IMAGE
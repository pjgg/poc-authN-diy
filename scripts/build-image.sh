#!/bin/bash -x

source scripts/build.env.sh

$DOCKER build --no-cache -t $DOCKER_IMAGE .
#!/bin/sh

set -e

container_name=$(basename $(pwd) | sed -e 's/torial-//' -e 's/$/-step-ca/')

if docker ps | grep $container_name > /dev/null 2>&1 ; then
    docker exec -it $container_name bash
else
    echo "Container [$container] not found"
fi
#! /usr/bin/bash

distrofolder="${1:-arch}"

echo "!! Building $distrofolder toolbox image"
podman build --tag $USER/$distrofolder ./$distrofolder
echo "!! Creating $USER/$distrofolder toolbox container"

toolbox create --image $USER/$distrofolder $distrofolder

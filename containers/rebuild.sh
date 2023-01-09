#! /usr/bin/bash

distrofolder="${1:-arch}"

toolbox rm -f $distrofolder;
podman rmi $USER/$distrofolder;
./build.sh $distrofolder;
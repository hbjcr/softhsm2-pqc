#!/bin/bash

# Include the color script
source ./src/dialogs.sh
source ./src/spinner.sh

title "SoftHSM2 Setup"

image_repo=${DOCKER_FINAL_IMAGE_REPO:-hbjcr/softhsm2-pqc:latest}

subtitle "Installing pre-requisites"

install_packages_silent "qemu-user-static"

run_step "Starting container binfmt" -- \
  docker run --privileged --rm \
    tonistiigi/binfmt \
    --install all

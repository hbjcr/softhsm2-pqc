#!/bin/bash
export SCRIPT_DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/src

# Output image properties
export FINAL_IMAGE_REPO='hbjcr/softhsm2-pqc:latest'

# Build properties
export BASE_IMAGE='alpine:latest'
export SOFTHSM_SOURCE_REPO='https://github.com/antoinelochet/SoftHSMv2.git'
export SOFTHSM_SOURCE_REPO_BRANCH='ml-kem'

#./01.prerequisites.sh

./02.buildimages.sh
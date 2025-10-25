#!/bin/bash

# Include the color script
source ./src/dialogs.sh
source ./src/spinner.sh

# Build properties
base_image=${BASE_IMAGE:-alpine:latest}
git_repo=${GIT_REPO:-https://github.com/antoinelochet/SoftHSMv2.git}
git_branch=${GIT_BRANCH:-ml-kem}
platforms="linux/386,linux/amd64,linux/arm/v6,linux/arm/v7,linux/arm64/v8,linux/ppc64le,linux/riscv64,linux/s390x,linux/arm64"
#platforms="linux/amd64"
dockerfile="softhsm.Dockerfile"
builder_name="SoftHSM2builder"

# Output image properties
image_repo=${FINAL_IMAGE_REPO:-hbjcr/softhsm2-pqc:latest}
declare -A image_meta=(
  [authors]="Hector Bejarano"
  [title]="$image_repo"
  [description]="SoftHSM2 with PQC"
  [source]="https://github.com/antoinelochet/SoftHSMv2/tree/ml-dsa-pr"
  [revision]="1"
  [version]="2"
  [created]="$(date -u +'%Y-%m-%dT%H:%M:%SZ')"
)

subtitle "Building images"

run_step "Docker Login" -- \
  docker login

if ! run_step "Remove any previous builder instance" -- \
  docker buildx rm "$builder_name"; then
  warning_box "Builder '$builder_name' could not be removed — continuing..."
fi

    #--driver-opt env.http_proxy=http://proxy-chain.intel.com:911 \
    #--driver-opt env.https_proxy=http://proxy-chain.intel.com:912 \
run_step "Create builder instance" -- \
  docker buildx create --use --name "$builder_name" \
    --driver docker-container 

run_step "Inspecting bootstrap" -- \
  docker buildx inspect --bootstrap

build_opts=(
  --file "images/$dockerfile"
  --builder "$builder_name"
  --progress=plain
  --tag="$image_repo"
  --pull
  # using the current date as value for BASE_LAYER_CACHE_KEY, i.e. the base layer cache (that holds system packages with security updates) will be invalidate once per day
  --build-arg BASE_IMAGE="$base_image"
  --build-arg GIT_REPO="$git_repo"
  --build-arg GIT_BRANCH="$git_branch"
  --platform "$platforms"
  --sbom=true  # https://docs.docker.com/build/metadata/attestations/sbom/#create-sbom-attestations
  --push
  #--output=type=docker
  #--output "type=registry,name=${LOCAL_REGISTRY}/${image_repo},registry.http=true,registry.insecure=true")
)

for key in "${!image_meta[@]}"; do
  build_opts+=(--build-arg "OCI_${key}=${image_meta[$key]}")
  build_opts+=(--annotation "index:org.opencontainers.image.${key}=${image_meta[$key]}")
done

run_step "Building docker image [$image_repo]..." -- \
  docker buildx build "${build_opts[@]}" .

run_step "Inspecting image [$image_repo]..." -- \
  docker buildx imagetools inspect "$image_repo"

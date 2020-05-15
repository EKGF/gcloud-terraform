#!/usr/bin/env bash

./localbuild.sh || exit $?

echo TF_VAR_project-name="${TF_VAR_project-name}" > env.vars
echo TF_VAR_region="${TF_VAR_region}" >> env.vars
echo _BUCKET="${_BUCKET}" >> env.vars
echo _INFRA_DIR="${_INFRA_DIR}" >> env.vars
echo  GCLOUD_SERVICE_KEY="whatever" >> env.vars

local_workdir=$(pwd)

docker run \
  --env-file env.vars \
  --interactive --tty --rm \
  --mount type=bind,source=${local_workdir},target=/workdir \
  --workdir="/workdir" \
  "$(< .image-id)" "$@"
exit $?

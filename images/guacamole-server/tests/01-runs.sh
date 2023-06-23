#!/usr/bin/env bash

set -o errexit -o nounset -o errtrace -o pipefail -x

if [[ "${IMAGE_NAME}" == "" ]]; then
    echo "Must set IMAGE_NAME environment variable. Exiting."
    exit 1
fi

# The image needs to be in a cluster to run, so we'll look for the right error message.
set +o pipefail
docker run --rm "${IMAGE_NAME}" 2>&1 | grep "Guacamole proxy daemon (guacd) version 1.5.2 started"

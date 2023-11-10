ARCH ?= $(shell uname -m)
ifeq (${ARCH}, arm64)
	ARCH = aarch64
else ifeq (${ARCH}, amd64)
	ARCH = x86_64
endif
TARGETDIR = packages/${ARCH}

MELANGE ?= $(shell which melange)
WOLFICTL ?= $(shell which wolfictl)
KEY ?= local-melange-enterprise.rsa
REPO ?= $(shell pwd)/packages

MELANGE_OPTS += --repository-append ${REPO}
MELANGE_OPTS += --keyring-append ${KEY}.pub
MELANGE_OPTS += --repository-append https://packages.wolfi.dev/os
MELANGE_OPTS += --keyring-append https://packages.wolfi.dev/os/wolfi-signing.rsa.pub
MELANGE_OPTS += --signing-key ${KEY}
MELANGE_OPTS += --pipeline-dir ./pipelines/
MELANGE_OPTS += --arch ${ARCH}
MELANGE_OPTS += --env-file build-${ARCH}.env
MELANGE_OPTS += --namespace chainguard
MELANGE_OPTS += ${MELANGE_EXTRA_OPTS}

# The list of packages to be built. The order matters.
# wolfictl determines the list and order
# set only to be called when needed, so make can be instant to run
# when it is not
PKGLISTCMD ?= $(WOLFICTL) text --dir . --type name

all: ${KEY} .build-packages

# this ensures two things:
# 1. We only generate the graph for the list of commands that requires it
# 2. If generating the graph fails, we error out; without this, a failure in $(shell) might go unnoticed.
ifneq ($(findstring $(MAKECMDGOALS),all list list-yaml),)
  PKGNAMES := $(shell $(PKGLISTCMD) || echo "failed")
  ifeq ($(PKGNAMES),failed)
    $(error $(PKGLISTCMD) failed)
  endif
  PKGLIST := $(addprefix package/,$(PKGNAMES))
else
  PKGLIST :=
endif
.build-packages: $(PKGLIST)

${KEY}:
	${MELANGE} keygen ${KEY}

clean:
	rm -rf packages/${ARCH}

.PHONY: list list-yaml

list:
	$(info $(PKGNAMES))
	@printf ''

list-yaml:
	$(info $(addsuffix .yaml,$(PKGNAMES)))
	@printf ''

package/%:
	$(eval yamlfile := $*.yaml)
	$(eval pkgver := $(shell $(MELANGE) package-version $(yamlfile)))
	$(MAKE) yamlfile=$(yamlfile) pkgname=$* packages/$(ARCH)/$(pkgver).apk

packages/$(ARCH)/%.apk: $(KEY)
	@mkdir -p ./$(pkgname)/
	$(eval SOURCE_DATE_EPOCH ?= $(shell git log -1 --pretty=%ct --follow $(yamlfile)))
	@SOURCE_DATE_EPOCH=$(SOURCE_DATE_EPOCH) $(MELANGE) build $(yamlfile) $(MELANGE_OPTS) --source-dir ./$(pkgname)/ --log-policy builtin:stderr,$(TARGETDIR)/buildlogs/$*.log

dev-container:
	docker run --privileged --rm -it \
			-v "${PWD}:${PWD}" \
			-v "${HOME}/.cache/wolfictl/dev-container-enterprise/root:/root" \
			-w "${PWD}" \
			ghcr.io/wolfi-dev/sdk:latest@sha256:954e0b8b77c9cbe82792c321787f5b73ab5765ee887df921a13778c9c0d30714


# The next two targets are mostly copies from the local-wolfi and
# dev-container-wolfi targets from wolfi-dev/os:
# https://github.com/wolfi-dev/os/blob/main/Makefile

PACKAGES_CONTAINER_FOLDER ?= /work/packages
TMP_REPOSITORIES_DIR := $(shell mktemp -d)
TMP_REPOSITORIES_FILE := $(TMP_REPOSITORIES_DIR)/repositories
# This target spins up a docker container that is helpful for testing local
# changes to the packages. It mounts the local packages folder as a read-only,
# and sets up the necessary keys for you to run `apk add` commands, and then
# test the packages however you see fit.
local-wolfi:
	@echo "https://packages.wolfi.dev/os" > $(TMP_REPOSITORIES_FILE)
	@echo "$(PACKAGES_CONTAINER_FOLDER)" >> $(TMP_REPOSITORIES_FILE)
	docker run --rm -it \
		--mount type=bind,source="${PWD}/packages",destination="$(PACKAGES_CONTAINER_FOLDER)",readonly \
		--mount type=bind,source="${PWD}/local-melange-enterprise.rsa.pub",destination="/etc/apk/keys/local-melange-enterprise.rsa.pub",readonly \
		--mount type=bind,source="$(TMP_REPOSITORIES_FILE)",destination="/etc/apk/repositories",readonly \
		-w "$(PACKAGES_CONTAINER_FOLDER)" \
		cgr.dev/chainguard/wolfi-base:latest@sha256:d97b08245cdceb142b25e9be03c8cea4d4e96b1d7e14bef64ca87a1f3212d23f
	@rm "$(TMP_REPOSITORIES_FILE)"
	@rmdir "$(TMP_REPOSITORIES_DIR)"

# This target spins up a docker container that is helpful for building images
# using local packages.
# It mounts the:
#  - local packages dir (default: pwd) as a read-only, as /work/packages. This
#    is where the local packages are set up to be fetched from.
#  - local os dir (default: pwd) as a read-only, as /work/os. This is where
#    apko config files should live in. Note that this can be the current
#    directory also.
# Both of these can be overridden with PACKAGES_CONTAINER_FOLDER and OS_DIR
# respectively.
# It sets up the necessary tools, keys, and repositories for you to run
# apko to build images and then test them. Currently, the apko tool requires a
# few flags to get the image built, but we'll work on getting the viper config
# set up to make this easier.
#
# The resulting image will be in the OUT_DIR, and it is best to specify the
# OUT_DIR as a directory in the host system, so that it will persist after the
# container is done, as well as you can test / iterate with the image and run
# tests in the host.
#
# Example invocation for
# mkdir /tmp/out && OUT_DIR=/tmp/out make dev-container-wolfi
# Then in the container, you could build an image like this:
# apko -C /work/out build --keyring-append /etc/apk/keys/wolfi-signing.rsa.pub \
#  --keyring-append /etc/apk/keys/local-melange.rsa.pub --arch host \
# /work/os/conda-IMAGE.yaml conda-test:test /work/out/conda-test.tar
#
# Then from the host you can run:
# docker load -i /tmp/out/conda-test.tar
# docker run -it
OUT_LOCAL_DIR ?= /work/out
OUT_DIR ?= $(shell mktemp -d)
OS_LOCAL_DIR ?= /work/os
OS_DIR ?= ${PWD}
dev-container-wolfi:
	@echo "https://packages.wolfi.dev/os" > $(TMP_REPOSITORIES_FILE)
	@echo "$(PACKAGES_CONTAINER_FOLDER)" >> $(TMP_REPOSITORIES_FILE)
	docker run --rm -it \
		--mount type=bind,source="${OUT_DIR}",destination="$(OUT_LOCAL_DIR)" \
		--mount type=bind,source="${OS_DIR}",destination="$(OS_LOCAL_DIR)",readonly \
		--mount type=bind,source="${PWD}/packages",destination="$(PACKAGES_CONTAINER_FOLDER)",readonly \
		--mount type=bind,source="${PWD}/local-melange-enterprise.rsa.pub",destination="/etc/apk/keys/local-melange-enterprise.rsa.pub",readonly \
		--mount type=bind,source="$(TMP_REPOSITORIES_FILE)",destination="/etc/apk/repositories",readonly \
		-w "$(PACKAGES_CONTAINER_FOLDER)" \
		ghcr.io/wolfi-dev/sdk:latest@sha256:954e0b8b77c9cbe82792c321787f5b73ab5765ee887df921a13778c9c0d30714
	@rm "$(TMP_REPOSITORIES_FILE)"
	@rmdir "$(TMP_REPOSITORIES_DIR)"

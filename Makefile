ARCH ?= $(shell uname -m)
ifeq (${ARCH}, arm64)
	ARCH = aarch64
endif
TARGETDIR = packages/${ARCH}

MELANGE ?= $(shell which melange)
WOLFICTL ?= $(shell which wolfictl)
KEY ?= local-melange-enterprise.rsa
REPO ?= $(shell pwd)/packages

MELANGE_OPTS += --repository-append ${REPO}
MELANGE_OPTS += --keyring-append ${KEY}.pub
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
			ghcr.io/wolfi-dev/sdk:latest@sha256:f0df69f51e1a2de2f3fef0d3aca3fa951a408f8d42983598bfac784db934d430

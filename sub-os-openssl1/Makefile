ARCH := $(shell uname -m)
MELANGE_DIR ?= ../melange
MELANGE ?= ${MELANGE_DIR}/melange
KEY ?= local-melange.rsa
REPO ?= $(shell pwd)/packages

MELANGE_OPTS += --repository-append ${REPO}
MELANGE_OPTS += --keyring-append ${KEY}.pub
MELANGE_OPTS += --signing-key ${KEY}
MELANGE_OPTS += --pipeline-dir ${MELANGE_DIR}/pipelines
MELANGE_OPTS += --arch ${ARCH}
MELANGE_OPTS += --env-file build-${ARCH}.env
MELANGE_OPTS += ${MELANGE_EXTRA_OPTS}

define build-package

packages/$(1): packages/${ARCH}/$(1)-$(2).apk
packages/${ARCH}/$(1)-$(2).apk: ${KEY}
	mkdir -p ./$(1)/
	${MELANGE} build $(1).yaml ${MELANGE_OPTS} --source-dir ./$(if $(3),$(3),$(1))/

PACKAGES += packages/${ARCH}/$(1)-$(2).apk

endef

all: ${KEY} .build-packages

${KEY}:
	${MELANGE} keygen ${KEY}

clean:
	rm -rf packages/${ARCH}

# The list of packages to be built.
#
# Use the `build-package` macro for packages which require a source
# directory, like `glibc/` or `busybox/`.
# arg 1 = package name
# arg 2 = package version
# arg 3 = override source directory, defaults to package name, useful if you want to reuse the same subfolder for multiple packages
# example: $(eval $(call build-package,gmp,6.2.1-r4))

$(eval $(call build-package,openssl-1.1,1.1.1t-r0))

.build-packages: ${PACKAGES}

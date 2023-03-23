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

$(eval $(call build-package,go-1.17,1.17.13-r1))
$(eval $(call build-package,chainguard-baselayout,20230214-r1))
$(eval $(call build-package,hello-world,0.0.1-r1))
$(eval $(call build-package,coredns,1.10.1-r3))
$(eval $(call build-package,kube-oidc-proxy,1.0.4-r0))
$(eval $(call build-package,oauth2-proxy,7.4.0-r0))
$(eval $(call build-package,nodejs-14,14.21.2-r1))
$(eval $(call build-package,grafana,7.5.20-r0))
$(eval $(call build-package,dex-k8s-authenticator,1.4.0-r2))
$(eval $(call build-package,python-3.7,3.7.16-r1))
$(eval $(call build-package,python-3.8,3.8.10-r1))
$(eval $(call build-package,python-3.9,3.9.16-r1))
$(eval $(call build-package,py3.7-installer,0.5.1-r1))
$(eval $(call build-package,py3.8-installer,0.5.1-r1))
$(eval $(call build-package,py3.9-installer,0.5.1-r1))
$(eval $(call build-package,py3.7-setuptools,67.5.1-r1))
$(eval $(call build-package,py3.8-setuptools,67.5.1-r1))
$(eval $(call build-package,py3.9-setuptools,67.5.1-r1))
$(eval $(call build-package,py3.7-pip,23.0.1-r1))
$(eval $(call build-package,py3.8-pip,23.0.1-r1))
$(eval $(call build-package,py3.9-pip,23.0.1-r1))
$(eval $(call build-package,sourcegraph-grafana,4.4.2-r4))
$(eval $(call build-package,kubectl-1.19,1.19.16-r1))
$(eval $(call build-package,kubectl-1.20,1.20.15-r1))
$(eval $(call build-package,kubectl-1.21,1.21.14-r1))
$(eval $(call build-package,kubectl-1.22,1.22.17-r1))
$(eval $(call build-package,kubectl-1.23,1.23.15-r1))
$(eval $(call build-package,kubectl-1.24,1.24.9-r1))
$(eval $(call build-package,kubectl-1.25,1.25.5-r1))
$(eval $(call build-package,kots,1.92.1-r1))


.build-packages: ${PACKAGES}

lint:
	wolfictl lint --skip-rule forbidden-repository-used --skip-rule forbidden-keyring-used

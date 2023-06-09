BUILDWORLD = no
MELANGE_EXTRA_OPTS = --build-option fips

-include os/Makefile

./openssl/:
	ln -sf os/openssl openssl

.packagerules-old:
	@echo "Solving build order, please wait..."
	@grep -v '^\#' packages.txt | while read pkg; do		\
		pkgname=`echo $$pkg | cut -d, -f1`;			\
		pkgdir=`echo $$pkg | cut -d, -f2`;			\
		[ -z "$$pkgdir" ] && pkgdir=$$pkgname;			\
		pkgver=`${MELANGE} package-version $${pkgname}.yaml`;	\
		pkgtarget="${TARGETDIR}/$${pkgver}.apk";		\
		echo "PKGNAMELIST += $$pkgname";			\
		echo ".build-packages: $$pkgtarget";			\
		echo "packages/$$pkgname: $$pkgtarget";			\
		echo "$$pkgtarget: $${pkgname}.yaml \$${KEY}";		\
		printf "\t%s\n" "@mkdir -p ./$${pkgdir}/";		\
		printf "\t%s" "SDE=\$${SOURCE_DATE_EPOCH}; [ -z \"\$$\$$SDE\" ] && SDE=\`git log -1 --pretty=%ct --follow $${pkgname}.yaml\`;"; \
		printf "\t%s\n\n" "SOURCE_DATE_EPOCH=\$$\$$SDE \$${MELANGE} build $${pkgname}.yaml \$${MELANGE_OPTS} --source-dir ./$${pkgdir}/ --log-policy builtin:stderr,\$${TARGETDIR}/buildlogs/$${pkgver}.log"; \
	done > .packagerules-old

-include .packagerules-old

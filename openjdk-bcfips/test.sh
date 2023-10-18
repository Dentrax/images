#!/usr/bin/env bash

set -o errexit -o nounset -o errtrace -o pipefail -x
set -eu

CLASSPATH="/usr/share/java/bouncycastle-fips/*:."
export CLASSPATH

JDK_JAVA_OPTIONS="-Djava.security.properties==${DESTDIR}/usr/lib/jvm/jdk-fips-config/java.security"
JDK_JAVA_OPTIONS="${JDK_JAVA_OPTIONS} --add-exports java.base/sun.security.internal.spec=ALL-UNNAMED"
export JDK_JAVA_OPTIONS

echo "${VERSION}"

keytool -v \
    -importkeystore \
    -srckeystore "/usr/lib/jvm/java-${VERSION}-openjdk/lib/security/cacerts" \
    -srcstoretype JKS \
    -srcstorepass changeit \
    -destkeystore cacerts.bcfks \
    -deststoretype bcfks \
    -deststorepass changeit \
    -providerclass org.bouncycastle.jcajce.provider.BouncyCastleFipsProvider \
    -providerpath /usr/share/java/bouncycastle-fips/bc-fips.jar

JDK_JAVA_OPTIONS="${JDK_JAVA_OPTIONS} -Djavax.net.ssl.trustStore=cacerts.bcfks"
JDK_JAVA_OPTIONS="${JDK_JAVA_OPTIONS} -Djavax.net.ssl.trustStorePassword=changeit"
export JDK_JAVA_OPTIONS

javac Test.java
java Test

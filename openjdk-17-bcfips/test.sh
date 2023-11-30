#!/usr/bin/env bash

set -o errexit -o nounset -o errtrace -o pipefail -x

JAVA_HOME="${DESTDIR}/${JAVA_HOME}"
CLASSPATH="/usr/share/java/bouncycastle-fips/*:."
export CLASSPATH

JDK_JAVA_OPTIONS="-Djava.security.properties==${JAVA_HOME}/conf/security/java.security"
JDK_JAVA_OPTIONS="${JDK_JAVA_OPTIONS} --add-exports java.base/sun.security.internal.spec=ALL-UNNAMED"
export JDK_JAVA_OPTIONS

JDK_JAVA_OPTIONS="${JDK_JAVA_OPTIONS} -Djavax.net.ssl.trustStore=cacerts.bcfks"
JDK_JAVA_OPTIONS="${JDK_JAVA_OPTIONS} -Djavax.net.ssl.trustStorePassword=changeit"
export JDK_JAVA_OPTIONS

"${JAVA_HOME}/bin/javac" Test.java
"${JAVA_HOME}/bin/java" Test

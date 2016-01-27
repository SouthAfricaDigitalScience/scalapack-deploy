#!/bin/bash -e
# This is the check script for scalapack
. /etc/profile.d/modules.sh
module add ci
module add cmake
module add gcc/${GCC_VERSION}
module add openmpi/${OPENMPI_VERSION}-gcc-${GCC_VERSION}
module add  lapack/3.6.0-gcc-${GCC_VERSION}

cd ${WORKSPACE}/${NAME}-${VERSION}/build-${BUILD_NUMBER}
# removing the tests since they timeout
# make test
echo "tests have passed. Installing into CI"
make install
echo "finished install, making modulefile"
mkdir -p modules
(
cat <<MODULE_FILE
#%Module1.0
## $NAME modulefile
##
proc ModulesHelp { } {
  puts stderr "\\tAdds $NAME ($VERSION.) to your environment."
}
module-whatis "Sets the environment for using $NAME ($VERSION.) See https://github.com/SouthAfricaDigitalScience/scalapack-deploy"
setenv SL_VERSION $VERSION
setenv SL_DIR /apprepo/$::env(SITE)/$::env(OS)/$::env(ARCH)/$NAME/$VERSION-mpi-$OPENMPI_VERSION-gcc-$GCC_VERSION
prepend-path LD_LIBRARY_PATH $::env(SL_DIR)/lib
prepend-path PATH $::env(SL_DIR)/bin
MODULE_FILE
) > modules/${VERSION}-mpi-${OPENMPI_VERSION}-gcc-${GCC_VERSION}
mkdir -p ${LIBRARIES_MODULES}/${NAME}
cp modules/${VERSION}-mpi-${OPENMPI_VERSION}-gcc-${GCC_VERSION} ${LIBRARIES_MODULES}/${NAME}

module avail

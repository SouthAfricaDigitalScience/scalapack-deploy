#!/bin/bash -e
# This is the deploy script for scalapack
. /etc/profile.d/modules.sh
module add deploy
module add cmake
module add gcc/${GCC_VERSION}
module add openmpi/${OPENMPI_VERSION}-gcc-${GCC_VERSION}
module add  lapack/3.6.0-gcc-${GCC_VERSION}

cd ${WORKSPACE}/${NAME}-${VERSION}/build-${BUILD_NUMBER}
rm -rf *
# we need to clean out the previous CI build
cmake ../ \
-G"Unix Makefiles" \
-DCMAKE_INSTALL_PREFIX=${SOFT_DIR}-mpi-${OPENMPI_VERSION}-gcc-${GCC_VERSION} \
-DBUILD_SHARED_LIBS=ON \
-DLAPACK_LIBRARIES="-L${LAPACK_DIR}/lib -llapack" \
-DBLAS_LIBRARIES="-lblas"

nice -n20 make -j2
make install

echo "deploy has finished, making modulefile"
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
setenv SL_DIR $::env(CVMFS_DIR)/$::env(SITE)/$::env(OS)/$::env(ARCH)/$NAME/$VERSION-mpi-$OPENMPI_VERSION-gcc-$GCC_VERSION
prepend-path LD_LIBRARY_PATH $::env(SL_DIR)/lib
prepend-path PATH $::env(SL_DIR)/bin
MODULE_FILE
) > modules/${VERSION}
mkdir -p ${LIBRARIES_MODULES}/${NAME}-mpi-${OPENMPI_VERSION}-gcc-${GCC_VERSION}
cp modules/${VERSION}-mpi-${OPENMPI_VERSION}-gcc-${GCC_VERSION} ${LIBRARIES_MODULES}/${NAME}
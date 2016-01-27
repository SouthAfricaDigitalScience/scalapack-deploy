#!/bin/bash -e
# This is the build script for scalapack
. /etc/profile.d/modules.sh
module add ci
module add cmake
module add gcc/${GCC_VERSION}
module add openmpi/${OPENMPI_VERSION}-gcc-${GCC_VERSION}
module add lapack/3.6.0-gcc-${GCC_VERSION}
SOURCE_FILE=${NAME}-${VERSION}.tgz

# We provide the base module which all jobs need to get their environment on the build slaves
mkdir -p ${WORKSPACE}
# SRC_DIR is the local directory to which all of the source code tarballs are downloaded. We cache them locally.
mkdir -p ${SRC_DIR}
# SOFT_DIR is the directory into which the application will be "installed"
mkdir -p ${SOFT_DIR}

#  Download the source file if it's not available locally.
#  we were originally using ncurses as the test application
if [ ! -e ${SRC_DIR}/${SOURCE_FILE}.lock ] && [ ! -s ${SRC_DIR}/${SOURCE_FILE} ] ; then
  touch  ${SRC_DIR}/${SOURCE_FILE}.lock
  echo "seems like this is the first build - let's get the source"
  mkdir -p $SRC_DIR
# use local mirrors if you can. Remember - UFS has to pay for the bandwidth!
  wget http://www.netlib.org/${NAME}/$SOURCE_FILE -O $SRC_DIR/$SOURCE_FILE
  echo "releasing lock"
  rm -v ${SRC_DIR}/${SOURCE_FILE}.lock
elif [ -e ${SRC_DIR}/${SOURCE_FILE}.lock ] ; then
  # Someone else has the file, wait till it's released
  while [ -e ${SRC_DIR}/${SOURCE_FILE}.lock ] ; do
    echo " There seems to be a download currently under way, will check again in 5 sec"
    sleep 5
  done
else
  echo "continuing from previous builds, using source at " $SRC_DIR/$SOURCE_FILE
fi

# now unpack it into the workspace
tar -xvzf ${SRC_DIR}/${SOURCE_FILE} -C ${WORKSPACE} --skip-old-files

#  generally tarballs will unpack into the NAME-VERSION directory structure. If this is not the case for your application
#  ie, if it unpacks into a different default directory, either use the relevant tar commands, or change
#  the next lines

# We will be running configure and make in this directory
mkdir -p ${WORKSPACE}/${NAME}-${VERSION}/build-${BUILD_NUMBER}
cp -vf ${WORKSPACE}/SLmake.inc ${WORKSPACE}/${NAME}-${VERSION}
cd ${WORKSPACE}/${NAME}-${VERSION}/build-${BUILD_NUMBER}
cmake ../ \
-G"Unix Makefiles" \
-DCMAKE_INSTALL_PREFIX=${SOFT_DIR}-mpi-${OPENMPI_VERSION}-gcc-${GCC_VERSION} \
-DBUILD_SHARED_LIBS=ON \
-DLAPACK_LIBRARIES="-L${LAPACK_DIR}/lib -llapack" \
-DBLAS_LIBRARIES="-lblas"

nice -n20 make -j2

#!/bin/sh

#
# This script builds the CernVM-FS service container.
#

set -e

SCRIPT_LOCATION=$(cd "$(dirname "$0")"; pwd)
. ${SCRIPT_LOCATION}/../common.sh

if [ $# -lt 3 ]; then
  echo "Usage: $0 <CernVM-FS source directory> <build result location> <busybox binary> [<nightly build number>]"
  echo "This script builds CernVM-FS service container"
  exit 1
fi

if ! buildah version; then
  echo "buildah required to build container image"
  exit 1
fi

if ! busybox --help | head -5; then
  echo "functional busybox is required"
  exit 1
fi

if ! lsb_release -sicr; then
  echo "lsb_release required to build container image"
  exit 1
fi

CVMFS_SOURCE_LOCATION="$1"
CVMFS_RESULT_LOCATION="$2"
CVMFS_BUSYBOX="$3"
CVMFS_NIGHTLY_BUILD_NUMBER="${4-0}"

# retrieve the upstream version string from CVMFS
cvmfs_version="$(get_cvmfs_version_from_cmake $CVMFS_SOURCE_LOCATION)"
echo "detected upstream version: $cvmfs_version"

git_hash="$(get_cvmfs_git_revision $CVMFS_SOURCE_LOCATION)"

# generate the release tag for either a nightly build or a release
CVMFS_TAG=
if [ $CVMFS_NIGHTLY_BUILD_NUMBER -gt 0 ]; then
  build_tag="git-${git_hash}"
  nightly_tag="0.${CVMFS_NIGHTLY_BUILD_NUMBER}.${git_hash}git"

  echo "creating nightly build '$nightly_tag'"
  CVMFS_TAG="$nightly_tag"
else
  echo "creating release: $cvmfs_version"
  CVMFS_TAG="$cvmfs_version"
fi

${CVMFS_SOURCE_LOCATION}/packaging/container/build.sh \
  ${CVMFS_SOURCE_LOCATION} ${CVMFS_RESULT_LOCATION} ${CVMFS_BUSYBOX} ${CVMFS_TAG} \
  || die "failed building service container"

#
## generating package map section for specific platform
#if [ ! -z $CVMFS_CI_PLATFORM_LABEL ]; then
#  echo "generating package map section for ${CVMFS_CI_PLATFORM_LABEL}..."
#  generate_package_map                                                        \
#    "$CVMFS_CI_PLATFORM_LABEL"                                                \
#    "$(basename $(find . -regex '.*cvmfs-[0-9].*\.rpm' ! -name '*.src.rpm'))" \
#    "$(basename $(find . -regex '.*cvmfs-server-[0-9].*\.rpm'))"              \
#    "$(basename $(find . -regex '.*cvmfs-devel-[0-9].*\.rpm'))"               \
#    "$(basename $(find . -regex '.*cvmfs-unittests-[0-9].*\.rpm'))"           \
#    "$CVMFS_CONFIG_PACKAGE"                                                   \
#    "$(basename $(find . -regex '.*cvmfs-shrinkwrap-[0-9].*\.rpm'))"          \
#    "$(basename $(find . -regex '.*cvmfs-ducc-[0-9].*\.rpm'))"                \
#    "$(basename $(find . -regex '.*cvmfs-fuse3-[0-9].*\.rpm'))"
#fi

#!/bin/bash

set -e

git pull

DATE=`date +%Y%m%d`
VERSION=$(git describe --tags | cut -d '-' -f 1 | cut -d 'v' -f 2 | sed -e 's/^release_\(.*\)_.*$/\1/')
GITTAG=`git rev-parse --short HEAD`
RELEASETYPE=`git describe --tags | cut -d '_' -f 2`
BUILDTAG=`git describe --tags | cut -d '-' -f 2-4`
CWD=`pwd`

bash duplicati-make-git-snapshot.sh "${GITTAG}" "${DATE}" "${VERSION}" "${RELEASETYPE}" "${BUILDTAG}-${GITTAG}"

RPMBUILD="${CWD}/${BUILDTAG}-rpmbuild"
if [ -d "${RPMBUILD}" ]; then
    rm -rf "${RPMBUILD}"
fi

mkdir -p "${RPMBUILD}"/{BUILD,RPMS,SOURCES,SPECS,SRPMS}

mv enatrustbackup-$DATE.tar.bz2 "${RPMBUILD}/SOURCES/"
cp *.sh "${RPMBUILD}/SOURCES/"
cp *.patch "${RPMBUILD}/SOURCES/"
cp duplicati.xpm "${RPMBUILD}/SOURCES/"
cp build-package.sh "${RPMBUILD}/SOURCES/duplicati-build-package.sh"

echo "%global _gittag ${GITTAG}" > "${RPMBUILD}/SOURCES/enatrustbackup-buildinfo.spec"
echo "%global _builddate ${DATE}" >> "${RPMBUILD}/SOURCES/enatrustbackup-buildinfo.spec"
echo "%global _buildversion ${VERSION}" >> "${RPMBUILD}/SOURCES/enatrustbackup-buildinfo.spec"
echo "%global _releasetype ${RELEASETYPE}" >> "${RPMBUILD}/SOURCES/enatrustbackup-buildinfo.spec"
cp ../install_glide.sh .

docker build $CWD -t "duplicati/centos-build:latest" -f Dockerfile.build

# Weirdness with time not being synced in Docker instance
sleep 5
echo docker run  -u 0:0 \
    --workdir "/buildroot" \
    --volume "${CWD}":"/buildroot":"rw" \
    --volume "${RPMBUILD}":"/root/rpmbuild":"rw" \
    "duplicati/centos-build:latest" \
    bash -c "chown -R root:root /root/rpmbuild/*;rpmbuild -ba enatrustbackup.spec"

docker run  -u 0:0 \
    --workdir "/buildroot" \
    --volume "${CWD}":"/buildroot":"rw" \
    --volume "${RPMBUILD}":"/root/rpmbuild":"rw" \
    "duplicati/centos-build:latest" \
    bash -c "chown -R root:root /root/rpmbuild/*;rpmbuild -ba enatrustbackup.spec"

cp "${RPMBUILD}/RPMS/noarch/"*.rpm .
cp "${RPMBUILD}/SRPMS/"*.rpm .
docker run  -u 0:0 \
    --workdir "/root/rpmbuild" \
    --volume "${RPMBUILD}":"/root/rpmbuild":"rw" \
    "duplicati/centos-build:latest" \
    bash -c "rm -rf *"
rmdir "${RPMBUILD}"

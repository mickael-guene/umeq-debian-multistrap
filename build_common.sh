#!/bin/bash -ex

arch=$1
version=$2
output=$3

function cleanup() {
    rm -Rf $TMPDIR
}

function build_multistrap() {
mkdir -p ${TMPDIR}/conf
cat << EOF > ${TMPDIR}/conf/multistrap.conf
[General]
noauth=true
unpack=true
debootstrap=Debian
aptsources=Debian
cleanup=true

[Debian]
packages=apt
source=http://ftp.debian.org/debian
suite=${version}
EOF
}

if [ "${arch}" == "arm64" ]; then
    UMEQ=umeq-arm64
    QEMU=qemu-aarch64-static
elif [ "${arch}" == "armhf" ]; then
    UMEQ=umeq-arm
    QEMU=qemu-arm-static
else
    exit 1
fi

#create tmp dir
TMPDIR=`mktemp -d -t arm64_debian_docker_XXXXXXXX`
trap cleanup EXIT
cd ${TMPDIR}

#build rootfs
build_multistrap
/usr/sbin/multistrap -a ${arch} -d rootfs -f ${TMPDIR}/conf/multistrap.conf

#get and install umeq
if [ "${arch}" == "arm64" ]; then
    UMEQ=umeq-arm64
    QEMU=qemu-aarch64-static
elif [ "${arch}" == "armhf" ]; then
    UMEQ=umeq-arm
    QEMU=qemu-arm-static
else
    exit 1
fi

wget https://raw.githubusercontent.com/mickael-guene/umeq-static-build/master/bin/${UMEQ} -O ${TMPDIR}/rootfs/usr/bin/${UMEQ}
chmod +x ${TMPDIR}/rootfs/usr/bin/${UMEQ}
ln -sf ./${UMEQ} ${TMPDIR}/rootfs/usr/bin/${QEMU}

#tweak rootfs for docker
#taken from debootstrab in docker.io contrib
cat > "${TMPDIR}/rootfs/etc/apt/apt.conf.d/docker-no-languages" <<-'EOF'
    # In Docker, we don't often need the "Translations" files, so we're just wasting
    # time and space by downloading them, and this inhibits that.  For users that do
    # need them, it's a simple matter to delete this file and "apt-get update". :)

    Acquire::Languages "none";
EOF
cat > "${TMPDIR}/rootfs/etc/apt/apt.conf.d/docker-gzip-indexes" <<-'EOF'
    # Since Docker users using "RUN apt-get update && apt-get install -y ..." in
    # their Dockerfiles don't go delete the lists files afterwards, we want them to
    # be as small as possible on-disk, so we explicitly request "gz" versions and
    # tell Apt to keep them gzipped on-disk.

    # For comparison, an "apt-get update" layer without this on a pristine
    # "debian:wheezy" base image was "29.88 MB", where with this it was only
    # "8.273 MB".

    Acquire::GzipIndexes "true";
    Acquire::CompressionTypes::Order:: "gz";
EOF

#build rootfs
tar --numeric-owner --owner=0 --group=0 -czf ${output} -C ${TMPDIR}/rootfs .

cleanup

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

#build rootfs
tar -czf ${output} -C ${TMPDIR}/rootfs .

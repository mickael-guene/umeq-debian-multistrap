#!/bin/bash -x

#get script location
SCRIPTDIR=`dirname $0`
SCRIPTDIR=`(cd $SCRIPTDIR ; pwd)`

#ARCHS="arm64 armhf"
#VERSIONS="jessie testing"
ARCHS="arm64 armhf"
VERSIONS="jessie testing"

#push rootfs
for arch in ${ARCHS}; do
    # deploy key
    set +x
    openssl aes-256-cbc -K $encrypted_f1bb190f457f_key -iv $encrypted_f1bb190f457f_iv -in deploy_key_${arch}.enc -out deploy_key -d
    set -x
    chmod 600 deploy_key
    eval `ssh-agent -s`
    ssh-add deploy_key
    rm deploy_key
    # deploy commit
    for version in ${VERSIONS}; do
        . ${SCRIPTDIR}/deploy_common.sh ${arch} ${version} ${SCRIPTDIR}/../${arch}-debian-${version}.tgz
    done
done

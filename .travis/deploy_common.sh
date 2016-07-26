#!/bin/bash -ex

arch=$1
version=$2
tarball=$3

#create working directory
WDIR=`mktemp -d` && trap "rm -Rf $WDIR" EXIT

#set umeq name
if [ "${arch}" == "arm64" ]; then
    UMEQ=umeq-arm64
elif [ "${arch}" == "armhf" ]; then
    UMEQ=umeq-arm
else
    exit 1
fi

#switch to tmp dir and setup new git repo
cd ${WDIR}
git init
git config user.name ${GIT_USER_NAME}
git config user.email ${GIT_USER_EMAIL}
git remote add origin https://github.com/mickael-guene/${arch}-debian

#pull last commit
git pull --depth=1 origin ${version}
git checkout -b ${version}

#create commit
cat << EOF > Dockerfile
FROM scratch
MAINTAINER ${GIT_USER_NAME} <${GIT_USER_EMAIL}>

ADD ${arch}-debian-${version}.tgz /

CMD ["/usr/bin/${UMEQ}" "-execve" "-0" "bash" "/bin/bash"]
EOF
cp ${tarball} .

git add .
git commit -m "Trig by original commit $TRAVIS_COMMIT"

#push commit
git push git@github.com:mickael-guene/${arch}-debian ${version}

#cleanup
rm -Rf $WDIR

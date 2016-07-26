#!/bin/bash -x

#get script location
SCRIPTDIR=`dirname $0`
SCRIPTDIR=`(cd $SCRIPTDIR ; pwd)`

#create working directory
WDIR=`mktemp -d` && trap "rm -Rf $WDIR" EXIT

#add deploy key
cd ${SCRIPTDIR}
openssl aes-256-cbc -K $encrypted_f1bb190f457f_key -iv $encrypted_f1bb190f457f_iv -in deploy_key.enc -out deploy_key -d
chmod 600 deploy_key
eval `ssh-agent -s`
ssh-add deploy_key
rm deploy_key

#switch to tmp dir and setup new git repo
cd ${WDIR}
git init
git config user.name ${GIT_USER_NAME}
git config user.email ${GIT_USER_EMAIL}
git remote add origin https://github.com/mickael-guene/arm64-debian

#pull last commit
git pull --depth=1 origin jessie
git checkout -b jessie

#create commit
cat << EOF > Dockerfile
FROM scratch
MAINTAINER ${GIT_USER_NAME} <${GIT_USER_EMAIL}>

ADD arm64-debian-jessie.tgz /

CMD ["/usr/bin/umeq-arm64" "-execve" "-0" "bash" "/bin/bash"]
EOF
cp ${SCRIPTDIR}/arm64-debian-jessie.tgz .

git add .
git commit -m "Trig by original commit $TRAVIS_COMMIT"

#push commit
git push git@github.com:mickael-guene/arm64-debian jessie

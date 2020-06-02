#! /bin/bash

ALPINE_VER=$1
ALPINE_BRANCH="$ALPINE_VER"-stable

FROM_TAG=alpine:$ALPINE_VER

REPO="codementality/alpine-php"
# Checks for the existence of a tag on Docker Hub
# Note:  need to install jq from repository on TRAVIS first
# sudo apt-get install jq
function docker_tag_exists() {
    TOKEN=$(curl -s -H "Content-Type: application/json" -X POST -d '{"username": "'${DOCKER_USERNAME}'", "password": "'${DOCKER_PASSWORD}'"}' https://hub.docker.com/v2/users/login/ | jq -r .token)
    EXISTS=$(curl -s -H "Authorization: JWT ${TOKEN}" https://hub.docker.com/v2/repositories/$1/tags/?page_size=10000 | jq -r "[.results | .[] | .name == \"$2\"] | any")
    test $EXISTS = true
}

if [ -z "$1" ]; then
	echo "Please supply an alpine linux aports version (branch name without \"-stable\") from https://gitlab.alpinelinux.org/alpine/aports."
	exit 0
fi

# Read the PHP version from APKBUILD and set the major (PHPV1), minor (PHPV2), and patch (PHPV3) versions
APKBUILD=$(curl -s https://gitlab.alpinelinux.org/alpine/aports/-/raw/${ALPINE_BRANCH}/community/php7/APKBUILD | grep "pkgver=")
LSTR=$(expr ${#APKBUILD} - 7)
 # patch version
PHPV2=${APKBUILD:7:$LSTR}
 # minor version
PHPV1=${PHPV2%.*}
 # major version
PHPV0=${PHPV2%%.*}

# check to see if the patch version tag exists, if yes, exit without building image
if docker_tag_exists codementality/alpine-php $PHPV2; then
	echo "Tag $PHPV3 exists"
    exit 0
fi

FROM_TAG=alpine:"$ALPINE_VER"
echo $FROM_TAG
echo $ALPINE_BRANCH
echo $PHPV0
echo $PHPV1
echo $PHPV2

docker build -t php \
	--build-arg FROM_TAG=${FROM_TAG} \
	--build-arg ALPINE_BRANCH=${ALPINE_BRANCH} \
	--build-arg PHPV0=${PHPV0} \
	--build-arg PHPV2=${PHPV2} \
	./

#docker login -u="$DOCKER_USERNAME" -p="$DOCKER_PASSWORD"
docker tag php codementality/alpine-php:${PHPV2}
#docker push codementality/alpine-php:${PHPV2}
docker tag php codementality/alpine-php:${PHPV1}
#docker push codementality/alpine-php:${PHPV1}

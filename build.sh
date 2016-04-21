#!/bin/bash -x

# check out out GO tools
git clone https://github.com/ubirch/go-tools.git

if [ $? -ne 0 ]; then exit 1; fi


# calculate our new label for the version string
NEW_LABEL=`./go-tools/concat-labels.sh`


if [ -f VAR/JAVA_VERSION ]; then
  export JAVA_VERSION=`cat VAR/JAVA_VERSION`
fi

if [ -f VAR/JAVA_BUILD ]; then
  export JAVA_BUILD=`cat VAR/JAVA_BUILD`
fi

if [ -f VAR/JAVA_UPDATE ]; then
  export JAVA_UPDATE=`cat VAR/JAVA_UPDATE`
fi


echo "Building Maven container with JAVA_VERSION=${JAVA_VERSION} JAVA_UPDATE=${JAVA_UPDATE} JAVA_BUILD=${JAVA_BUILD}"

mkdir -p VAR && docker build --build-arg JAVA_VERSION=${JAVA_VERSION:=8} \
  -t ubirch/maven-build:v${NEW_LABEL} .


if [ $? -eq 0 ]; then
    echo ${JAVA_VERSION:=8} > VAR/JAVA_VERSION
    echo ${JAVA_UPDATE:=77} > VAR/JAVA_UPDATE
    echo ${JAVA_BUILD:=03} > VAR/JAVA_BUILD
else
    echo "Docker build failed"
    exit 1
  fi

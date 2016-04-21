#!/bin/bash -x



# calculate our new label for the version string
NEW_LABEL=""


if [ -f VAR/JAVA_VERSION ]; then
  export JAVA_VERSION=`cat VAR/JAVA_VERSION`
fi

if [ -f VAR/JAVA_BUILD ]; then
  export JAVA_BUILD=`cat VAR/JAVA_BUILD`
fi

if [ -f VAR/JAVA_UPDATE ]; then
  export JAVA_UPDATE=`cat VAR/JAVA_UPDATE`
fi

function fetch_got-tools() {

    if [ -d go-tools ]; then
      # update the existing repo
      cd go-tools
      git pull
      if [ $? -ne 0 ]; then exit 1; fi
      cd ..
    else
      # check out out GO tools
      git clone https://github.com/ubirch/go-tools.git
      if [ $? -ne 0 ]; then exit 1; fi
    fi


}

function init() {
  NEW_LABEL=`./go-tools/concat-labels.sh`
}

function fix_dockerfile_version() {
  sed "s#FROM ubirch/java#FROM ubirch/java:v${GO_DEPENDENCY_LABEL_JAVA_BASE_CONTAINER}#g" Dockerfile > Dockerfile.v${NEW_LABEL}
}

# build the docker container
function build_container() {

    fix_dockerfile_version

    echo "Building Maven container with JAVA_VERSION=${JAVA_VERSION} JAVA_UPDATE=${JAVA_UPDATE} JAVA_BUILD=${JAVA_BUILD}"

    mkdir -p VAR && docker build --build-arg JAVA_VERSION=${JAVA_VERSION:=8} -t ubirch/maven-build:v${NEW_LABEL} -f Dockerfile.v${NEW_LABEL} .


    if [ $? -eq 0 ]; then
        echo ${JAVA_VERSION:=8} > VAR/JAVA_VERSION
        echo ${JAVA_UPDATE:=77} > VAR/JAVA_UPDATE
        echo ${JAVA_BUILD:=03} > VAR/JAVA_BUILD
        echo ${NEW_LABEL} > VAR/${GO_PIPELINE_NAME}_${GO_STAGE_NAME}
    else
        echo "Docker build failed"
        exit 1
    fi

}

# publish the new docker container
function publish_container() {
  echo "Publishing Docker Container with version: ${NEW_LABEL}"
  docker push ubirch/maven-build:v${NEW_LABEL}

  if [ $? -eq 0 ]; then
    echo ${NEW_LABEL} > VAR/GO_PIPELINE_NAME_${GO_PIPELINE_NAME}
  else
    echo "Docker push faild"
    exit 1
  fi

}


case "$1" in
    build)
        fetch_got-tools
        init
        build_container
        ;;
    publish)
        fetch_got-tools
        init
        publish_container
        ;;
    *)
        echo "Usage: $0 {build|publish}"
        exit 1
esac

exit 0

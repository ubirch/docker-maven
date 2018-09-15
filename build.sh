#!/bin/bash -x


if [ -f VAR/JAVA_VERSION ]; then
  export JAVA_VERSION=`cat VAR/JAVA_VERSION`
fi

if [ -f VAR/JAVA_BUILD ]; then
  export JAVA_BUILD=`cat VAR/JAVA_BUILD`
fi

if [ -f VAR/JAVA_UPDATE ]; then
  export JAVA_UPDATE=`cat VAR/JAVA_UPDATE`
fi


function test_maven() {

  docker run -ti -v${PWD}:/build ubirch/maven-build:v${GO_PIPELINE_LABEL} archetype:generate -DgroupId=com.mycompany.app -DartifactId=my-app -DarchetypeArtifactId=maven-archetype-quickstart -DinteractiveMode=false

  if [ ! $? -eq 0 ]; then
      echo "Docker build failed"
      exit 1
  fi

  if [ ! -f ${PWD}/my-app/pom.xml ]; then
    echo "Test failed: pom.xml missing"
    exit 1
  fi
  if [ ! -f ${PWD}/my-app/src/main/java/com/mycompany/app/App.java ]; then
    echo "Test failed: ${PWD}/my-app/src/main/java/com/mycompany/app/App.java missing"
    exit 1
  fi
}

function fix_dockerfile_version() {
  if [ "v${GO_DEPENDENCY_LABEL_JAVA_BASE_CONTAINER}" = "v" ]; then
    CONTAINER_LABEL=latest
  else
    CONTAINER_LABEL="v${GO_DEPENDENCY_LABEL_JAVA_BASE_CONTAINER}"
  fi
  sed "s#FROM ubirch/java#FROM ubirch/java:${CONTAINER_LABEL}#g" Dockerfile > Dockerfile.v${GO_PIPELINE_LABEL}
  diff Dockerfile Dockerfile.v${GO_PIPELINE_LABEL}
}

# build the docker container
function build_container() {

    fix_dockerfile_version

    echo "Building Maven container with JAVA_VERSION=${JAVA_VERSION} JAVA_UPDATE=${JAVA_UPDATE} JAVA_BUILD=${JAVA_BUILD}"

    mkdir -p VAR && docker build --build-arg JAVA_VERSION=${JAVA_VERSION:=8} --build-arg VCS_REF=`git rev-parse --short HEAD` --build-arg BUILD_DATE=`date -u +"%Y-%m-%dT%H:%M:%SZ"` -t ubirch/maven-build:v${GO_PIPELINE_LABEL} -f Dockerfile.v${GO_PIPELINE_LABEL} .


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
  echo "Publishing Docker Container with version: ${GO_PIPELINE_LABEL}"
  docker push ubirch/maven-build:v${GO_PIPELINE_LABEL} && docker push ubirch/maven-build

  if [ $? -eq 0 ]; then
    echo ${NEW_LABEL} > VAR/GO_PIPELINE_NAME_${GO_PIPELINE_NAME}
  else
    echo "Docker push faild"
    exit 1
  fi

}


case "$1" in
    build)
        build_container
        ;;
    publish)
        publish_container
        ;;
    test)
      test_maven
      ;;
    *)
        echo "Usage: $0 {build|publish}"
        exit 1
esac

exit 0

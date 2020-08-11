#!/bin/bash -x



# call maven to create a default project to check base functionality
# https://maven.apache.org/guides/getting-started/maven-in-five-minutes.html
function test_maven() {

  # delete artefact from previous run
  if [ -d ./my-app/ ]; then
    rm -rf ./my-app/
  fi

  mkdir -p maven-repo
  docker run --user `id -u`:`id -g` -v ${PWD}/maven-repo:/maven-repo -v${PWD}:/build ubirch/maven-build:vOpenJDK_${GO_PIPELINE_LABEL} archetype:generate -DgroupId=com.mycompany.app -DartifactId=my-app -DarchetypeArtifactId=maven-archetype-quickstart -DinteractiveMode=false

  if [ ! $? -eq 0 ]; then
      echo "Maven generate archetype failed"
      exit 1
  fi

  # check whether pom.xml has been created by Maven
  if [ ! -f ${PWD}/my-app/pom.xml ]; then
    echo "Test failed: pom.xml missing"
    exit 1
  fi

  # check whether Java Source file has been created by maven
  if [ ! -f ${PWD}/my-app/src/main/java/com/mycompany/app/App.java ]; then
    echo "Test failed: ${PWD}/my-app/src/main/java/com/mycompany/app/App.java missing"
    exit 1
  fi

  docker run --user `id -u`:`id -g` -v${PWD}/my-app:/build ubirch/maven-build:vOpenJDK_${GO_PIPELINE_LABEL} package
  if [ ! $? -eq 0 ]; then
      echo "Maven package failed"
      exit 1
  fi

}



# build the docker container
function build_container() {

    fix_dockerfile_version

    echo "Building Maven container with OpenJDK 8"

    mkdir -p VAR && docker build --build-arg VCS_REF=`git rev-parse --short HEAD` --build-arg BUILD_DATE=`date -u +"%Y-%m-%dT%H:%M:%SZ"` -t ubirch/maven-build:vOpenJDK_${GO_PIPELINE_LABEL} -f Dockerfile .


    if [ $? -eq 0 ]; then
        echo ${NEW_LABEL} > VAR/${GO_PIPELINE_NAME}_${GO_STAGE_NAME}
    else
        echo "Docker build failed"
        exit 1
    fi

}

# publish the new docker container
function publish_container() {
  echo "Publishing Docker Container with version: ${GO_PIPELINE_LABEL}"
  docker push ubirch/maven-build:vOpenJDK_${GO_PIPELINE_LABEL} && docker push ubirch/maven-build

  if [ $? -eq 0 ]; then
    echo ${NEW_LABEL} > VAR/GO_PIPELINE_NAME_${GO_PIPELINE_NAME}
  else
    echo "Docker push failed"
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
        echo "Usage: $0 {build|publish|test}"
        exit 1
esac

exit 0

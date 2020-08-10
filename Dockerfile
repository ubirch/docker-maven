FROM ubirch/java
MAINTAINER Falko Zurell <falko.zurell@ubirch.com>

# Build-time metadata as defined at http://label-schema.org
  ARG BUILD_DATE
  ARG VCS_REF
  LABEL org.label-schema.build-date=$BUILD_DATE \
        org.label-schema.docker.dockerfile="/Dockerfile" \
        org.label-schema.license="MIT" \
        org.label-schema.name="ubirch Maven Build Container" \
        org.label-schema.url="https://ubirch.com" \
        org.label-schema.vcs-ref=$VCS_REF \
        org.label-schema.vcs-type="Git" \
        org.label-schema.vcs-url="https://github.com/ubirch/docker-maven"

ARG JAVA_VERSION=8
ARG JAVA_HOME=/usr/lib/jvm/java-${JAVA_VERSION}-oracle

LABEL description="uBirch Maven build container"
RUN apt-get update && apt-get --fix-missing --no-install-recommends install procps maven git  -y && \
    apt-get autoclean && apt-get --purge -y autoremove && \
    rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*

RUN update-alternatives --install "/usr/bin/java" "java" "${JAVA_HOME}/bin/java" 1 && \
    update-alternatives --install "/usr/bin/javaws" "javaws" "${JAVA_HOME}/bin/javaws" 1 && \
    update-alternatives --install "/usr/bin/javac" "javac" "${JAVA_HOME}/bin/javac" 1 && \
    update-alternatives --set java "${JAVA_HOME}/bin/java" && \
    update-alternatives --set javaws "${JAVA_HOME}/bin/javaws" && \
    update-alternatives --set javac "${JAVA_HOME}/bin/javac"

RUN git config --system user.name Docker && git config --system user.email docker@localhost

RUN mkdir -p /build && mkdir -p /maven-repo
VOLUME /build /maven-repo
WORKDIR /build
ENV JAVA_HOME /usr
ENTRYPOINT ["/usr/bin/mvn"]
ENV MAVEN_OPTS=-Dmaven.repo.local=/maven-repo
CMD ["--help"]

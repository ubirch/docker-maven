FROM debian:stretch
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



LABEL description="uBirch Maven build container"
RUN apt-get update
RUN apt-get --fix-missing install openjdk-8-jdk -y
RUN apt-get --fix-missing install maven git -y && \
    apt-get autoclean && apt-get --purge -y autoremove && \
    rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*


RUN git config --system user.name Docker && git config --system user.email docker@localhost

RUN mkdir -p /build && mkdir -p /maven-repo
VOLUME /build /maven-repo
WORKDIR /build
ENV JAVA_HOME /usr
ENTRYPOINT ["/usr/bin/mvn"]
ENV MAVEN_OPTS=-Dmaven.repo.local=/maven-repo
CMD ["--help"]

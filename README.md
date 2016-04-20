# Build container

This docker container is our default build container for java based applications.
It should be used to compile java projects with maven

## usage
Check out your Java project containing the maven build file. Run the container
to start the maven compilation. You mount the root directory of your project
into the container and call maven install:

```docker run --name maven -v $PWD:/build -v /maven-repo maven-build install```

This will mount your current working directory into "/build" of the container
call ```mvn install``` in that directory. Additionally the /maven-repo directory inside
the container will be persistet. Thus on subsequent runs of this container it will
likely reuse downloaded artifacts.

The downloaded artifacts are stored in a folder called "/maven-repo". If you don't want that, then you can override the maven environment
by passing a different or empty MAVEN_OPTS to the command:

```docker run --name maven -v $PWD:/build -e "MAVEN_OPTS=-Dmaven.repo.local=/build/local-maven-repo" maven-build install```

Subsequent build can then be called via:

```docker start -a maven```

This will start the original container with the very same parameters and execute the
build again. In that run, the downloads that have been cached before in /maven-repo
are used and speed up the build.

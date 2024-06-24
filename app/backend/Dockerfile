FROM gradle:7.5-jdk17 AS build

COPY --chown=gradle:gradle . /home/gradle/src

WORKDIR /home/gradle/src

RUN gradle build --no-daemon

FROM openjdk:17-oracle

COPY --from=build /home/gradle/src/build/libs/tic-tac-toe-0.0.1-SNAPSHOT.jar /app/application.jar

ENTRYPOINT ["java","-jar","/app/application.jar"]

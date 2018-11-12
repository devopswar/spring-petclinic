FROM anapsix/alpine-java
LABEL maintainer="labs@cyberark.com"
WORKDIR /home/ubuntu/workspace/spring-project/target/
COPY . /home
CMD ["java","-jar","/home/target/spring-petclinic-2.0.0.jar"]
EXPOSE 8080
 

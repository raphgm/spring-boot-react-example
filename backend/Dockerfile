# Use a base image with JDK
FROM openjdk:17-jdk-slim

# Set the working directory
WORKDIR /app

# Copy the JAR file built in your CI pipeline
#COPY target/my-spring-boot-app.jar app.jar
#COPY target/app.jar app.jar
COPY target/react-and-spring-data-rest-0.0.1-SNAPSHOT.jar app.jar



# Expose the port the app will run on
EXPOSE 8080

# Run the application
ENTRYPOINT ["java", "-jar", "app.jar"]

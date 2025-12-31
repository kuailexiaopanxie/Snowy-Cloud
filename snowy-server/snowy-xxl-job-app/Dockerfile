# ========================================
# Stage 1: Maven Build
# ========================================
FROM maven:3.9-amazoncorretto-17 AS builder

# Set working directory
WORKDIR /build

# Copy all required pom.xml (build parent chain)
COPY pom.xml .
COPY snowy-base/pom.xml snowy-base/
COPY snowy-base/snowy-common/pom.xml snowy-base/snowy-common/
COPY snowy-base/snowy-common/src snowy-base/snowy-common/src

# Install parent chain to local repository in order
# 1. Install root pom (snowy-cloud)
RUN mvn install -N -DskipTests
# 2. Install snowy-base pom
RUN mvn -f snowy-base/pom.xml install -N -DskipTests
# 3. Install snowy-common
RUN mvn -f snowy-base/snowy-common/pom.xml clean install -DskipTests -B

# Copy snowy-xxl-job-app
COPY snowy-server/pom.xml snowy-server/
COPY snowy-server/snowy-xxl-job-app/pom.xml snowy-server/snowy-xxl-job-app/
COPY snowy-server/snowy-xxl-job-app/src snowy-server/snowy-xxl-job-app/src

# Build snowy-xxl-job-app
RUN mvn -f snowy-server/snowy-xxl-job-app/pom.xml clean package -DskipTests -B

# ========================================
# Stage 2: Runtime
# ========================================
FROM amazoncorretto:17

# Set working directory
WORKDIR /app

# Copy JAR file from build stage
COPY --from=builder /build/snowy-server/snowy-xxl-job-app/target/snowy-xxl-job-app.jar ./app.jar

# Create logs directory
RUN mkdir -p /app/logs

# Expose port
EXPOSE 9004

# JVM parameters optimized for XXL-Job scheduling service
ENV JAVA_OPTS="-Xms256m -Xmx512m -XX:+UseG1GC -XX:MaxGCPauseMillis=200"

# Start application
ENTRYPOINT ["sh", "-c", "java $JAVA_OPTS -jar app.jar"]

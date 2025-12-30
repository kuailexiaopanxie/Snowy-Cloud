# ========================================
# Stage 1: Maven Build
# ========================================
FROM maven:3.9-amazoncorretto-17 AS builder

# Set working directory
WORKDIR /build

# Copy parent poms and snowy-common source (dependency chain)
COPY pom.xml .
COPY snowy-base/pom.xml snowy-base/
COPY snowy-base/snowy-common/pom.xml snowy-base/snowy-common/
COPY snowy-base/snowy-common/src snowy-base/snowy-common/src

# Build dependency chain: root -> snowy-base -> snowy-common
RUN mvn install -N -DskipTests && \
    mvn -f snowy-base/pom.xml install -N -DskipTests && \
    mvn -f snowy-base/snowy-common/pom.xml clean install -DskipTests -B

# Copy sentinel project files
COPY snowy-server/pom.xml snowy-server/
COPY snowy-server/snowy-sentinel-app/pom.xml snowy-server/snowy-sentinel-app/
COPY snowy-server/snowy-sentinel-app/src snowy-server/snowy-sentinel-app/src

# Build sentinel (dependencies now available in local .m2 repository)
RUN mvn -f snowy-server/snowy-sentinel-app/pom.xml clean package -DskipTests -B

# ========================= ===============
# Stage 2: Runtime
# ========================================
FROM amazoncorretto:17

# Set working directory
WORKDIR /app

# Copy JAR file from build stage
COPY --from=builder /build/snowy-server/snowy-sentinel-app/target/sentinel-dashboard.jar ./app.jar

# Create logs directory
RUN mkdir -p /app/logs

# Expose port
EXPOSE 9002

# JVM parameters optimization
ENV JAVA_OPTS="-Xms192m -Xmx384m -XX:+UseG1GC -XX:MaxGCPauseMillis=200"

# Start application
ENTRYPOINT ["sh", "-c", "java $JAVA_OPTS -jar app.jar"]

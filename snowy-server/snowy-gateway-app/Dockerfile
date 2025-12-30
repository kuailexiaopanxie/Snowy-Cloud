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

# Copy and build snowy-plugin modules (gateway depends on snowy-plugin-auth-api)
COPY snowy-plugin/pom.xml snowy-plugin/
COPY snowy-plugin/snowy-plugin-auth/pom.xml snowy-plugin/snowy-plugin-auth/
COPY snowy-plugin/snowy-plugin-auth/snowy-plugin-auth-api/pom.xml snowy-plugin/snowy-plugin-auth/snowy-plugin-auth-api/
COPY snowy-plugin/snowy-plugin-auth/snowy-plugin-auth-api/src snowy-plugin/snowy-plugin-auth/snowy-plugin-auth-api/src

# Build snowy-plugin-auth-api
RUN mvn -f snowy-plugin/pom.xml install -N -DskipTests && \
    mvn -f snowy-plugin/snowy-plugin-auth/pom.xml install -N -DskipTests && \
    mvn -f snowy-plugin/snowy-plugin-auth/snowy-plugin-auth-api/pom.xml clean install -DskipTests -B

# Copy gateway project files
COPY snowy-server/pom.xml snowy-server/
COPY snowy-server/snowy-gateway-app/pom.xml snowy-server/snowy-gateway-app/
COPY snowy-server/snowy-gateway-app/src snowy-server/snowy-gateway-app/src

# Build gateway (dependencies now available in local .m2 repository)
RUN mvn -f snowy-server/snowy-gateway-app/pom.xml clean package -DskipTests -B

# ========================================
# Stage 2: Runtime
# ========================================
FROM amazoncorretto:17

# Set working directory
WORKDIR /app

# Copy JAR file from build stage
COPY --from=builder /build/snowy-server/snowy-gateway-app/target/snowy-gateway-app.jar ./app.jar

# Create logs directory
RUN mkdir -p /app/logs

# Expose port
EXPOSE 9003

# JVM parameters optimization (WebFlux reactive architecture)
ENV JAVA_OPTS="-Xms256m -Xmx512m -XX:+UseG1GC -XX:MaxGCPauseMillis=200 -XX:+DisableExplicitGC"

# Start application
ENTRYPOINT ["sh", "-c", "java $JAVA_OPTS -jar app.jar"]

# ========================================
# Stage 1: Maven Build
# ========================================
FROM maven:3.9-amazoncorretto-17 AS builder

# Set working directory
WORKDIR /build

# Copy all pom.xml files (root, snowy-server, snowy-nacos-app)
COPY pom.xml .
COPY snowy-server/pom.xml snowy-server/
COPY snowy-server/snowy-nacos-app/pom.xml snowy-server/snowy-nacos-app/

# Copy source code
COPY snowy-server/snowy-nacos-app/src snowy-server/snowy-nacos-app/src

# Build directly, skipping parent module validation
RUN mvn -f snowy-server/snowy-nacos-app/pom.xml clean package -DskipTests -B

# ========================================
# Stage 2: Runtime
# ========================================
FROM amazoncorretto:17

# Set working directory
WORKDIR /app

# Copy JAR file from builder stage
COPY --from=builder /build/snowy-server/snowy-nacos-app/target/snowy-nacos-app.jar ./app.jar

# Create log directory
RUN mkdir -p /app/logs

# Expose port
EXPOSE 8848

# JVM parameters optimization
ENV JAVA_OPTS="-Xms512m -Xmx512m -XX:+UseG1GC -XX:MaxGCPauseMillis=200"

# Health check
HEALTHCHECK --interval=30s --timeout=3s --start-period=60s --retries=3 \
    CMD wget --no-verbose --tries=1 --spider http://localhost:8848/nacos/ || exit 1

# Start application
ENTRYPOINT ["sh", "-c", "java $JAVA_OPTS -jar app.jar"]

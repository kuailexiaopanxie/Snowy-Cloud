# ========================================
# 阶段 1: Maven 构建
# ========================================
FROM maven:3.9-amazoncorretto-17 AS builder

# 设置工作目录
WORKDIR /build

# 复制父 pom 和 snowy-common 源码（依赖链）
COPY pom.xml .
COPY snowy-base/pom.xml snowy-base/
COPY snowy-base/snowy-common/pom.xml snowy-base/snowy-common/
COPY snowy-base/snowy-common/src snowy-base/snowy-common/src

# 构建依赖链：root -> snowy-base -> snowy-common
RUN mvn install -N -DskipTests && \
    mvn -f snowy-base/pom.xml install -N -DskipTests && \
    mvn -f snowy-base/snowy-common/pom.xml clean install -DskipTests -B

# 复制并构建 snowy-plugin 模块（gateway 依赖 snowy-plugin-auth-api）
COPY snowy-plugin/pom.xml snowy-plugin/
COPY snowy-plugin/snowy-plugin-auth/pom.xml snowy-plugin/snowy-plugin-auth/
COPY snowy-plugin/snowy-plugin-auth/snowy-plugin-auth-api/pom.xml snowy-plugin/snowy-plugin-auth/snowy-plugin-auth-api/
COPY snowy-plugin/snowy-plugin-auth/snowy-plugin-auth-api/src snowy-plugin/snowy-plugin-auth/snowy-plugin-auth-api/src

# 构建 snowy-plugin-auth-api
RUN mvn -f snowy-plugin/pom.xml install -N -DskipTests && \
    mvn -f snowy-plugin/snowy-plugin-auth/pom.xml install -N -DskipTests && \
    mvn -f snowy-plugin/snowy-plugin-auth/snowy-plugin-auth-api/pom.xml clean install -DskipTests -B

# 复制 gateway 项目文件
COPY snowy-server/pom.xml snowy-server/
COPY snowy-server/snowy-gateway-app/pom.xml snowy-server/snowy-gateway-app/
COPY snowy-server/snowy-gateway-app/src snowy-server/snowy-gateway-app/src

# 构建 gateway（依赖已在本地 .m2 仓库中可用）
RUN mvn -f snowy-server/snowy-gateway-app/pom.xml clean package -DskipTests -B

# ========================================
# 阶段 2: 运行时
# ========================================
FROM amazoncorretto:17

# 设置工作目录
WORKDIR /app

# 从构建阶段复制 JAR 文件
COPY --from=builder /build/snowy-server/snowy-gateway-app/target/snowy-gateway-app.jar ./app.jar

# 创建日志目录
RUN mkdir -p /app/logs

# 暴露端口
EXPOSE 9003

# JVM 参数优化（WebFlux 响应式架构）
ENV JAVA_OPTS="-Xms256m -Xmx512m -XX:+UseG1GC -XX:MaxGCPauseMillis=200 -XX:+DisableExplicitGC"

# 启动应用
ENTRYPOINT ["sh", "-c", "java $JAVA_OPTS -jar app.jar"]

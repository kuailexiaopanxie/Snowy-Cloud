# ========================================
# 阶段 1: Maven 构建
# ========================================
FROM maven:3.9-amazoncorretto-17 AS builder

# 设置工作目录
WORKDIR /build

# 复制所有必需的 pom.xml（构建 parent 链）
COPY pom.xml .
COPY snowy-base/pom.xml snowy-base/
COPY snowy-base/snowy-common/pom.xml snowy-base/snowy-common/
COPY snowy-base/snowy-common/src snowy-base/snowy-common/src

# 按顺序安装 parent 链到本地仓库
# 1. 安装根 pom (snowy-cloud)
RUN mvn install -N -DskipTests
# 2. 安装 snowy-base pom
RUN mvn -f snowy-base/pom.xml install -N -DskipTests
# 3. 安装 snowy-common
RUN mvn -f snowy-base/snowy-common/pom.xml clean install -DskipTests -B

# 复制 snowy-xxl-job-app
COPY snowy-server/pom.xml snowy-server/
COPY snowy-server/snowy-xxl-job-app/pom.xml snowy-server/snowy-xxl-job-app/
COPY snowy-server/snowy-xxl-job-app/src snowy-server/snowy-xxl-job-app/src

# 构建 snowy-xxl-job-app
RUN mvn -f snowy-server/snowy-xxl-job-app/pom.xml clean package -DskipTests -B

# ========================================
# 阶段 2: 运行时
# ========================================
FROM amazoncorretto:17

# 设置工作目录
WORKDIR /app

# 从构建阶段复制 JAR 文件
COPY --from=builder /build/snowy-server/snowy-xxl-job-app/target/snowy-xxl-job-app.jar ./app.jar

# 创建日志目录
RUN mkdir -p /app/logs

# 暴露端口
EXPOSE 9004

# 为 XXL-Job 调度服务优化的 JVM 参数
ENV JAVA_OPTS="-Xms256m -Xmx512m -XX:+UseG1GC -XX:MaxGCPauseMillis=200"

# 启动应用
ENTRYPOINT ["sh", "-c", "java $JAVA_OPTS -jar app.jar"]

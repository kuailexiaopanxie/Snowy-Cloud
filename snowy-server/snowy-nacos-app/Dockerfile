# ========================================
# 阶段 1: Maven 构建
# ========================================
FROM maven:3.9-amazoncorretto-17 AS builder

# 设置工作目录
WORKDIR /build

# 复制所有 pom.xml 文件（根目录、snowy-server、snowy-nacos-app）
COPY pom.xml .
COPY snowy-server/pom.xml snowy-server/
COPY snowy-server/snowy-nacos-app/pom.xml snowy-server/snowy-nacos-app/

# 复制源代码
COPY snowy-server/snowy-nacos-app/src snowy-server/snowy-nacos-app/src

# 直接构建，跳过父模块验证
RUN mvn -f snowy-server/snowy-nacos-app/pom.xml clean package -DskipTests -B

# ========================================
# 阶段 2: 运行时
# ========================================
FROM amazoncorretto:17

# 设置工作目录
WORKDIR /app

# 从构建阶段复制 JAR 文件
COPY --from=builder /build/snowy-server/snowy-nacos-app/target/snowy-nacos-app.jar ./app.jar

# 创建日志目录
RUN mkdir -p /app/logs

# 暴露端口
EXPOSE 8848

# JVM 参数优化
ENV JAVA_OPTS="-Xms256m -Xmx512m -XX:+UseG1GC -XX:MaxGCPauseMillis=200"

# 启动应用
ENTRYPOINT ["sh", "-c", "java $JAVA_OPTS -jar app.jar"]

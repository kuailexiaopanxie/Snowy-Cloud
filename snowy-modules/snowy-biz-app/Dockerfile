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

# 复制所有 snowy-plugin 模块（一次性构建整个插件目录）
COPY snowy-plugin/pom.xml snowy-plugin/
COPY snowy-plugin/snowy-plugin-auth snowy-plugin/snowy-plugin-auth
COPY snowy-plugin/snowy-plugin-biz snowy-plugin/snowy-plugin-biz
COPY snowy-plugin/snowy-plugin-client snowy-plugin/snowy-plugin-client
COPY snowy-plugin/snowy-plugin-dev snowy-plugin/snowy-plugin-dev
COPY snowy-plugin/snowy-plugin-gen snowy-plugin/snowy-plugin-gen
COPY snowy-plugin/snowy-plugin-mobile snowy-plugin/snowy-plugin-mobile
COPY snowy-plugin/snowy-plugin-mocker snowy-plugin/snowy-plugin-mocker
COPY snowy-plugin/snowy-plugin-sys snowy-plugin/snowy-plugin-sys

# 构建所有插件模块（Maven 会自动处理模块间依赖）
RUN mvn -f snowy-plugin/pom.xml clean install -DskipTests -B

# 复制 biz-app 项目文件
COPY snowy-modules/pom.xml snowy-modules/
COPY snowy-modules/snowy-biz-app/pom.xml snowy-modules/snowy-biz-app/
COPY snowy-modules/snowy-biz-app/src snowy-modules/snowy-biz-app/src

# 构建 biz-app（依赖已在本地 .m2 仓库中可用）
RUN mvn -f snowy-modules/snowy-biz-app/pom.xml clean package -DskipTests -B

# ========================================
# 阶段 2: 运行时
# ========================================
FROM amazoncorretto:17

# 设置工作目录
WORKDIR /app

# 从构建阶段复制 JAR 文件
COPY --from=builder /build/snowy-modules/snowy-biz-app/target/snowy-biz-app.jar ./app.jar

# 创建日志目录
RUN mkdir -p /app/logs

# 暴露端口
EXPOSE 9102

# JVM 参数优化（业务应用）
ENV JAVA_OPTS="-Xms256m -Xmx512m -XX:+UseG1GC -XX:MaxGCPauseMillis=200"

# 启动应用
ENTRYPOINT ["sh", "-c", "java $JAVA_OPTS -jar app.jar"]

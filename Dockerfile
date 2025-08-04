# =========================================================================
# Stage 1: Build Stage - 编译所有源码 
# =========================================================================
FROM maven:3.9.11-eclipse-temurin-8-noble AS build

WORKDIR /build

# 复制主pom和各模块pom，加快依赖下载
COPY pom.xml .
COPY mall-common/pom.xml mall-common/
COPY mall-mbg/pom.xml mall-mbg/
COPY mall-security/pom.xml mall-security/
COPY mall-admin/pom.xml mall-admin/
COPY mall-portal/pom.xml mall-portal/
COPY mall-search/pom.xml mall-search/
COPY mall-demo/pom.xml mall-demo/

# 预下载依赖，离线构建更快
RUN mvn dependency:go-offline -B

# 复制源码
COPY mall-common/src mall-common/src/
COPY mall-mbg/src mall-mbg/src/
COPY mall-security/src mall-security/src/
COPY mall-admin/src mall-admin/src/
COPY mall-portal/src mall-portal/src/
COPY mall-search/src mall-search/src/
COPY mall-demo/src mall-demo/src/

# 构建指定服务，跳过测试
ARG SERVICE_NAME=mall-admin
RUN mvn clean install -pl ${SERVICE_NAME} -am -DskipTests

# =========================================================================
# Stage 2: Runner Stage - 创建最终运行的镜像 (修正版)
# =========================================================================
FROM eclipse-temurin:8-jre-noble


# 创建 malluser 用户和用户组，避免用 root 运行
RUN groupadd --gid 2001 mallgroup && \
    useradd --uid 2001 --gid 2001 -m malluser

WORKDIR /app

# 复制 jar 包到运行环境
ARG SERVICE_NAME=mall-admin
COPY --from=build /build/${SERVICE_NAME}/target/${SERVICE_NAME}-*.jar app.jar

# 修改 jar 包属主
RUN chown malluser:mallgroup app.jar

# 生成启动脚本，支持参数透传
RUN cat > /entrypoint.sh << 'EOF'
#!/bin/sh
set -e

# 如果第一个参数是 -jar，或者命令是空，我们就认为是启动 java
# 这是一个更健壮的判断
if [ "$1" = '-jar' ] || [ $# -eq 0 ]; then
    exec java ${JAVA_OPTS} -jar /app/app.jar "$@"
else
    # 否则，直接执行用户传入的命令
    exec "$@"
fi
EOF

# 设置脚本权限和属主
RUN chown malluser:mallgroup /entrypoint.sh && chmod +x /entrypoint.sh 
RUN mkdir -p /var/logs/spring.log/debug /var/logs/spring.log/error && \
    chown -R malluser:mallgroup /var/logs
USER malluser

# 设置容器启动入口
ENTRYPOINT ["/entrypoint.sh"]

# 暴露应用端口
EXPOSE 8080

# CMD 现在可以为空，由 entrypoint.sh 脚本处理
CMD []

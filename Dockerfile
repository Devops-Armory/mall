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

# 从本地复制 entrypoint.sh 脚本到镜像中
COPY entrypoint.sh /entrypoint.sh

# 修改 jar 包属主
RUN chown malluser:mallgroup app.jar && \
    chown malluser:mallgroup /entrypoint.sh && \
    chmod +x /entrypoint.sh


# 创建日志目录并授权
RUN mkdir -p /var/logs/spring.log/debug /var/logs/spring.log/error && \
    chown -R malluser:mallgroup /var/logs

USER malluser

# 设置容器启动入口
ENTRYPOINT ["/entrypoint.sh"]

# 暴露应用端口
EXPOSE 8080

# 默认命令，entrypoint.sh 会处理它
CMD []

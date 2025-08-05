#!/bin/sh
# 当任何命令失败时，立即退出脚本
set -e

# 这是一个灵活的启动脚本逻辑：
# 如果用户运行 `docker run` 时没有提供任何命令，
# 或者提供的第一个命令是 '-jar' 我们就默认执行 Java 应用。
if [ "$1" = '-jar' ] || [ $# -eq 0 ]; then
    # 使用 exec 命令，这会让 Java 应用成为容器的主进程 (PID 1)
    # 这样它就能正确地接收和处理来自 Docker 的信号 (比如停止信号)
    # ${JAVA_OPTS} 是一个环境变量，允许我们在启动容器时动态传入JVM参数
    exec java ${JAVA_OPTS} -jar /app/app.jar "$@"
else
    # 否则，如果用户在 `docker run` 后面提供了其他命令 (比如 `sh`)，
    # 我们就直接执行那个命令。这对于调试容器非常有用。
    exec "$@"
fi

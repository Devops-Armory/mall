## 构建不同的服务

确保你在项目的根目录下执行命令。使用 `--build-arg` 标志来传递服务名。

### 构建 mall-admin 服务

```bash
docker build -t mall-admin:latest --build-arg SERVICE_NAME=mall-admin .
```

### 构建 mall-portal 服务

```bash
docker build -t mall-portal:latest --build-arg SERVICE_NAME=mall-portal .
```

### 构建 mall-search 服务

```bash
docker build -t mall-search:latest --build-arg SERVICE_NAME=mall-search .
```

---
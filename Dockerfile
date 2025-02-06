# 使用多阶段构建减少镜像体积
# 阶段1：构建 Snell Server 二进制
FROM golang:1.19-alpine AS builder

# 安装编译依赖
RUN apk add --no-cache git make

# 克隆 Snell 源码
RUN git clone https://github.com/surge-networks/snell.git /snell \
    && cd /snell \
    && git checkout v3.0.1  # 指定版本

# 编译 Snell
WORKDIR /snell
RUN make && mv snell /snell-server

# 阶段2：生成最终镜像
FROM alpine:3.18

# 复制编译好的二进制和配置文件
COPY --from=builder /snell-server /usr/local/bin/snell-server
COPY snell.conf /etc/snell/snell.conf

# 安装依赖（如需要）
RUN apk add --no-cache libcap \
    && setcap 'cap_net_bind_service=+ep' /usr/local/bin/snell-server

# 暴露端口
EXPOSE ${PORT:-8080}

# 启动命令
CMD ["snell-server", "--config", "/etc/snell/snell.conf"]

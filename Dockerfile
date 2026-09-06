# model-downloader
# 容器内下载 AI 模型到宿主机挂载目录,镜像本身不预设/不改动任何缓存目录,
# 缓存位置完全由用户 docker run 时通过环境变量传入。
#
# 参考: alexcheng1982/model-downloader(去掉了硬编码 /model-files-cache)

FROM python:3.12-alpine

# alpine 基础工具(下载与调试用)
RUN apk add --no-cache bash curl wget ca-certificates

WORKDIR /workspace

COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt && rm requirements.txt

# 约定俗成的挂载点:宿主机目录挂到这里,模型即落在宿主机
VOLUME ["/models"]

# 注意:此处【不】设置 HF_HOME / MODELSCOPE_CACHE 等任何缓存目录变量,
# 全部由用户在 docker run 时传入(见 README),镜像对缓存策略零干预。
COPY entrypoint.sh /usr/local/bin/model-downloader
RUN chmod +x /usr/local/bin/model-downloader

ENTRYPOINT ["model-downloader"]

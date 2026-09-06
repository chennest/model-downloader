# model-downloader

在容器里下载 AI 模型到**宿主机目录**的最小镜像。内置 [HuggingFace CLI](https://huggingface.co/docs/huggingface_hub/guides/cli) 与 [ModelScope](https://github.com/modelscope/modelscope),模型文件通过挂载卷直接落盘,容器用完即弃。

灵感来自 [alexcheng1982/model-downloader](https://github.com/alexcheng1982/model-downloader),主要差异:

| | alexcheng1982/model-downloader | 本仓库 |
|---|---|---|
| 基础镜像 | python:3.12-alpine | python:3.12-alpine |
| 缓存目录 | 镜像内写死 `/model-files-cache`(`ENV` 硬编码) | **零预设零干预**,完全由用户 `-e` 按生态标准变量传入 |
| 国内加速 | 不支持 | `HF_ENDPOINT` / `MODELSCOPE_ENDPOINT` 原生支持 |
| 入口 | 固定 `hf` | `hf` / `ms` / 任意命令透传 |
| 用途 | 通用下载 | 只下载到本地挂载目录 |

## 构建

```sh
docker build -t model-downloader .
```

## 自动发版(打 tag 即发布)

推送 `vX.Y.Z` 格式的 tag 会触发 GitHub Actions 自动构建并发布到 **GHCR**(`ghcr.io/chennest/model-downloader`):

```sh
git tag v0.1.0
git push origin v0.1.0
```

- 镜像 tag 规则:`v0.1.0` → 同时发布 `0.1.0` 与 `latest`
- **GitHub Release 同步自动创建**(release notes 自动生成,基于两次 tag 之间的提交)
- 构建日志与 Release:仓库 Actions / Releases 页面查看
- 拉取:

```sh
docker pull ghcr.io/chennest/model-downloader:v0.1.0
```

## 用法(复制即用)

镜像不做任何缓存目录假设,只透传标准环境变量给底层 CLI。**设了哪些变量、模型就落在哪**。

### 标准模板 ①:HuggingFace(hf)——已带国内镜像

容器内固定挂载 `/models`(宿主机目录自选),国内加速走 hf-mirror:

```sh
docker run --rm -v "$PWD/models:/models" \
    -e HF_ENDPOINT=https://hf-mirror.com \
    -e HF_HOME=/models \
    model-downloader hf download Qwen/Qwen2.5-7B-Instruct
```

- `-v "$PWD/models:/models"`:宿主机 `./models` → 容器内 `/models`,模型落盘到宿主机
- `-e HF_ENDPOINT=https://hf-mirror.com`:**国内下载加速镜像**(必带,否则直连 huggingface.co 会失败/极慢)
- `-e HF_HOME=/models`:模型缓存写到容器内 `/models`,与挂载点对齐

### 标准模板 ②:ModelScope(ms)

```sh
docker run --rm -v "$PWD/models:/models" \
    -e MODELSCOPE_CACHE=/models \
    model-downloader ms download --model Qwen/Qwen2.5-7B-Instruct
```

- `-v "$PWD/models:/models"`:宿主机 `./models` → 容器内 `/models`,模型落盘到宿主机
- `-e MODELSCOPE_CACHE=/models`:模型缓存写到容器内 `/models`,与挂载点对齐

> 两个模板统一规则:**宿主机目录随意,容器内目录固定 `/models`**,下载结果都在宿主机的 `./models` 下(模型较多时建议挂到独立大磁盘)。

### 支持的环境变量(全部原样透传)

**HuggingFace(hf)**

| 变量 | 说明 | 示例 |
|---|---|---|
| `HF_HOME` | 缓存根目录 | `-e HF_HOME=/models` |
| `HF_HUB_CACHE` | 仅指定模型缓存目录 | `-e HF_HUB_CACHE=/models/hub` |
| `HF_ENDPOINT` | API 地址,**国内加速填 hf-mirror** | `-e HF_ENDPOINT=https://hf-mirror.com` |
| `HF_TOKEN` | 访问 gated/私有模型的令牌 | `-e HF_TOKEN=hf_xxx` |

**ModelScope(ms)**

| 变量 | 说明 | 示例 |
|---|---|---|
| `MODELSCOPE_CACHE` | 模型缓存根目录 | `-e MODELSCOPE_CACHE=/models` |
| `MODELSCOPE_ENDPOINT` | API 地址(国内一般不需要改) | `-e MODELSCOPE_ENDPOINT=https://www.modelscope.cn` |

> 入口脚本每次启动会打印当前生效的下载配置(缓存目录 / 加速地址),可据此确认模型实际落盘位置。

### 下载到平铺目录(不用 HF 缓存结构)

HuggingFace CLI 原生支持 `--local-dir`,直接平铺下载,不产生 `hub/` 缓存目录:

```sh
docker run --rm -v "$PWD/models:/models" \
    -e HF_ENDPOINT=https://hf-mirror.com \
    model-downloader hf download Qwen/Qwen2.5-7B-Instruct \
    --local-dir /models/Qwen2.5-7B-Instruct
```

### 其他命令

`hf` / `ms` 之外任意命令原样透传,方便进容器排查:

```sh
docker run --rm -v "$PWD/models:/models" model-downloader sh -c "ls -lh /models"
```

## 示例:预下载 vLLM 要用的模型

```sh
MODEL=Qwen/Qwen2.5-7B-Instruct
docker run --rm \
    -v "$PWD/models:/models" \
    -e HF_ENDPOINT=https://hf-mirror.com \
    -e HF_HOME=/models \
    model-downloader hf download "$MODEL"

# 之后 vLLM 直接指向宿主机目录即可
# (容器内缓存结构:/models/hub/<repo> 镜像了 HF 官方缓存布局)
docker run --rm --gpus all -v "$PWD/models:/models" \
    vllm/vllm-openai --model /models/hub/$MODEL --port 8000
```

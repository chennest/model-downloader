# model-downloader

在容器里下载 AI 模型到**宿主机目录**的最小镜像。内置 [HuggingFace CLI](https://huggingface.co/docs/huggingface_hub/guides/cli) 与 [ModelScope](https://github.com/modelscope/modelscope),模型文件通过挂载卷直接落盘,容器用完即弃。

灵感来自 [alexcheng1982/model-downloader](https://github.com/alexcheng1982/model-downloader),主要差异:

| | alexcheng1982/model-downloader | 本仓库 |
|---|---|---|
| 基础镜像 | python:3.12-alpine | python:3.12-alpine |
| 缓存目录 | 镜像内写死 `/model-files-cache`(`ENV` 硬编码) | **不预设、不改动**,完全由用户 `-e` 传入 |
| 入口 | 固定 `hf` | `hf` / `ms` / 任意命令透传 |
| 用途 | 通用下载 | 只下载到本地挂载目录 |

## 构建

```sh
docker build -t model-downloader .
```

## 用法

```sh
# HuggingFace:模型下到宿主机 ./models 目录
docker run --rm -v "$PWD/models:/models" \
    -e HF_HOME=/models \
    model-downloader hf download Qwen/Qwen2.5-7B-Instruct

# ModelScope
docker run --rm -v "$PWD/models:/models" \
    -e MODELSCOPE_CACHE=/models \
    model-downloader ms download --model Qwen/Qwen2.5-7B-Instruct
```

### 缓存目录怎么传(核心设计)

镜像**零干预**缓存目录。三种方式任选:

| 方式 | 示例 | 说明 |
|---|---|---|
| `HF_HOME` | `-e HF_HOME=/models` | HuggingFace 缓存根 |
| `MODELSCOPE_CACHE` | `-e MODELSCOPE_CACHE=/models` | ModelScope 缓存根 |
| `CACHE_DIR` | `-e CACHE_DIR=/models` | 一键同时设置以上两者(已单独设置的不受影响) |

都不传则用各 CLI 的默认路径(容器内 `~/.cache/...`),此时模型不会落到宿主机,注意用 `-v` 挂载。

### 下载到平铺目录(不用 HF 缓存结构)

HuggingFace CLI 原生支持 `--local-dir`,直接平铺下载,不产生 `hub/` 缓存目录:

```sh
docker run --rm -v "$PWD/models:/models" \
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
    -e CACHE_DIR=/models \
    model-downloader hf download "$MODEL"

# 之后 vLLM 直接指向宿主机目录即可
docker run --rm --gpus all -v "$PWD/models:/models" \
    vllm/vllm-openai --model /models/hub/$MODEL --port 8000
```

#!/usr/bin/env bash
set -euo pipefail

# ============================================================
# model-downloader entrypoint
#
# 设计原则:镜像【零干预】——不预设、不改写、不发明变量。
# 缓存目录 / 国内加速源 / Token 等一律遵循各生态标准环境变量,
# 用户 docker run -e 传入什么,容器内就是什么,原样透传。
#
#   HuggingFace: HF_HOME | HF_HUB_CACHE | HF_ENDPOINT | HF_TOKEN ...
#   ModelScope : MODELSCOPE_CACHE | MODELSCOPE_ENDPOINT | MODELSCOPE_TOKEN ...
# ============================================================

echo "[model-downloader] 当前生效的下载配置(未设置则用 CLI 默认):"
echo "  HF_HOME          = ${HF_HOME:-<默认 ~/.cache/huggingface>}"
echo "  HF_ENDPOINT      = ${HF_ENDPOINT:-<默认 huggingface.co>}   # 国内加速填 https://hf-mirror.com"
echo "  MODELSCOPE_CACHE = ${MODELSCOPE_CACHE:-<默认 ~/.cache/modelscope>}"
echo "  MODELSCOPE_ENDPOINT = ${MODELSCOPE_ENDPOINT:-<默认 modelscope.cn>}"

# 无参数:打印用法
if [[ $# -eq 0 ]]; then
    cat <<'EOF'

用法: docker run --rm -v $PWD/models:/models \
        -e HF_HOME=/models \
        <image> hf download Qwen/Qwen2.5-7B-Instruct

  <image>  hf ...   透传 HuggingFace CLI,如: hf download <repo> [--local-dir ...]
  <image>  ms ...   透传 ModelScope CLI,如: ms download --model <model_id> [--local_dir ...]
  <image>  help     显示本帮助

示例(国内加速 + 指定落盘目录):
  docker run --rm -v $PWD/models:/models \
    -e HF_ENDPOINT=https://hf-mirror.com \
    -e HF_HOME=/models \
    <image> hf download Qwen/Qwen2.5-7B-Instruct

  docker run --rm -v $PWD/models:/models \
    -e MODELSCOPE_CACHE=/models \
    <image> ms download --model Qwen/Qwen2.5-7B-Instruct
EOF
    exit 0
fi

case "$1" in
    hf)
        shift
        exec hf "$@"
        ;;
    ms)
        shift
        exec modelscope "$@"
        ;;
    help|-h|--help)
        echo "用法见仓库 README"
        ;;
    *)
        # 其他命令直接执行,保留逃生口(如 sh、ls 排查)
        exec "$@"
        ;;
esac

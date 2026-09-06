#!/usr/bin/env bash
set -euo pipefail

# ============================================================
# model-downloader entrypoint
#
# 设计原则:镜像【不预设、不改写】任何缓存目录。
# 用户通过 docker run -e 传入的 HF_HOME / MODELSCOPE_CACHE 等
# 环境变量原样生效;若只传一个 CACHE_DIR,则同时作为两者缓存根。
# ============================================================

# 统一便捷入口:CACHE_DIR 同时作用于 HF 与 ModelScope(已单独传 HF_* / MODELSCOPE_* 则不覆盖)
if [[ -n "${CACHE_DIR:-}" ]]; then
    export HF_HOME="${HF_HOME:-$CACHE_DIR}"
    export MODELSCOPE_CACHE="${MODELSCOPE_CACHE:-$CACHE_DIR}"
fi

echo "[model-downloader] HF_HOME=${HF_HOME:-默认 ~/.cache/huggingface}"
echo "[model-downloader] MODELSCOPE_CACHE=${MODELSCOPE_CACHE:-默认 ~/.cache/modelscope}"

# 无参数:打印用法
if [[ $# -eq 0 ]]; then
    cat <<'EOF'

用法: docker run --rm -v $PWD/models:/models \
        -e CACHE_DIR=/models \
        <image> hf download Qwen/Qwen2.5-7B-Instruct

  <image>  hf ...   透传 HuggingFace CLI,如: hf download <repo> [--local-dir ...]
  <image>  ms ...   透传 ModelScope CLI,如: ms download --model <model_id> [--local_dir ...]
  <image>  help     显示本帮助

缓存目录(任选其一,都不传则用各 CLI 默认):
  -e HF_HOME=/path            指定 HuggingFace 缓存根
  -e MODELSCOPE_CACHE=/path   指定 ModelScope 缓存根
  -e CACHE_DIR=/path          一键同时设置以上两者(已单独设置的不受影响)
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
        echo "用法见 https://github.com/<you>/model-downloader 的 README"
        ;;
    *)
        # 其他命令直接执行,保留逃生口(如 sh、ls 排查)
        exec "$@"
        ;;
esac

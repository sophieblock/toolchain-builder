#!/usr/bin/env bash
set -euo pipefail

# Build a wheel for a *consumer* project (e.g., Allo) using the exported LLVM/MLIR toolchain.
# Assumes you already ran download_and_setup.sh and eval'ed toolchain-builder exports in your conda env.
# Usage:
#   bash scripts/build_consumer_wheel.sh /path/to/consumer_repo
# The wheel is written to <consumer_repo>/dist/

if [[ $# -ne 1 ]]; then
  echo "Usage: $0 /path/to/consumer_repo" >&2
  exit 1
fi

CONSUMER_DIR="$1"

# Ensure we're in a conda env
if [[ -z "${CONDA_PREFIX:-}" ]]; then
  echo "Please 'conda activate <env>' first." >&2
  exit 1
fi

# Ensure toolchain env vars are set (best effort)
if [[ -z "${LLVM_BUILD_DIR:-}" ]]; then
  if command -v toolchain-builder >/dev/null 2>&1; then
    eval "$(toolchain-builder)"
  else
    echo "toolchain-builder CLI not found; run 'python -m pip install -e .' in this repo." >&2
    exit 1
  fi
fi

mkdir -p "${CONSUMER_DIR}/dist"
# Use conda environment's Python explicitly to avoid externally-managed-environment errors
"${CONDA_PREFIX}/bin/python" -m pip wheel "${CONSUMER_DIR}" -w "${CONSUMER_DIR}/dist"
echo ">> Wheel(s) written to ${CONSUMER_DIR}/dist:"
ls -lh "${CONSUMER_DIR}/dist"
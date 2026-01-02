#!/usr/bin/env bash
set -euo pipefail

# Create and activate a conda env for building/using the toolchain locally
# Usage:
#   bash scripts/create_conda_env.sh [env_name]
# Default env name: qrew-llvm

ENV_NAME="${1:-qrew-llvm}"

if ! command -v conda >/dev/null 2>&1; then
  echo "Conda not found. Install Miniforge/Mambaforge or Anaconda, then retry." >&2
  exit 1
fi
CONDA_VERSION_RAW="$(conda --version | awk '{print $2}')"
CONDA_MAJOR="${CONDA_VERSION_RAW%%.*}"
if [[ "${CONDA_MAJOR}" -lt 25 ]]; then
  echo "Conda >=25.x is required (found ${CONDA_VERSION_RAW}). Please upgrade Miniforge/Rattler." >&2
  exit 1
fi

# Create env with Python, pip, and build helpers
conda create -y -n "${ENV_NAME}" python=3.12 cmake ninja pip
# shellcheck disable=SC1091
source "$(conda info --base)/etc/profile.d/conda.sh"
conda activate "${ENV_NAME}"

# Install this repo's helper CLI in editable mode
# Use the conda environment's pip explicitly to avoid externally-managed-environment errors
"${CONDA_PREFIX}/bin/python" -m pip install -U pip wheel
"${CONDA_PREFIX}/bin/python" -m pip install -e .

echo ">> Conda env '${ENV_NAME}' ready and activated."
python -V
echo ">> Next:"
echo "   1) export GITHUB_REPOSITORY=OWNER/REPO"
echo "   2) bash scripts/download_and_setup.sh"
echo "   3) eval \"\$(toolchain-builder)\""

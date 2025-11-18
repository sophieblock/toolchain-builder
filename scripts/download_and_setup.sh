#!/usr/bin/env bash
set -euo pipefail

# macOS arm64 only: download the latest toolchain artifact, extract to cache, and print export instructions.
# Requires: gh CLI (authenticated) OR manual download from Releases.

OS="$(uname -s)"
ARCH="$(uname -m)"
if [[ "$OS" != "Darwin" || "$ARCH" != "arm64" ]]; then
  echo "This script supports macOS arm64 only." >&2
  exit 1
fi

TRIPLET="macos-arm64"
CACHE_DIR="${HOME}/.cache/toolchain-builder/llvm-mlir/${TRIPLET}"
BUILD_DIR="${CACHE_DIR}/build"
mkdir -p "${CACHE_DIR}"

REPO="${GITHUB_REPOSITORY:-.}"
if [[ "${REPO}" == "." ]]; then
  echo "Set GITHUB_REPOSITORY=owner/repo or run inside a GitHub Actions job."
fi

echo ">> Downloading latest toolchain for ${TRIPLET} into ${CACHE_DIR}"
if command -v gh >/dev/null 2>&1; then
  gh release download --repo "${REPO}" --pattern "*${TRIPLET}*.tar.gz" --dir "${CACHE_DIR}" --clobber || {
    echo "Failed to download via gh. Please download from the Releases page manually."
    exit 1
  }
else
  echo "Install GitHub CLI (gh) or manually download from the Releases page."
  exit 1
fi

TARBALL="$(ls -1 "${CACHE_DIR}"/*"${TRIPLET}"*.tar.gz | head -n1)"
if [[ ! -f "$TARBALL" ]]; then
  echo "No tarball found for ${TRIPLET} in ${CACHE_DIR}" >&2
  exit 1
fi

mkdir -p "${BUILD_DIR}"
tar -C "${BUILD_DIR}" -xzf "${TARBALL}"

echo
echo ">> To set environment for this shell, run:"
echo "eval \"\$(python -m toolchain_builder --build-dir '${BUILD_DIR}')\""
echo

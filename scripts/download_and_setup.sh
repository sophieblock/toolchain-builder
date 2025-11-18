#!/bin/bash
# Script to download and setup LLVM/MLIR toolchain and Allo wheel

set -e

# Default values
INSTALL_DIR="${HOME}/.qrew-toolchain"
GITHUB_REPO="sophieblock/toolchain-builder"
VERSION="latest"
PLATFORM=""

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

print_info() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

print_warn() {
    echo -e "${YELLOW}[WARN]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

usage() {
    cat << EOF
Usage: $0 [OPTIONS]

Download and setup LLVM/MLIR 19 (Allo-patched) toolchain and Allo wheel.

OPTIONS:
    -d, --dir DIR          Installation directory (default: ~/.qrew-toolchain)
    -v, --version VERSION  Version tag to download (default: latest)
    -p, --platform PLATFORM Platform: macos-arm64 or linux-x86_64 (auto-detect if not specified)
    -h, --help            Show this help message

EXAMPLES:
    # Install latest version to default location
    $0

    # Install specific version
    $0 --version v0.1.0

    # Install to custom directory
    $0 --dir /opt/qrew-toolchain

    # Specify platform explicitly
    $0 --platform linux-x86_64

ENVIRONMENT:
    After installation, add to your shell profile:
        eval \$(qrew-toolchain)

    Or manually export:
        export LLVM_BUILD_DIR="\${HOME}/.qrew-toolchain/llvm-build"
        export PATH="\${LLVM_BUILD_DIR}/bin:\${PATH}"
EOF
}

detect_platform() {
    local os=$(uname -s)
    local arch=$(uname -m)

    if [[ "$os" == "Darwin" ]]; then
        if [[ "$arch" == "arm64" ]]; then
            echo "macos-arm64"
        else
            print_error "Unsupported macOS architecture: $arch"
            exit 1
        fi
    elif [[ "$os" == "Linux" ]]; then
        if [[ "$arch" == "x86_64" ]]; then
            echo "linux-x86_64"
        else
            print_error "Unsupported Linux architecture: $arch"
            exit 1
        fi
    else
        print_error "Unsupported operating system: $os"
        exit 1
    fi
}

parse_args() {
    while [[ $# -gt 0 ]]; do
        case $1 in
            -d|--dir)
                INSTALL_DIR="$2"
                shift 2
                ;;
            -v|--version)
                VERSION="$2"
                shift 2
                ;;
            -p|--platform)
                PLATFORM="$2"
                shift 2
                ;;
            -h|--help)
                usage
                exit 0
                ;;
            *)
                print_error "Unknown option: $1"
                usage
                exit 1
                ;;
        esac
    done
}

get_latest_release() {
    local repo=$1
    curl -s "https://api.github.com/repos/${repo}/releases/latest" | grep '"tag_name":' | sed -E 's/.*"([^"]+)".*/\1/'
}

download_artifact() {
    local url=$1
    local output=$2

    print_info "Downloading from: $url"

    if command -v curl &> /dev/null; then
        curl -L -o "$output" "$url"
    elif command -v wget &> /dev/null; then
        wget -O "$output" "$url"
    else
        print_error "Neither curl nor wget found. Please install one of them."
        exit 1
    fi
}

main() {
    parse_args "$@"

    # Detect platform if not specified
    if [[ -z "$PLATFORM" ]]; then
        PLATFORM=$(detect_platform)
        print_info "Detected platform: $PLATFORM"
    fi

    # Get latest version if not specified
    if [[ "$VERSION" == "latest" ]]; then
        VERSION=$(get_latest_release "$GITHUB_REPO")
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

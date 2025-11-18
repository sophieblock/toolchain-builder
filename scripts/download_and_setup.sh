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
        if [[ -z "$VERSION" ]]; then
            print_error "Failed to fetch latest release version"
            exit 1
        fi
        print_info "Latest version: $VERSION"
    fi
    
    # Create installation directory
    mkdir -p "$INSTALL_DIR"
    cd "$INSTALL_DIR"
    
    print_info "Installing to: $INSTALL_DIR"
    
    # Construct download URLs
    local base_url="https://github.com/${GITHUB_REPO}/releases/download/${VERSION}"
    local toolchain_file="llvm-mlir-toolchain-${PLATFORM}.tar.gz"
    local allo_file="allo-${PLATFORM}-py3-none-any.whl"
    
    # Download toolchain
    print_info "Downloading LLVM/MLIR toolchain..."
    download_artifact "${base_url}/${toolchain_file}" "${toolchain_file}"
    
    # Extract toolchain
    print_info "Extracting toolchain..."
    tar -xzf "${toolchain_file}"
    rm "${toolchain_file}"
    
    # Download Allo wheel
    print_info "Downloading Allo wheel..."
    download_artifact "${base_url}/${allo_file}" "${allo_file}"
    
    # Install Allo wheel (optional)
    if command -v pip &> /dev/null || command -v pip3 &> /dev/null; then
        print_info "Installing Allo wheel..."
        if command -v pip3 &> /dev/null; then
            pip3 install --force-reinstall "${allo_file}"
        else
            pip install --force-reinstall "${allo_file}"
        fi
    else
        print_warn "pip not found. Allo wheel downloaded but not installed."
        print_warn "You can install it later with: pip install ${INSTALL_DIR}/${allo_file}"
    fi
    
    print_info "Installation complete!"
    echo ""
    print_info "To use the toolchain, add this to your shell profile:"
    echo "    eval \$(qrew-toolchain)"
    echo ""
    print_info "Or set environment variables manually:"
    echo "    export LLVM_BUILD_DIR=\"${INSTALL_DIR}/llvm-build\""
    echo "    export PATH=\"\${LLVM_BUILD_DIR}/bin:\${PATH}\""
}

main "$@"

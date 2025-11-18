# Toolchain Builder

Standalone builder for LLVM/MLIR 19 (Allo-patched) + Allo wheel.

This repository provides automated builds of LLVM/MLIR 19 with Allo-specific patches, along with pre-built Allo Python wheels. It's designed to simplify the setup process for downstream projects like QREW.

## Supported Platforms

- **macOS**: arm64 (Apple Silicon) - `macos-14`
- **Linux**: x86_64 (Ubuntu 24.04) - `ubuntu-24.04`

## Features

- 🔧 Pre-built LLVM/MLIR 19 toolchain with Allo patches
- 🐍 Pre-built Allo Python wheels
- 📦 Automated CI/CD pipeline for reproducible builds
- 🚀 Easy installation with a single command
- 🔌 CLI tool for environment setup

## Quick Start

### Installation

Install the toolchain and Allo wheel with a single command:

```bash
curl -sSL https://raw.githubusercontent.com/sophieblock/toolchain-builder/main/scripts/download_and_setup.sh | bash
```

Or download and run the script manually:

```bash
wget https://raw.githubusercontent.com/sophieblock/toolchain-builder/main/scripts/download_and_setup.sh
chmod +x download_and_setup.sh
./download_and_setup.sh
```

### Custom Installation Directory

```bash
./download_and_setup.sh --dir /opt/qrew-toolchain
```

### Install Specific Version

```bash
./download_and_setup.sh --version v0.1.0
```

## Usage

### Setting Up Environment

After installation, set up your environment with:

```bash
eval $(qrew-toolchain)
```

Or manually export the variables:

```bash
export LLVM_BUILD_DIR="${HOME}/.qrew-toolchain/llvm-build"
export PATH="${LLVM_BUILD_DIR}/bin:${PATH}"
export LD_LIBRARY_PATH="${LLVM_BUILD_DIR}/lib:${LD_LIBRARY_PATH}"
```

### Using the CLI Tool

The `qrew-toolchain` CLI tool helps you set up environment variables:

```bash
# Print exports for bash/zsh (default)
qrew-toolchain

# Print exports for fish shell
qrew-toolchain --shell fish

# Use in your shell profile
echo 'eval $(qrew-toolchain)' >> ~/.bashrc
```

### Installing qrew-toolchain CLI

To install the CLI tool:

```bash
cd toolchain-builder
pip install -e .
```

## Building from Source

The GitHub Actions workflow automatically builds the toolchain for each platform. To build manually:

### Prerequisites

**macOS:**
```bash
brew install cmake ninja ccache
```

**Ubuntu:**
```bash
sudo apt-get update
sudo apt-get install -y cmake ninja-build clang lld ccache python3-dev
```

### Build Steps

1. Clone the Allo repository and get the LLVM SHA:
```bash
git clone https://github.com/sophieblock/allo.git
cd allo
LLVM_SHA=$(git submodule status externals/llvm-project | awk '{print $1}' | sed 's/^-//')
```

2. Clone LLVM at the specific commit:
```bash
git clone https://github.com/llvm/llvm-project.git
cd llvm-project
git checkout $LLVM_SHA
```

3. Apply Allo patches:
```bash
git apply ../allo/externals/llvm_patch
```

4. Build LLVM/MLIR:
```bash
mkdir build && cd build
cmake -G Ninja \
  -DCMAKE_BUILD_TYPE=Release \
  -DLLVM_ENABLE_PROJECTS="mlir" \
  -DLLVM_TARGETS_TO_BUILD="X86;AArch64;NVPTX;AMDGPU" \
  -DLLVM_ENABLE_ASSERTIONS=ON \
  -DMLIR_ENABLE_BINDINGS_PYTHON=ON \
  ../llvm
ninja
```

5. Build Allo wheel:
```bash
cd ../../allo
export LLVM_BUILD_DIR=/path/to/llvm-project/build
python -m build --wheel
```

## CI/CD Pipeline

The repository includes a comprehensive GitHub Actions workflow (`.github/workflows/build-and-release.yml`) that:

1. **Builds LLVM/MLIR Toolchain**:
   - Checks out the Allo repository
   - Extracts LLVM commit SHA from submodules
   - Clones LLVM at the specific commit
   - Applies Allo patches
   - Builds LLVM/MLIR with optimizations
   - Creates a tarball of the build artifacts

2. **Builds Allo Wheel**:
   - Downloads the toolchain artifact
   - Builds Allo using the toolchain
   - Creates platform-specific wheels

3. **Creates Release** (on version tags):
   - Automatically creates a GitHub Release
   - Uploads all artifacts (toolchains and wheels)
   - Includes installation instructions

### Triggering Builds

- **Automatic**: Push to `main` or `develop` branches
- **Tags**: Push a tag matching `v*` (e.g., `v0.1.0`) to create a release
- **Manual**: Use workflow dispatch from GitHub Actions tab

## Project Structure

```
toolchain-builder/
├── .github/
│   └── workflows/
│       └── build-and-release.yml    # CI/CD pipeline
├── scripts/
│   └── download_and_setup.sh        # Installation script
├── src/
│   └── qrew_toolchain/
│       ├── __init__.py
│       └── cli.py                   # CLI tool for env exports
├── pyproject.toml                   # Python package configuration
├── .gitignore
└── README.md
```

## Environment Variables

The toolchain uses the following environment variables:

- `LLVM_BUILD_DIR`: Path to the LLVM build directory
- `QREW_TOOLCHAIN_ROOT`: Root directory of the installed toolchain
- `PATH`: Updated to include LLVM binaries
- `LD_LIBRARY_PATH`: Updated to include LLVM libraries (Linux)

## Contributing

Contributions are welcome! Please ensure:

1. CI pipeline passes on all platforms
2. Changes are documented in the README
3. Version tags follow semantic versioning

## License

This project inherits the license from the LLVM project and Allo. See individual components for details.

## Related Projects

- [Allo](https://github.com/cornell-zhang/allo) - A composable programming model for high-performance ML accelerators
- [LLVM](https://llvm.org/) - The LLVM Compiler Infrastructure
- [MLIR](https://mlir.llvm.org/) - Multi-Level Intermediate Representation

## Troubleshooting

### Toolchain not found

If `qrew-toolchain` reports that the toolchain is not found:

1. Ensure the installation completed successfully
2. Check that `~/.qrew-toolchain` exists
3. Set `QREW_TOOLCHAIN_ROOT` manually if using a custom location

### Build failures

If building from source fails:

1. Ensure all prerequisites are installed
2. Check that you have enough disk space (LLVM builds require ~30GB)
3. Verify the LLVM SHA matches the one in Allo's submodules
4. Check that patches apply cleanly

### Import errors with Allo

If you get import errors when using Allo:

1. Ensure `LLVM_BUILD_DIR` is set correctly
2. Verify the Allo wheel was installed: `pip list | grep allo`
3. Check Python version compatibility (requires Python 3.12+)

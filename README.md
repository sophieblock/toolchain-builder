# Toolchain Builder (macOS arm64, conda‑first)

**Purpose.** Produce a reusable **LLVM/MLIR** build for **macOS arm64** and expose it via environment variables (`LLVM_BUILD_DIR`, `CMAKE_PREFIX_PATH`, etc.) so any project can compile/link against it. This repo does **not** depend on third‑party sources in CI; it only builds stock `llvm-project` at a ref you choose and applies **optional local patches**.

## What the CI does
- Runs on **macOS arm64** (`macos-14`) only.
- Checks out `llvm-project` at `llvm_ref` (default: `llvmorg-19.1.0`).
- Applies optional patches under `patches/` if present.
- Configures with **MLIR Python bindings enabled** and builds with Ninja.
- Uploads a compressed build dir: `llvm-mlir-macos-arm64.tar.gz`.
- On tag pushes (`v*`), publishes artifacts to a GitHub Release.

## One‑time local setup (conda only)
```bash
# 0) Clone this repo, cd into it
git clone https://github.com/<you>/toolchain-builder
cd toolchain-builder

# 1) Create a conda env and install the helper CLI
bash scripts/create_conda_env.sh qrew-llvm      # env name optional (default qrew-llvm)

# 2) Tell the helper where to download from (this repo)
export GITHUB_REPOSITORY=<you>/toolchain-builder

# 3) Download + extract the latest toolchain artifact for macOS arm64
bash scripts/download_and_setup.sh

# 4) Export environment variables into the current shell
eval "$(toolchain-builder)"
# Now you have:
#   LLVM_BUILD_DIR=/Users/<you>/.cache/toolchain-builder/llvm-mlir/macos-arm64/build
#   CMAKE_PREFIX_PATH=$LLVM_BUILD_DIR/lib/cmake:$CMAKE_PREFIX_PATH
#   (optional) LLVM_DIR, MLIR_DIR under $LLVM_BUILD_DIR/lib/cmake
```

## Build a consumer wheel using this toolchain (example: Allo, done outside this repo)
```bash
# With conda env active and env exported via toolchain-builder
# 1) Get your consumer source (fork or local path). Example:
git clone https://github.com/<you>/allo.git   # as an example consumer
# 2) Build a wheel that links against the shared toolchain
bash scripts/build_consumer_wheel.sh ./allo
# 3) Install that wheel locally
python -m pip install ./allo/dist/*.whl
# 4) Quick import smoke test (example for Allo)
python - <<'PY'
import importlib
m = importlib.import_module("allo")
air = importlib.import_module("allo.ir")
print("Import OK:", m.__version__)
print("IR OK:", type(air).__name__)
PY
```

## Reusing the wheel in **other repositories**
**Option A — local path**
```bash
# In another repo's conda env:
python -m pip install /absolute/path/to/allo/dist/allo-<ver>-cp312-*.whl
```

**Option B — GitHub Release URL**
1. Attach your wheel file(s) to a Release in either the consumer repo or this toolchain repo.
2. Install by URL:
```bash
python -m pip install \
  https://github.com/<owner>/<repo>/releases/download/<tag>/allo-<ver>-cp312-*-macosx_12_0_arm64.whl
```
3. Pinning in `requirements.txt`:
```
# requirements.txt
https://github.com/<owner>/<repo>/releases/download/<tag>/allo-<ver>-cp312-*-macosx_12_0_arm64.whl
```

> Tip: keep wheels per‑platform. This repo only ships **macOS arm64** toolchains. If you later add Linux, publish separate artifacts and wheels by platform tag.

## Changing LLVM version or applying patches
- Run the workflow manually with a different `llvm_ref` (tag like `llvmorg-19.1.5` or a commit SHA).
- Put `.patch` files under `patches/common/` or `patches/<name>/` and run the workflow with `patch_set=<name>`. Patches apply in alphanumeric order.

## FAQ
- **Do I need conda for CI?** No. CI uses Homebrew tools on `macos-14`. Conda is for local isolation only.
- **Can I install the helper CLI without editable mode?** Yes: `python -m pip install .` (inside the repo).
- **Where is the toolchain placed?** By default under `~/.cache/toolchain-builder/llvm-mlir/macos-arm64/build`. Override with `toolchain-builder --build-dir <path>` when printing exports.
- **How do I undo the exports?** Start a new shell or `unset LLVM_BUILD_DIR` etc.

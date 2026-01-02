# LLVM builds via conda-build (preferred) vs manual builds

> “The LLVM build process is fully scripted by conda-build, and the llvmdev recipe is the canonical reference for building LLVM for llvmlite. Please use it if at all possible!”

## Why conda-build first?
- Reproducible, scripted builds with the canonical `llvmdev` recipe.
- Patch application, dependency pinning, and output packaging are all handled for you.
- Artifacts drop directly into a conda channel (or local folder) so downstream recipes (e.g., `llvmlite`, `jaxlib`) can consume them immediately.
- Manual builds are possible, but require hand-managed toolchains, cache dirs, and patch ordering.

## Prerequisites
- **Miniforge3 or Rattler** with `conda` **≥25.x** and `conda-build` **≥25.x** (match the major/minor). Check with:
  ```bash
  conda --version
  conda-build --version
  ```
- A build environment created from [`envs/toolchain-builder-conda-build.yml`](../envs/toolchain-builder-conda-build.yml):
  ```bash
  conda env create -f envs/toolchain-builder-conda-build.yml
  conda activate toolchain-builder-conda-build
  ```
- Optional: `rattler-build` and `boa` are included to experiment with faster solvers.

## Building LLVM with the canonical recipe
1. Fetch the recipe (from conda-forge feedstock or your fork):
   ```bash
   git clone https://github.com/conda-forge/llvmdev-feedstock.git
   cd llvmdev-feedstock
   ```
2. Build with conda-build (preferred) or mambabuild:
   ```bash
   conda build recipe --output-folder ./build_artifacts
   # or
   conda mambabuild recipe --output-folder ./build_artifacts
   ```
   The produced packages land under `./build_artifacts/osx-arm64/`. Use `conda index` to serve them locally, or upload to your channel.
3. Point `toolchain-builder` at the installed prefix:
   ```bash
   conda create -n llvm-from-conda ./build_artifacts/osx-arm64/llvmdev-*.tar.bz2
   conda activate llvm-from-conda
   eval "$(toolchain-builder --build-dir "$CONDA_PREFIX")"
   ```

## Extending for llvmlite, polygeist, and jaxlib/jax
- **llvmlite**: Use the same `llvmdev` output as the compiler/headers input. In the llvmlite recipe, set `llvm-config` to point at the conda-installed LLVM. TODO: keep the recipe notes updated with the exact LLVM ref whenever you bump `llvmdev`.
- **polygeist**: Build against the packaged LLVM/MLIR by exporting `LLVM_BUILD_DIR` from `toolchain-builder` and invoking the polygeist CMake pipeline. Capture these steps in a recipe stub so conda-build can manage patches and compiler flags. TODO: record the CMake flags and required patches once validated.
- **jaxlib / jax**: After LLVM/MLIR is packaged, feed its headers and libraries into the jaxlib build (CPU-only or accelerator-specific). Keep the `jax` Python wheel pinned to the matching `jaxlib` build in your channel metadata. TODO: add a recipe skeleton that consumes the packaged LLVM/MLIR output.
- Track TODOs for each consumer recipe next to your `recipe/` folder (or in your issue tracker) so they stay discoverable with the toolchain sources.

## Manual build comparison (when you must)
- Manual CMake/Ninja builds give full control (custom flags, ad-hoc patches), but you must manage compilers, caches, and ABI compatibility yourself.
- Output placement is ad-hoc; downstream recipes cannot automatically reuse it without extra scripting.
- Prefer the conda-build flow above; fall back to manual only for one-off debugging or experiments, then upstream the change into the `llvmdev` recipe to regain reproducibility.

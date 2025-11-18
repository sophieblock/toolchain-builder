import argparse
import platform
from pathlib import Path

DEFAULT_CACHE = Path.home() / ".cache" / "toolchain-builder" / "llvm-mlir"


def detect_triplet() -> str:
    sys = platform.system().lower()
    mach = platform.machine().lower()
    if sys == "darwin" and mach in ("arm64", "aarch64"):
        return "macos-arm64"
    return f"{sys}-{mach}"


def default_build_dir() -> Path:
    return DEFAULT_CACHE / detect_triplet() / "build"


def print_exports(build_dir: Path) -> None:
    cmake_prefix = build_dir / "lib" / "cmake"
    print(f'export LLVM_BUILD_DIR="{build_dir}"')
    print(f'export CMAKE_PREFIX_PATH="{cmake_prefix}:$' + '{CMAKE_PREFIX_PATH}"')
    print(f'# Optional CMake hints:')
    print(f'export LLVM_DIR="{cmake_prefix}/llvm"')
    print(f'export MLIR_DIR="{cmake_prefix}/mlir"')


def main() -> None:
    ap = argparse.ArgumentParser(description="Print exports for a given LLVM/MLIR build dir")
    ap.add_argument(
        "--build-dir",
        type=str,
        default=None,
        help=(
            "LLVM build directory (default: "
            "~/.cache/toolchain-builder/llvm-mlir/<triplet>/build)"
        ),
    )
    args = ap.parse_args()
    bd = Path(args.build_dir) if args.build_dir else default_build_dir()
    if not bd.exists():
        print(f"# WARNING: build dir does not exist yet: {bd}")
    print_exports(bd)


if __name__ == "__main__":
    main()

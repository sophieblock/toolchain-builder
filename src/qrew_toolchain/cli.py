#!/usr/bin/env python3
"""CLI tool to print environment variable exports for LLVM/MLIR toolchain."""

import os
import sys
from pathlib import Path


def find_toolchain_root():
    """Find the toolchain root directory.
    
    Searches in the following order:
    1. QREW_TOOLCHAIN_ROOT environment variable
    2. ~/.qrew-toolchain
    3. Current directory's toolchain subdirectory
    """
    # Check environment variable
    env_root = os.environ.get("QREW_TOOLCHAIN_ROOT")
    if env_root:
        root = Path(env_root)
        if root.exists():
            return root
    
    # Check default location
    default_root = Path.home() / ".qrew-toolchain"
    if default_root.exists():
        return default_root
    
    # Check current directory
    cwd_root = Path.cwd() / "toolchain"
    if cwd_root.exists():
        return cwd_root
    
    return None


def get_llvm_build_dir(toolchain_root):
    """Get the LLVM build directory from the toolchain."""
    # Look for llvm-build directory
    llvm_build = toolchain_root / "llvm-build"
    if llvm_build.exists():
        return llvm_build
    
    # Look for a subdirectory that might be the build directory
    for item in toolchain_root.iterdir():
        if item.is_dir() and "llvm" in item.name.lower():
            return item
    
    return None


def print_exports(shell="bash"):
    """Print environment variable exports for the toolchain.
    
    Args:
        shell: Shell type ("bash", "fish", "zsh"). Default is "bash".
    """
    toolchain_root = find_toolchain_root()
    
    if not toolchain_root:
        print("Error: Toolchain not found. Please install it using scripts/download_and_setup.sh", 
              file=sys.stderr)
        sys.exit(1)
    
    llvm_build_dir = get_llvm_build_dir(toolchain_root)
    
    if not llvm_build_dir:
        print(f"Error: LLVM build directory not found in {toolchain_root}", 
              file=sys.stderr)
        sys.exit(1)
    
    # Generate export statements based on shell type
    if shell in ["bash", "zsh", "sh"]:
        print(f'export LLVM_BUILD_DIR="{llvm_build_dir}"')
        print(f'export PATH="{llvm_build_dir}/bin:$PATH"')
        print(f'export LD_LIBRARY_PATH="{llvm_build_dir}/lib:${{LD_LIBRARY_PATH:-}}"')
        print(f'export QREW_TOOLCHAIN_ROOT="{toolchain_root}"')
    elif shell == "fish":
        print(f'set -gx LLVM_BUILD_DIR "{llvm_build_dir}"')
        print(f'set -gx PATH "{llvm_build_dir}/bin" $PATH')
        print(f'set -gx LD_LIBRARY_PATH "{llvm_build_dir}/lib" $LD_LIBRARY_PATH')
        print(f'set -gx QREW_TOOLCHAIN_ROOT "{toolchain_root}"')
    else:
        print(f"Error: Unsupported shell type: {shell}", file=sys.stderr)
        sys.exit(1)


def main():
    """Main entry point for the CLI."""
    import argparse
    
    parser = argparse.ArgumentParser(
        description="Print environment variable exports for LLVM/MLIR toolchain",
        epilog="Example usage:\n  eval $(qrew-toolchain)\n  eval $(qrew-toolchain --shell fish)",
        formatter_class=argparse.RawDescriptionHelpFormatter
    )
    parser.add_argument(
        "--shell",
        choices=["bash", "zsh", "fish", "sh"],
        default="bash",
        help="Shell type for export format (default: bash)"
    )
    parser.add_argument(
        "--version",
        action="version",
        version="qrew-toolchain 0.1.0"
    )
    
    args = parser.parse_args()
    print_exports(shell=args.shell)


if __name__ == "__main__":
    main()

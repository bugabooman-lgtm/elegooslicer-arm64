#!/bin/bash
# Small fixes applied to Elegoo's source before building on ARM64 Linux.
# Run from the root of the ElegooSlicer checkout.
set -euo pipefail

echo "== Applying ARM64 fixes =="

# 1. OpenSSL: Elegoo copies libssl/libcrypto from lib64/ to lib/, which only exists
#    on x86_64. On aarch64 OpenSSL already installs to lib/, so the copy fails.
#    Limit that step to x86_64.
f=deps/OpenSSL/OpenSSL.cmake
if grep -q 'if(NOT WIN32 AND NOT APPLE)' "$f"; then
  sed -i 's/if(NOT WIN32 AND NOT APPLE)/if(NOT WIN32 AND NOT APPLE AND CMAKE_SYSTEM_PROCESSOR MATCHES "x86_64|AMD64")/' "$f"
  echo "  patched $f"
else
  echo "  $f: pattern not found (already fixed upstream?)"
fi

echo "== Done =="

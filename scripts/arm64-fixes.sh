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

# 2. elegoo-link (Elegoo's printer connection library):
#    a) Its cloud features use the Agora SDK, which Elegoo only ships as a prebuilt
#       x86_64 Linux binary, so it can't link on ARM64. Turn cloud features off.
#       Local network (LAN) printer control is separate code and stays enabled.
#    b) Some headers use std::find_if without #include <algorithm>; GCC 14's headers
#       on aarch64 don't pull it in indirectly, so force-include it.
f=deps/elegoolink/elegoolink.cmake
if grep -q -- '-DENABLE_CLOUD_FEATURES=ON' "$f"; then
  sed -i 's/-DENABLE_CLOUD_FEATURES=ON/-DENABLE_CLOUD_FEATURES=OFF/' "$f"
  echo "  $f: cloud features off"
else
  echo "  $f: cloud flag pattern not found"
fi
if ! grep -q 'include algorithm' "$f"; then
  sed -i 's/-DBUILD_SHARED_LIBS=OFF/-DBUILD_SHARED_LIBS=OFF\n        "-DCMAKE_CXX_FLAGS=-include algorithm -include cstdint"/' "$f"
  echo "  $f: force-include <algorithm>"
fi

echo "== Done =="

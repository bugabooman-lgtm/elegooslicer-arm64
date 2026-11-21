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
#    a) Its cloud messaging uses the Agora RTM SDK, which Elegoo only ships as a prebuilt
#       x86_64 binary. ElegooSlicer needs elegoo-link's cloud API to exist, so keep cloud
#       features ON and swap the Agora libraries for small ARM64 stand-ins
#       (scripts/agora-stub.sh) right after the source is downloaded.
#       LAN printer control is unaffected.
#    b) Some headers use std::find_if without #include <algorithm>; force-include it.
f=deps/elegoolink/elegoolink.cmake
here=$(cd "$(dirname "$0")" && pwd)
cp "$here/agora-stub.sh" deps/elegoolink/agora-stub.sh
if ! grep -q 'agora-stub.sh' "$f"; then
  sed -i 's|^\(\s*\)GIT_TAG\(\s*\)origin/main|&\n\1PATCH_COMMAND bash ${CMAKE_CURRENT_LIST_DIR}/agora-stub.sh|' "$f"
  echo "  $f: Agora stand-in hooked in"
fi
if ! grep -q 'include algorithm' "$f"; then
  sed -i 's/-DBUILD_SHARED_LIBS=OFF/-DBUILD_SHARED_LIBS=OFF\n        "-DCMAKE_CXX_FLAGS=-include algorithm -include cstdint"/' "$f"
  echo "  $f: force-include <algorithm>"
fi

echo "== Done =="

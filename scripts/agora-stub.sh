#!/bin/bash
# Replaces elegoo-link's prebuilt x86_64-only Agora RTM libraries with tiny ARM64 stand-ins.
# Run from the root of the elegoo-link source tree (CMake PATCH_COMMAND does this).
#
# Agora RTM is only used for Elegoo's cloud messaging. elegoo-link calls just three
# exported C functions from it. The stand-in createAgoraRtmClient() reports failure,
# which elegoo-link already handles (it logs "Failed to initialize RTM client" and the
# cloud messaging feature stays unavailable). Everything else keeps working.
set -euo pipefail

dir=thirdparty/agora/linux
[ -d "$dir" ] || { echo "agora-stub: $dir not found, skipping"; exit 0; }

case "$(uname -m)" in
  x86_64|amd64) echo "agora-stub: x86_64 host, keeping real Agora SDK"; exit 0 ;;
esac

tmp=$(mktemp -d)
cat > "$tmp/agora_stub.c" <<'EOF'
#include <stddef.h>
/* extern "C" functions from IAgoraRtmClient.h; C++ references are passed as pointers. */
__attribute__((visibility("default")))
void *createAgoraRtmClient(const void *config, int *errorCode) {
    (void)config;
    if (errorCode) *errorCode = -1;
    return NULL;
}
__attribute__((visibility("default")))
const char *getErrorReason(int errorCode) {
    (void)errorCode;
    return "Agora RTM cloud messaging is not available in the ARM64 Linux build";
}
__attribute__((visibility("default")))
const char *getVersion(void) { return "0.0.0-arm64-stub"; }
EOF
echo 'void aosl_stub_placeholder(void) {}' > "$tmp/aosl_stub.c"

cc=${CC:-cc}
command -v "$cc" >/dev/null 2>&1 || cc=clang
"$cc" -shared -fPIC -O2 -Wl,-soname,libaosl.so -o "$dir/libaosl.so" "$tmp/aosl_stub.c"
"$cc" -shared -fPIC -O2 -Wl,-soname,libagora_rtm_sdk.so -o "$dir/libagora_rtm_sdk.so" "$tmp/agora_stub.c"
rm -rf "$tmp"
echo "agora-stub: replaced Agora RTM libraries with $(uname -m) stand-ins"

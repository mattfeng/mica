#!/bin/sh
set -eu

derived_data=$1
mkdir -p -- "$derived_data"
derived_data=$(CDPATH= cd -- "$derived_data" && pwd -P)
marker="$derived_data/.mica-build-path"
previous_path=
if [ -f "$marker" ]; then
    previous_path=$(cat "$marker")
fi

# Xcode's generated caches contain absolute paths and cannot be relocated.
if [ "$previous_path" != "$derived_data" ]; then
    rm -rf -- "$derived_data/Build" "$derived_data/ModuleCache.noindex" \
        "$derived_data/SDKStatCaches.noindex" "$derived_data/info.plist"
    printf '%s\n' "$derived_data" > "$marker"
fi

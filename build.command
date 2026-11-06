#!/bin/zsh
set -euo pipefail
cd "$(dirname "$0")"
/usr/bin/xcodebuild -project Mica.xcodeproj -scheme Mica -configuration Release -derivedDataPath .build CODE_SIGNING_ALLOWED=NO build
printf '\nMica.app built at:\n%s\n' "$PWD/.build/Build/Products/Release/Mica.app"
/usr/bin/open -R "$PWD/.build/Build/Products/Release/Mica.app"

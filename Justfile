# Mica — native macOS command-line builds.
# Requires Xcode (not only Command Line Tools) and `just`.

project := "Mica.xcodeproj"
scheme := "Mica"
derived_data := ".build"

# Build an unsigned local Release app.
default: build

build:
    sh ./prepare-build.sh "{{derived_data}}"
    xcodebuild -project "{{project}}" -scheme "{{scheme}}" -configuration Release -derivedDataPath "{{derived_data}}" CODE_SIGNING_ALLOWED=NO build
    @echo "Built: {{derived_data}}/Build/Products/Release/Mica.app"

# Build an unsigned Debug app.
debug:
    sh ./prepare-build.sh "{{derived_data}}"
    xcodebuild -project "{{project}}" -scheme "{{scheme}}" -configuration Debug -derivedDataPath "{{derived_data}}" CODE_SIGNING_ALLOWED=NO build
    @echo "Built: {{derived_data}}/Build/Products/Debug/Mica.app"

# Build Release, refresh macOS app registration, and launch it.
run: build
    touch "{{derived_data}}/Build/Products/Release/Mica.app"
    /System/Library/Frameworks/CoreServices.framework/Frameworks/LaunchServices.framework/Support/lsregister -f "{{derived_data}}/Build/Products/Release/Mica.app"
    open "{{derived_data}}/Build/Products/Release/Mica.app"

# Remove all local build artifacts.
clean:
    rm -rf -- "{{derived_data}}"

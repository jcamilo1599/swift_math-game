---
name: build-mathgame
description: Build the MathGame iOS app for the Simulator, install it, and launch it. Use when the user asks to build, run, launch, install, or test the app on a simulator, or wants to verify a change works end-to-end. This skill knows the project's scheme, bundle ID, and the canonical xcodebuild + simctl pipeline.
---

# build-mathgame

Build, install, and launch the MathGame app in the iOS Simulator. Use when verifying a change end-to-end.

## Project facts

- **Project**: `MathGame.xcodeproj` (no workspace, no SPM, no Pods)
- **Scheme**: `MathGame`
- **Configurations**: `Debug` → bundle ID `com.faacil.MathGame-debug`; `Release` → `com.faacil.MathGame`
- **Deployment target**: iOS 17.4, devices: iPhone + iPad

## Steps

### 1. Pick a simulator (if not already running)

```bash
xcrun simctl list devices booted
# If none booted, pick one:
xcrun simctl list devices available | grep -E "iPhone (15|16) "
```

Prefer the newest already-available iPhone simulator. If asked to test iPad, pick an `iPad` device. Boot it before building so install/launch don't race:

```bash
xcrun simctl boot "iPhone 15" 2>/dev/null || true
open -a Simulator
```

### 2. Build for the booted simulator

Use `-destination 'generic/platform=iOS Simulator'` only for CI; for a real install-and-launch flow, pin to the booted device:

```bash
DEVICE_UDID=$(xcrun simctl list devices booted -j | python3 -c 'import sys,json; d=json.load(sys.stdin); [print(dev["udid"]) for v in d["devices"].values() for dev in v if dev.get("state")=="Booted"]' | head -1)

xcodebuild -project MathGame.xcodeproj \
  -scheme MathGame \
  -configuration Debug \
  -destination "id=$DEVICE_UDID" \
  -derivedDataPath build/ \
  build
```

If `xcodebuild` floods stdout, append `| xcbeautify` if available, or `| tail -40` to keep the conversation tight.

### 3. Locate the built `.app`

```bash
APP_PATH=$(find build/Build/Products/Debug-iphonesimulator -maxdepth 2 -name "MathGame.app" -type d | head -1)
echo "$APP_PATH"
```

### 4. Install and launch

```bash
xcrun simctl install "$DEVICE_UDID" "$APP_PATH"
xcrun simctl launch "$DEVICE_UDID" com.faacil.MathGame-debug
```

### 5. (Optional) screenshot for verification

```bash
xcrun simctl io "$DEVICE_UDID" screenshot /tmp/mathgame.png
open /tmp/mathgame.png
```

## Common failure modes

- **`No such file or directory: MathGame.app`** — the build silently failed; re-run the build without `| tail` to see the error.
- **`Unable to launch com.faacil.MathGame-debug — process exited`** — usually a crash on launch (check the latest `~/Library/Logs/CoreSimulator/<UDID>/system.log`).
- **Long build with no output** — first build after clean is slow (60-90s); don't kill it.
- **Localization not switching** — language is per-simulator-device; set with `xcrun simctl spawn $UDID defaults write com.faacil.MathGame-debug AppleLanguages '(es)'` then relaunch.

## When NOT to use this skill

- For headless CI builds, use `xcodebuild test` with `-destination 'generic/platform=iOS Simulator'` instead.
- For App Store builds, use `Release` configuration and `xcodebuild archive` — not covered here.

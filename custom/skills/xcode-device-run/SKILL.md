---
name: xcode-device-run
description: >-
  Xcode/iOS/macOS 앱 프로젝트를 Xcode GUI Run 버튼 없이 CLI로 빌드, 설치, 실행하는 워크플로우.
  반드시 사용: 사용자가 "Xcode에서 실행", "실기기에 올려줘", "iPhone에 빌드", "run 해줘", "앱 실행해줘",
  "Xcode 빌드가 안 돼", "Metal Toolchain", "Developer Disk Image", "devicectl", "simctl"을 언급하거나,
  iOS/macOS/SwiftUI/Metal 프로젝트에서 실행 가능 상태까지 세팅/검증을 원할 때.
  특히 Xcode GUI는 열어두되 에이전트가 터미널에서 자동으로 빌드→설치→실행해야 하는 상황에서 사용한다.
---

# Xcode Device Run

Xcode 프로젝트를 GUI Run 버튼에 의존하지 않고 CLI로 빌드, 설치, 실행한다. 사용자가 Xcode 환경을 잘 모르더라도, 에이전트가 실행 가능한 상태까지 책임지고 확인한다.

## Core workflow

1. 프로젝트 종류와 대상 확인
   - `.xcodeproj` 또는 `.xcworkspace`
   - scheme
   - bundle identifier
   - 실행 대상: 기본은 연결된 physical iOS device 1대
2. Xcode preflight 실행
   - `xcode-select -p`
   - `xcodebuild -version`
   - Metal 프로젝트면 `xcrun --find metal`, `xcrun --find metallib`
3. 연결된 기기 확인
   - physical device: `xcrun devicectl list devices`
   - simulator: `xcrun simctl list devices available`
4. 빌드
   - 실기기는 기본적으로 `generic/platform=iOS`로 빌드한다.
   - 특정 device destination으로 바로 빌드하다가 Developer Disk Image 문제가 날 수 있으므로, install/launch는 `devicectl`로 분리한다.
5. 설치/실행
   - `xcrun devicectl device install app`
   - `xcrun devicectl device process launch`
6. 결과를 한국어로 명확히 보고
   - 빌드 성공/실패
   - 설치 성공/실패
   - 실행 성공/실패
   - 실패 시 코드 문제인지 Xcode/기기 환경 문제인지 구분

## Preferred physical-device pattern

실기기 실행은 이 패턴을 우선한다.

```bash
xcodebuild \
  -project App.xcodeproj \
  -scheme App \
  -configuration Debug \
  -destination 'generic/platform=iOS' \
  -derivedDataPath .build/DerivedData \
  CODE_SIGNING_ALLOWED=YES \
  build

xcrun devicectl device install app \
  --device "$DEVICE" \
  .build/DerivedData/Build/Products/Debug-iphoneos/App.app

xcrun devicectl device process launch \
  --device "$DEVICE" \
  com.example.bundleid \
  --terminate-existing
```

왜 이 패턴을 쓰는가:
- `-destination id=<device>` 직접 빌드는 Developer Disk Image mount 단계에서 실패할 수 있다.
- `generic/platform=iOS` 빌드는 앱 산출물을 안정적으로 만들고, `devicectl`이 설치/실행을 담당한다.
- Xcode GUI 팝업이나 Run 버튼에 덜 의존한다.

## Add reusable scripts to the project

사용자가 "앞으로 이 프로젝트에서 계속 같은 방식으로 실행"하길 원하면 repo에 스크립트를 추가한다.

### `scripts/xcode-preflight.sh`

```bash
#!/usr/bin/env bash
set -euo pipefail

echo "== Xcode selection =="
xcode-select -p

echo

echo "== Xcode version =="
xcodebuild -version

echo

echo "== Metal tools =="
if find . -name '*.metal' -print -quit | grep -q .; then
  xcrun --find metal
  xcrun --find metallib
else
  echo "No .metal files found; skipping Metal tool lookup."
fi

echo

echo "OK: Xcode preflight passed."
```

### `scripts/run-device.sh`

기본 연결 기기 1대를 자동 선택한다. 사용자가 한 기기만 쓴다고 하면 이 방식을 기본값으로 한다.

```bash
#!/usr/bin/env bash
set -euo pipefail

PROJECT="${PROJECT:-App.xcodeproj}"
SCHEME="${SCHEME:-App}"
CONFIGURATION="${CONFIGURATION:-Debug}"
DERIVED_DATA_PATH="${DERIVED_DATA_PATH:-.build/DerivedData}"
BUNDLE_ID="${BUNDLE_ID:-com.example.app}"
DEVICE="${1:-${DEVICE:-}}"
DEVICES_JSON="${DERIVED_DATA_PATH}/devices.json"
APP_PATH="${DERIVED_DATA_PATH}/Build/Products/${CONFIGURATION}-iphoneos/${SCHEME}.app"

mkdir -p "$DERIVED_DATA_PATH"

./scripts/xcode-preflight.sh

echo
echo "== Detect iOS device =="
if [[ -z "$DEVICE" ]]; then
  xcrun devicectl list devices --json-output "$DEVICES_JSON" >/dev/null
  DEVICE="$(python3 - "$DEVICES_JSON" <<'PY'
import json
import sys

with open(sys.argv[1]) as f:
    devices = json.load(f)["result"]["devices"]

connected = []
for device in devices:
    hardware = device.get("hardwareProperties", {})
    connection = device.get("connectionProperties", {})
    if (
        hardware.get("platform") == "iOS"
        and hardware.get("reality") == "physical"
        and connection.get("tunnelState") == "connected"
    ):
        connected.append(device)

if not connected:
    sys.exit("No connected physical iOS device found. Connect/unlock an iPhone and trust this computer.")

selected = connected[0]
selected_hardware = selected.get("hardwareProperties", {})
selected_properties = selected.get("deviceProperties", {})
print(selected["identifier"])
print(
    f"Selected: {selected_properties.get('name', 'Unknown')} "
    f"({selected_hardware.get('marketingName', selected_hardware.get('productType', 'iPhone'))})",
    file=sys.stderr,
)
PY
  )"
else
  echo "Selected by argument/env: $DEVICE"
fi

echo "Device: $DEVICE"

echo
echo "== Build for physical iOS device =="
xcodebuild \
  -project "$PROJECT" \
  -scheme "$SCHEME" \
  -configuration "$CONFIGURATION" \
  -destination 'generic/platform=iOS' \
  -derivedDataPath "$DERIVED_DATA_PATH" \
  CODE_SIGNING_ALLOWED=YES \
  build

if [[ ! -d "$APP_PATH" ]]; then
  echo "App bundle not found: $APP_PATH" >&2
  exit 1
fi

echo
echo "== Install app =="
xcrun devicectl device install app \
  --device "$DEVICE" \
  "$APP_PATH" \
  --timeout 120 \
  --json-output "${DERIVED_DATA_PATH}/install.json"

echo
echo "== Launch app =="
xcrun devicectl device process launch \
  --device "$DEVICE" \
  "$BUNDLE_ID" \
  --terminate-existing \
  --timeout 60 \
  --json-output "${DERIVED_DATA_PATH}/launch.json"

echo
echo "OK: Built, installed, and launched $BUNDLE_ID on device $DEVICE."
```

After writing scripts, run:

```bash
chmod +x scripts/xcode-preflight.sh scripts/run-device.sh
./scripts/run-device.sh
```

## Project AGENTS.md guidance

프로젝트에 `AGENTS.md`가 있거나 만들 수 있으면 다음 내용을 추가한다.

```md
## CLI-first Xcode device run

Xcode GUI Run 버튼보다 CLI 실행을 우선한다.

```bash
./scripts/run-device.sh
```

이 스크립트는 Xcode/Metal preflight → physical iOS build → devicectl install → devicectl launch 순서로 실행한다.

`missing Metal Toolchain` 또는 `Developer Disk Image could not be mounted`는 먼저 Xcode/기기 환경 문제로 보고 preflight와 devicectl 흐름을 확인한다.
```

## Troubleshooting guide

### Metal Toolchain prompt/error

증상:

```text
cannot execute tool 'metal' due to missing Metal Toolchain
Download Xcode support for Metal Toolchain?
```

판단:
- Metal shader를 쓰는 프로젝트에서는 Xcode가 별도 Metal Toolchain support를 요구할 수 있다.
- 코드 문제로 단정하지 않는다.

확인:

```bash
xcrun --find metal
xcrun --find metallib
```

복구:

```bash
sudo xcode-select -s /Applications/Xcode.app/Contents/Developer
xcodebuild -runFirstLaunch
xcodebuild -downloadComponent MetalToolchain
```

Xcode 26 계열에서는 `/var/run/com.apple.security.cryptexd/mnt/com.apple.MobileAsset.MetalToolchain-...` 경로가 정상일 수 있다.

### Developer Disk Image mount failure

증상:

```text
The developer disk image could not be mounted on this device.
```

판단:
- 실기기 디버그 지원 이미지 마운트 문제다.
- 앱 코드/Swift 컴파일 문제로 단정하지 않는다.

대응:
1. 기기 잠금 해제, Trust this computer 확인
2. Developer Mode 확인
3. `xcrun devicectl list devices` 확인
4. 직접 device destination 빌드 대신 `generic/platform=iOS` 빌드 후 `devicectl install/launch` 사용

### Signing failure

확인:

```bash
xcodebuild -showBuildSettings -project App.xcodeproj -scheme App -configuration Debug | rg 'PRODUCT_BUNDLE_IDENTIFIER|DEVELOPMENT_TEAM|CODE_SIGN_STYLE|PROVISIONING_PROFILE'
```

대응:
- Xcode에서 Team/Signing 설정을 먼저 맞춘다.
- 자동 서명 프로젝트라면 `CODE_SIGNING_ALLOWED=YES`로 CLI 빌드한다.

## Reporting format

작업 완료 시 간단히 보고한다.

```md
- 대상 기기: [기기명/identifier]
- 빌드: 성공/실패
- 설치: 성공/실패
- 실행: 성공/실패
- 앱 bundle id: [bundle id]
- 남은 조치: [사용자가 직접 승인해야 하는 Xcode/iPhone 팝업 등]
```

## Important behavior

- 사용자가 한 기기만 사용한다고 했으면 기본 연결 기기를 자동 선택한다.
- Xcode GUI는 편집/디버깅용으로 열어둘 수 있지만, 에이전트는 가능한 CLI로 실행까지 처리한다.
- 실기기 실행 전 불필요하게 Xcode GUI Run 버튼을 요구하지 않는다.
- `.build/`, `DerivedData/` 같은 산출물이 git에 들어가지 않도록 `.gitignore`를 확인한다.

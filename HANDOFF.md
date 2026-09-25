# 다음 세션에서 이어서 작업하기

최종 정리: 2026-09-25. 이 문서는 재시작 지점이며 할 일의 단일 목록은 [TODO.md](TODO.md)다.

## 현재 상태

- Flutter에서 **iOS SwiftUI / Android Kotlin·Compose** 독립 네이티브 프로젝트로 전환했다. Flutter SDK는 필요 없다. 이전 MVP는 `6f9ad16`, `flutter-mvp-archive-20260925`에 보존한다.
- 암호화 로컬 저장, 사진/영상 기록·초안·휴지통·공유·잠금·백업 및 새 네이티브 앱끼리의 양방향 복원을 구현했다. 이전 Flutter 데이터/DRBK1 자동 이전은 지원하지 않는다.
- 종이색·손글씨 제목의 스케치북 UI, 설정에 있는 카드/2열/3열 선택, 사진 캐러셀/썸네일 작성, 사진 캘린더, 전체화면 보기와 사진 낙서를 반영했다.
- 편집 레시피 v2는 원본 좌표계 낙서를 저장한다. v1 읽기는 유지하며 암호화 포맷 DRBK2/DRY2는 바뀌지 않았다.
- Android Debug APK·미서명 Release AAB·lint, Kotlin 코어 8개, 기기 검사 7개, Swift CoreCheck/교차 백업 검사까지 통과했다. **iOS 앱 전체 컴파일·실행은 미검증**이다. 전체 Xcode가 없는 로컬 환경의 제한을 숨기지 않는다.
- 앱 아이콘은 5개 시안만 있고 미선정·미적용이다. 브랜드 인트로, 버튼·화면 아이콘, 화면 전체 마감은 사용자가 추가 요청한 다음 작업이다. [TODO](TODO.md)에 완료 기준까지 적었다.
- 서버 프로젝트 `../drawry-server`는 이번 전환·디자인 작업 범위 밖이며 변경하지 않았다.

## 지금 열린 에뮬레이터와 데이터 보호

| 구분 | 값 / 주의 |
| --- | --- |
| 현재 사용자 수동 테스트 기기 | `drawry-sketchbook-qa`, 기존 실행 포트 `5556` |
| 시스템 이미지 | Android API 36, `google_apis_ps16k`, arm64, 16KB 페이지 크기 |
| 앱 | `com.poyal.drawry`, 마지막 설치는 `adb install -r` 방식 |
| 날짜별 샘플 | 일기 12개 / 9개 날짜 / 사진 첨부 33개, 보관함 사진 12종 |
| 샘플 날짜 | 2026-08-31 및 2026-09-18~25. 09-21·23·25에는 샘플 2개씩 |
| 기존 기록 | 샘플 추가 당시 기록 2개와 초안·설정을 보존했다. 이후 사용자가 직접 수정할 수 있으므로 현재 개수를 단정하지 않는다 |
| 이전 수동 테스트 기기 | `drawry-test-16k`는 별도 AVD. 이번 디자인 QA/샘플 추가 과정에서는 건드리지 않았다 |

**이름에 QA가 있어도 현재는 사용자가 직접 쓰는 기기다.** `connectedDebugAndroidTest`, 전체 instrumentation 테스트, 앱 제거/데이터 초기화, `-wipe-data`, 자동 샘플 재주입을 실행하지 않는다. `SketchbookTest`의 UI 시나리오도 기록/설정을 변경하므로 현재 기기에서 재실행하지 않는다. 원격 CI는 별도의 일회용 기기를 사용한다.

앱 갱신은 대상 AVD를 확인하고 `install -r`로 한다. 사용자가 조작 중이면 임의로 화면을 닫거나 전환하지 않는다. 현재 화면은 마지막 점검 때 공유 옵션이었지만 다음 세션에서 달라질 수 있다. 런처/앱의 캡처 차단을 디버깅 편의로 해제하지 않는다.

## 같은 Mac에서 다시 실행하기

모든 명령은 `drawry/` 기준이다. `.toolchain/`, `.build/`, AVD 데이터와 APK는 로컬 전용이며 Git에 포함하지 않는다. 새 머신에서는 Android Studio/SDK/JDK와 전체 Xcode를 별도로 설치한다. 로컬 SDK 경로는 `android/local.properties`에 둔다.

```sh
# 먼저 현재 기기를 확인. 연결 포트는 바뀔 수 있으므로 이름까지 확인한다.
.toolchain/android-sdk/platform-tools/adb devices -l
.toolchain/android-sdk/platform-tools/adb -s emulator-5556 emu avd name
```

해당 AVD가 실행 중이 아닐 때만 다음 명령으로 기존 데이터를 그대로 연다.

```sh
env ANDROID_HOME="$PWD/.toolchain/android-sdk" \
  ANDROID_USER_HOME="$PWD/.toolchain/android-user" \
  ANDROID_AVD_HOME="$PWD/.toolchain/android-user/avd" \
  .toolchain/android-sdk/emulator/emulator \
  -avd drawry-sketchbook-qa -port 5556 -gpu swiftshader \
  -no-snapshot -no-boot-anim -no-audio
```

```sh
# Android 빌드 (현재 에뮬레이터의 앱/기록에는 영향을 주지 않음)
env JAVA_HOME="$PWD/.toolchain/jdk-17.0.20.1+1/Contents/Home" \
  GRADLE_USER_HOME="$PWD/.toolchain/gradle-cache" \
  ./android/gradlew -p android :core:test :app:assembleDebug :app:lintDebug :app:bundleRelease

# 직접 요청받아 앱을 갱신할 때만. 앱 삭제/재설치가 아니라 데이터 유지 갱신이다.
.toolchain/android-sdk/platform-tools/adb -s emulator-5556 install -r \
  android/app/build/outputs/apk/debug/app-debug.apk
.toolchain/android-sdk/platform-tools/adb -s emulator-5556 shell am start \
  -n com.poyal.drawry/.MainActivity
```

Android 스튜디오 대신 위의 로컬 Gradle 명령을 사용할 수 있다. JDK/SDK 경로와 버전은 이 Mac의 현재 설치 기준이다. 운영 서명은 아직 없으므로 Release AAB를 바로 스토어 업로드용으로 취급하지 않는다.

## 코어 검증 / iOS

```sh
# drawry/ 기준. Kotlin fixture 생성 후 Swift 검증, 다시 Kotlin에서 Swift fixture 읽기.
env JAVA_HOME="$PWD/.toolchain/jdk-17.0.20.1+1/Contents/Home" \
  GRADLE_USER_HOME="$PWD/.toolchain/gradle-cache" \
  ./android/gradlew -p android :core:test --rerun-tasks
swift run --package-path ios --scratch-path .build/swift CoreCheck shared/fixtures/generated
env JAVA_HOME="$PWD/.toolchain/jdk-17.0.20.1+1/Contents/Home" \
  GRADLE_USER_HOME="$PWD/.toolchain/gradle-cache" \
  ./android/gradlew -p android :core:test --rerun-tasks

# 구문 검사일 뿐 iOS 앱 전체 빌드가 아님
swiftc -frontend -parse ios/App/*.swift
```

`ios/project.yml`을 수정했으면 XcodeGen으로 프로젝트를 다시 생성한다. 이 Mac에는 `.toolchain/xcodegen/xcodegen/bin/xcodegen`이 있다. 생성된 `ios/Drawry.xcodeproj`도 함께 커밋한다.

전체 Xcode가 준비되면 [README](README.md)의 iOS 빌드·테스트 명령을 실행한다. `.github/workflows/native.yml`은 Android 및 iOS/상호 운용성 검증을 구성하며, 푸시 후 실제 Actions 결과를 별도로 확인해야 한다. 로컬 통과 기록과 원격 통과 기록을 혼동하지 않는다.

## 파일 안내

| 작업 | 주요 위치 |
| --- | --- |
| 화면/상태 | `ios/App/`, `android/app/src/main/kotlin/com/poyal/drawry/` |
| 색·글꼴·공통 요소 | 각 플랫폼의 `SketchDesign`, iOS `project.yml`, `shared/fonts/`, `shared/licenses/` |
| 사진 편집/뷰어 | `EditorView.swift`, `SketchPhotoEditor.kt`, 양쪽 `InkCanvasView`·`InkDrawing`·`PhotoViewer` |
| 모델·낙서·암호화·백업 | `ios/Core/`, `android/core/`, `shared/specs/native-v2.md` |
| 샘플 주입 | `ShowcaseSeedTest.kt` — 명시적 실행 옵션 + AVD 검사. 일반 테스트는 건너뜀 |
| 디자인/아이콘/캡처 | `docs/design/` — 커밋된 캡처는 도형 사진 기반 QA 화면이며 실제 사진 샘플 추가 전 자료 |
| 테스트 결과/보고서 | `VALIDATION_STATUS.md`, 로컬 `android/**/build/reports/` |

사진 보관함과 암호화 DB/키는 에뮬레이터 안에만 있다. **Git 푸시는 일기 데이터의 백업이 아니다.** AVD를 삭제/이전하기 전에 앱의 암호화 백업 기능으로 내보내고 암호/복구 키를 별도로 보관한다. 백업·DB·키·실제 개인 사진을 저장소에 커밋하지 않는다.

샘플을 새 기기에 다시 구성하는 방법과 사진 출처는 [showcase-data](docs/testing/showcase-data.md)에 있다. 현재 기기는 이미 준비되어 있으므로 추가 요청 없이 재실행할 필요가 없다.

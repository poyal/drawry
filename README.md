# Drawry

사진과 영상을 암호화해 보관하는 오프라인 그림일기 앱입니다. iOS와 Android가 각각 독립 네이티브 프로젝트이며 Flutter SDK를 사용하지 않습니다.

다음 세션 시작: **[인수인계·로컬 실행 방법](HANDOFF.md)** → **[할 일·디자인 마감 체크리스트](TODO.md)** → [실제 검증 상태](VALIDATION_STATUS.md).

현재 Android는 개발 빌드와 로컬 검증을 통과했으며, iOS 앱 전체 빌드·시뮬레이터 실행은 아직 확인해야 합니다. 앱 아이콘 최종 적용, 인트로 페이지, 버튼·화면 아이콘과 화면별 정리는 다음 작업입니다.

| | iOS | Android |
| --- | --- | --- |
| 구현 | Swift·SwiftUI | Kotlin·Jetpack Compose·CameraX |
| 최소 실행 OS | iOS 17 | Android 8 / API 26 |
| 빌드 기준 | Xcode 26 이상 | JDK 17, SDK 36, Gradle 8.13 |
| 저장소 | SQLCipher·Keychain | Room·SQLCipher·Keystore |
| 프로젝트 | `ios/Drawry.xcodeproj` | `android/` |

## 실행

iOS는 Xcode에서 `ios/Drawry.xcodeproj`를 열고 **Drawry** scheme과 시뮬레이터를 선택합니다. Swift Package Manager가 공식 SQLCipher 패키지를 내려받습니다. 실기기는 Signing & Capabilities에서 개발 팀을 설정합니다.

```sh
cd ios
swift test
swift run CoreCheck ../shared/fixtures/generated
xcodebuild -project Drawry.xcodeproj -scheme Drawry -destination 'generic/platform=iOS Simulator' CODE_SIGNING_ALLOWED=NO build
```

Xcode 프로젝트 정의를 수정한 경우 XcodeGen 2.44.1로 `xcodegen generate`를 실행하고 생성된 프로젝트도 함께 관리합니다. Command Line Tools만 있는 Mac에서는 `CoreCheck`를 실행할 수 있지만 앱 빌드와 XCTest에는 전체 Xcode가 필요합니다.

Android Studio에서 `android/`를 열거나 다음 명령을 실행합니다. 로컬 SDK 경로는 무시되는 `android/local.properties`의 `sdk.dir`로 지정합니다.

```sh
cd android
./gradlew :core:test :app:assembleDebug :app:lintDebug
./gradlew :app:connectedDebugAndroidTest  # 데이터가 없는 자동 테스트 전용 에뮬레이터에서만 실행
./gradlew :app:bundleRelease
```

Android 릴리스는 운영 키가 없으면 서명하지 않습니다. `DRAWRY_KEYSTORE`, `DRAWRY_STORE_PASSWORD`, `DRAWRY_KEY_ALIAS`, `DRAWRY_KEY_PASSWORD`를 CI 비밀 값이나 로컬 환경으로 제공해야 스토어 제출용 서명이 적용됩니다. Debug 키를 Release에 사용하지 않습니다.

주의: `connectedDebugAndroidTest`는 테스트 전후 앱을 설치·제거할 수 있으므로 직접 작성한 기록이 있는 기기/에뮬레이터에서 실행하지 마세요. 수동 테스트 앱 갱신에는 `adb install -r app/build/outputs/apk/debug/app-debug.apk`를 사용합니다 (`android/` 기준).

현재 `drawry-sketchbook-qa`에도 사용자가 직접 테스트한 기록이 있으므로 이름만 보고 초기화하거나 전체 테스트를 실행하면 안 됩니다. 실행 중인 기기를 먼저 확인하고, [안전한 재개 방법](HANDOFF.md)을 따르세요. Git 푸시는 에뮬레이터 기록을 백업하지 않습니다.

## 구현 기능

- 사진·영상 일기, 미리 보기, 날짜·시간·본문·기분·태그·함께한 사람·수동 날씨
- 종이색·손글씨 제목의 스케치북 UI, 라이트/다크 모드, 사진 넘기기·썸네일 선택형 작성 화면
- 카드·2열·3열 피드, 월 캘린더, 상세·수정, 암호화 초안 자동 저장과 복구
- 네이티브 사진 선택·촬영, 이미지 회전·정사각 자르기·필터·텍스트·이모지·스티커·실행 취소, 영상 재생·대표 프레임
- 사진 위 낙서(6색·3굵기), 획 지우개·실행 취소/다시 실행, 전체화면 사진 확대·이동
- 선택형 앱 잠금·재잠금 유예, 백그라운드 화면 가림, 30일 휴지통·복원·영구 삭제
- 항목·비율·테마·워터마크를 선택하는 이미지 공유, 암호화 백업과 암호·복구 키 복원
- iOS ↔ Android 백업 호환, 병합·교체 복원, 실패 시 기존 저장소 보존

제한: 일기당 미디어 10개·300MiB, 영상 3개·각 30초·합계 60초. 서버·계정·지도·동기화·자동 날씨와 영상 편집·재인코딩은 포함하지 않습니다. 원본 영상은 기기가 지원하는 코덱 범위에서 재생합니다.

낙서는 사진당 256획·20,000점까지 저장합니다. 원본 사진은 바뀌지 않으며 회전·자르기, 공유, 암호화 백업과 함께 보존됩니다. 낙서가 포함된 편집 v2 백업을 열 때는 양쪽 기기 모두 최신 네이티브 구현이 필요합니다. 기존 편집 v1 기록은 계속 읽을 수 있습니다.

## 구조와 검증

`ios/Core`와 `android/core`는 화면과 분리된 모델·암호화·백업 구현입니다. `shared/`에는 공통 규격, 독립 암호화 테스트 벡터와 라이선스가 있습니다. 두 플랫폼의 실행 코드를 공유하지 않습니다.

- [검증 결과와 남은 출시 조건](VALIDATION_STATUS.md)
- [다음 세션 인수인계](HANDOFF.md)
- [아이콘·인트로·버튼·화면 정리 등 할 일](TODO.md)
- [스케치북 디자인·검증 화면](docs/design/sketchbook.md)
- [날짜별 사진 샘플·추가 방법·출처](docs/testing/showcase-data.md)
- [네이티브 전환 기록](PLAN.MD)
- [공통 데이터·암호화·백업 규격](shared/specs/native-v2.md)
- [기능 검증 기준](docs/acceptance.md)
- [스토어 제출 준비](docs/release.md)

Flutter MVP는 커밋 `6f9ad16`과 태그 `flutter-mvp-archive-20260925`에 보존했습니다. 기존 Flutter 설치 데이터와 DRBK1 백업은 자동 이전하지 않습니다. 기존 개발용 설치를 테스트할 때는 별도 백업 후 새 설치를 사용하세요. `tools/media-validation`과 `readme/`의 후속 기능 문서는 참고 자료이며 네이티브 앱의 검증 통과를 의미하지 않습니다.

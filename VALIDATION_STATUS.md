# 네이티브 전환 검증 상태

확인일: 2026-09-25. 아래 결과는 이번 로컬 구현에서 실제 실행한 검사와 미검증 항목을 구분합니다.

## 통과한 검사

| 검사 | 결과 |
| --- | --- |
| Android 네이티브 Debug APK 생성 | 통과 |
| Android Release AAB 생성·R8 | 통과, 운영 키 미제공으로 **미서명** |
| Android lintDebug | 오류 없음; 의존성 최신 버전·스타일 등의 경고는 남음 |
| Kotlin 코어 테스트 | 8개 통과 (낙서 3개 포함) |
| Android API 36 / 16KB 에뮬레이터 | `getconf PAGE_SIZE = 16384` 확인 |
| SQLCipher·저장소·렌더링 및 네이티브 화면 테스트 | 7개 통과 (QA 전용 기기, 직접 instrumentation) |
| APK 16KB ZIP 정렬 | `zipalign -c -P 16 -v 4` 통과 |
| Swift 코어 빌드·CoreCheck 실행 | 통과 |
| 독립 PBKDF2 / DRY2 암호화 벡터 | Swift·Kotlin 모두 통과 |
| Swift → Kotlin, Kotlin → Swift 백업 복원 | 낙서 v2 메타데이터 포함 양방향 통과 |
| iOS 프로젝트 생성·Swift 소스 구문·plist 검사 | 통과 |
| 명시적 날짜별 샘플 추가 검사 | 별도 1개 통과; 기존 기록·초안·설정 보존 |

자동 테스트는 다중 청크, 잘못된 AAD·암호, 잘린 파일, 평문 출력 정리, 암호·복구 키 복원, 데이터 제약을 포함합니다. Android 통합 테스트는 DB가 평문 SQLite가 아님을 확인하고, 초안·휴지통·병합/교체 복원·설정 보존·만료 정리·온보딩/작성/캘린더 진입을 확인합니다.

산출물:

- `android/app/build/outputs/apk/debug/app-debug.apk`
- `android/app/build/outputs/bundle/release/app-release.aab` — 미서명
- `android/core/build/reports/tests/test/`
- `android/app/build/reports/androidTests/connected/debug/` — 과거 Gradle 연결 테스트 보고서. 이번 QA 검증은 자동 설치 제거가 없는 ADB 직접 instrumentation의 `OK (7 tests)` 결과로 확인
- `android/app/build/reports/lint-results-debug.html`

## 2026-09-25 보기 설정 이동 후 추가 확인

- iOS·Android 피드의 카드/2열/3열 선택을 설정 → 화면 → 기록 보기 방식으로 이동. 저장 모델과 기존 선택값은 변경하지 않음.
- Android Debug APK·lintDebug 통과. UI 테스트 `feedLayoutLivesInSettingsAndPersists` 1개를 ADB instrumentation으로 통과: 피드에서 선택 UI가 사라짐, 세 방식 모두 설정에서 선택 가능, Activity 재실행 후 유지, 테스트 전 선택으로 복원.
- iOS 변경 소스 구문 검사 통과. 전체 Xcode 빌드 제한은 아래와 동일.
- 첫 Gradle 연결 테스트는 UI 준비 대기 문제로 실패했으며 종료 시 에뮬레이터 앱이 제거됨. 이후 APK를 재설치하고 자동 제거가 없는 직접 instrumentation으로 검증. 수동 작성 기록이 있는 기기에는 `connectedDebugAndroidTest`를 사용하지 않도록 README에 경고 추가.
- 아이콘 5종은 [디자인 시안](docs/design/app-icons/2026-09-25/README.md)으로만 보관. 런처 아이콘 미변경.

## 2026-09-25 스케치북 디자인·사진 낙서 구현

- iOS·Android: 종이색/손글씨 제목/사진 우선 피드, 상세·확대 보기, 캐러셀·썸네일 기반 한 페이지 작성, 사진 캘린더, 설정·잠금·시작 화면, 비율을 보존하는 공유 이미지. 제목용 NanumPenScript 글꼴과 OFL 고지를 번들에 포함.
- 사진 낙서: 6색·3굵기, 획 지우개, 실행 취소/다시 실행. 원본 좌표계의 비파괴 편집이며 필터/회전/자르기, 썸네일/공유/초안/저장/백업에 반영. 편집 레시피만 v2 확장, 기존 v1 및 DRBK2/DRY2 암호화 포맷 유지.
- Kotlin 코어 8개, Swift CoreCheck, Android Debug APK·Release AAB/R8·lintDebug, APK 16KB ZIP 정렬 통과. Swift 앱 소스 구문·XcodeGen·plist 검사 통과. 전체 iOS 앱 컴파일은 미검증.
- `drawry-sketchbook-qa` / `emulator-5556` / API 36 / 16KB 페이지 크기의 별도 QA 기기에서 **7개 instrumentation 검사 통과**. 낙서 테스트는 실제 픽셀 정렬, 원본 불변, 초안/저장/공유 3비율/백업, 사진 썸네일 선택, 전체화면 진입, 그리기→취소→재실행→저장 후 획 증가 확인을 포함.
- 동일 UI 흐름을 다크 모드 및 시스템 글씨 150%로 각각 재실행하여 통과. QA 설정은 밝은 모드·100%로 복원. VoiceOver/TalkBack·200% 글씨·태블릿·가로 화면까지 검증한 것은 아님.
- 기존 수동 테스트용 `drawry-test-16k` 기기는 이번 검증에서 사용하거나 초기화하지 않음. 샘플 주입과 캡처 차단 해제는 QA 전용 AVD 이름을 확인한 테스트 코드에서만 실행하며 앱 본체의 보안 정책은 유지.
- 실제 QA [화면 캡처와 디자인 설명](docs/design/sketchbook.md)을 저장. 사진에 보이는 풍경은 테스트 코드로 만든 도형이며 사용자 사진이 아님.

## 2026-09-25 다중 사진·날짜별 수동 테스트 데이터

- 사용자 요청에 따라 `ShowcaseSeedTest.addPhotosAndDatedDiaries`를 `seedShowcase=true` 옵션으로 **단독 실행, 1개 통과**. 일반 실행에서는 건너뛰며 기존 7개 회귀 검사의 개수와 구분한다.
- 12종 공개 샘플 사진으로 일기 12개·날짜 9개·첨부 미디어 33개를 추가하고, 시스템 보관함에도 사진 12장을 등록했다. 2026-08-31 및 09-18~25 기록으로 날짜 이동·동일 날짜 여러 기록·사진 넘김을 수동 테스트할 수 있다.
- 추가 전 기록 2개, 초안과 초안 미디어, 설정이 그대로 보존됐는지 검사했다. 기존 ID가 있으면 덮어쓰지 않는 추가 방식이며 앱 초기화·DB 교체·앱 제거는 하지 않았다.
- 테스트 APK 빌드 통과 후 데이터만 추가했다. 앱 본체는 이 작업에서 변경하지 않았다. 출처와 재구성 방법은 [샘플 문서](docs/testing/showcase-data.md)에 있다.
- **현재 QA AVD는 사용자 수동 테스트 기기로 취급한다.** 자동 테스트용 빈 기기가 아니므로 전체 테스트·초기화·재주입을 임의로 실행하지 않는다. 사용자 입력으로 기록 수와 화면은 이후 달라질 수 있다.
- 커밋된 디자인 캡처는 앞 단계의 도형 사진 기반 화면이며, 이후 추가한 공개 사진 12종을 보여주는 최신 화면이라고 간주하지 않는다.

## 아직 검증하지 못한 항목

1. **iOS 앱 전체 컴파일·XCTest·시뮬레이터 실행.** 현재 Mac에는 전체 Xcode가 없고 Command Line Tools만 있습니다. Swift 코어 검사와 앱 구문 검사는 iOS 앱 빌드 성공을 의미하지 않습니다. `ios/Drawry.xcodeproj`와 CI는 구성했으며, 푸시 후 GitHub Actions의 실제 결과는 별도로 확인해야 합니다. 이 문서는 로컬 검증 기록입니다.
2. iPhone·실제 Android의 카메라/마이크, Face ID/생체 인증·기기 암호, 시스템 파일/공유 화면, 다양한 미디어 코덱과 접근성.
3. 최대 10개·300MiB 미디어의 메모리·발열·백업 중단·저장 공간 부족 부하 측정.
4. 운영 서명·프로비저닝·스토어 계정, 최종 앱 아이콘과 스크린샷, 개인정보·암호화 관련 등록 자료.
5. 인트로·온보딩 최종 디자인, 버튼/아이콘 체계 및 화면 전체 마감. 사용자가 추가 요청한 [TODO.md](TODO.md)의 미완료 항목이다.

**따라서 현재 상태는 네이티브 구현과 Android 검증을 마친 개발 버전이며, 두 스토어에 바로 제출 가능한 출시 완료 상태는 아닙니다.** 물리 저장 블록의 완전 덮어쓰기를 보장하지 않으며, 앱 외부로 이미 내보낸 백업은 앱 내 삭제 대상이 아닙니다.

자세한 실기기 완료 기준은 [docs/acceptance.md](docs/acceptance.md), 제출 절차는 [docs/release.md](docs/release.md)를 따릅니다.

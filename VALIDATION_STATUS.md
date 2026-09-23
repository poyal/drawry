# 기술 검증 진행 상태

> 마지막 확인: 2026-08-30

## 현재 결론

- Flutter 3.44.7 단일 코드베이스로 1차 MVP 구현 완료
- Android 디버그·릴리스 APK 빌드 성공
- `flutter analyze`: 문제 없음
- 자동 테스트: 7개 통과
- iOS 프로젝트·권한·Keychain entitlement 구성 완료
- 남은 출시 관문: macOS iOS 빌드, Android/iPhone 실기기 미디어·잠금·백업 성능, 운영 서명과 스토어 설정

## 구현 범위

- 온보딩, 카드·2열·3열 피드, 날짜별 기록 개수 캘린더, 일기 등록·상세·수정
- 사진·영상 선택과 촬영, 이미지 꾸미기, 영상 재생·대표 화면
- 기분·태그·함께한 사람·표시 항목을 고르는 수동 과거 날씨
- 설정형 앱 잠금과 즉시·30초·1분·5분·15분·30분 재잠금
- 30일 휴지통, 복원과 암호학적 영구 삭제
- 공유 항목·비율·테마 기억, 정지 이미지 공유와 임시 파일 정리
- 암호 및 별도 복구 키로 여는 암호화 백업, 병합·교체 복원과 실패 롤백
- SQLCipher 안의 작성 중 자동 임시저장, 비정상 종료 후 복구·폐기

## 보안·권한 확인

- 일기 DB: SQLCipher, 256비트 키는 Android Keystore/iOS Keychain 계층에 저장
- 미디어: 파일별 256비트 키와 AES-256-GCM 4MiB 청크 암호화
- 백업: PBKDF2-HMAC-SHA256 210,000회로 암호 키 유도, 암호·복구 키로 데이터 키를 각각 래핑
- 잘못된 미디어 키 복호화 시 평문 출력 파일 제거 테스트 통과
- 잘못된 백업 암호, 올바른 암호, 복구 키 복원 테스트 통과
- 앱이 백그라운드로 가면 복호화 보기 캐시를 제거하고 화면을 가림
- Android 자동 백업 비활성화
- 릴리스 APK에 위치·인터넷·네트워크 상태 권한 없음
- 릴리스 APK 권한: 생체 인증, 구형 지문 호환, 로컬 영상 재생용 wake-lock

## Android 빌드 결과

```text
applicationId     com.poyal.drawry
minSdk            24
targetSdk         36
release APK       build/app/outputs/flutter-apk/app-release.apk
release APK size  약 81.9MB (ABI 통합 개발 산출물)
SHA-256          39AA3C4B9B3637AE547FC636A898D69E688CDA8AF5C09015B7F8F96A31B7CA3F
native ABI        arm64-v8a, armeabi-v7a, x86_64
SQLCipher         모든 ABI에 libsqlcipher.so 포함 확인
signing           Android Debug 인증서 — 배포 전 운영 키로 교체 필요
```

## 자동 테스트

```text
ChunkedCipher       다중 청크 왕복, 잘못된 키의 평문 정리
AppSettings         사용자 옵션 JSON 왕복
DiaryRepository     저장, 30일 휴지통, 복원, DB 스냅샷 복원
BackupService       잘못된 암호 거부, 암호 복원, 복구 키 복원
DiaryDraft          미디어 키·대표 화면·날씨를 포함한 초안 직렬화 왕복
합계                7 passed, 0 failed
```

## 1차 범위 경계

- 장소, GPS, 위치 권한, NAVER Maps SDK, 위치 기반 자동 날씨 제외
- 날씨는 사용자가 직접 입력하며 외부 API를 호출하지 않음
- 중앙 서버, 계정, 공개 SNS, 동기화와 분석 SDK 없음
- 1차 네이버 클라우드 지도 예상 사용량·비용: 0건·0원
- 2·3차 상세 계획: [장소·네이버 지도 도입 계획](readme/지도-도입-계획.md)

## 아직 검증하지 못한 항목

1. Windows에서는 iOS를 컴파일할 수 없으므로 macOS/Xcode 빌드와 App Store 서명 필요
2. 실제 Android/iPhone에서 사진 선택·카메라·Face ID/생체 인증·공유 시트·파일 선택기 확인 필요
3. 10개 미디어와 300MB 한도에서 메모리·발열·백업 중단 복구 측정 필요
4. 영상은 현재 원본을 암호화하며 1080p 자동 정규화는 아직 구현하지 않음
5. Android 릴리스는 개발용 debug 인증서로 서명되어 있어 배포 불가
6. `cryptography_flutter`, `get_video_thumbnail` 플러그인의 향후 Flutter Built-in Kotlin 전환 추적 필요

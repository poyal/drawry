# Drawry

iOS·Android용 비공개 그림일기 앱 프로젝트입니다.

Flutter 단일 코드베이스로 구현되어 있으며, 1차 앱은 서버·계정·지도·장소·자동 날씨 없이 기기 내부에서만 동작합니다.

## 구현된 주요 기능

- 사진·영상 일기 등록, 상세 보기와 수정
- 텍스트·필터·이모지 등을 지원하는 이미지 꾸미기
- 영상 재생과 공유용 대표 화면 선택
- 카드·2열·3열 피드와 날짜별 기록 개수가 보이는 캘린더
- 표시 항목을 고르는 수동 과거 날씨, 기분, 태그, 함께한 사람 기록
- SQLCipher 기반 작성 중 자동 임시저장과 비정상 종료 후 초안 복구
- SQLCipher 데이터베이스와 AES-256-GCM 청크 미디어 암호화
- 선택형 앱 잠금과 재잠금 유예 시간
- 30일 휴지통, 암호 또는 복구 키 기반 암호화 백업·복원
- 항목·비율·테마를 고른 뒤 위치 메타데이터 없이 이미지 공유

## 개발 명령

Flutter 3.44.7, JDK 17, Android SDK 36을 기준으로 합니다.

```shell
flutter pub get
dart run build_runner build
flutter analyze
flutter test
flutter build apk --debug
```

Android 최소 버전은 API 24, iOS 최소 버전은 15입니다. 배포 전에는 Android 운영 서명 설정과 macOS에서의 iOS 빌드·실기기 검증이 필요합니다.

- [제품 요구사항과 개발 계획](PLAN.MD)
- [기술 검증 진행 상태](VALIDATION_STATUS.md)
- [2·3차 장소·네이버 지도 도입 계획](readme/지도-도입-계획.md)
- [미디어 제한 검증 도구](tools/media-validation/README.md)

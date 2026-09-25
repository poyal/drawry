# 날짜별 사진 샘플 데이터

2026-09-25 사용자 요청으로 현재 열린 `drawry-sketchbook-qa` (`emulator-5556`)에 추가한 수동 테스트용 데이터입니다. 앱 본체에 샘플 주입 기능을 넣지 않습니다.

- 사진 12종: 가로·세로·정사각형, 보관함 `Pictures/Drawry Samples/`에도 복사.
- 일기 12개: 2026-08-31, 09-18~09-25의 9개 날짜, 일기당 1~4장, 총 33개 미디어 첨부.
- 09-21·23·25에는 같은 날짜의 샘플 일기를 2개씩 추가. 기존 일기는 그대로 둡니다.
- `샘플` 태그와 본문의 샘플 안내로 실제 기록과 구분합니다.
- 기존 일기·초안·설정의 동등성과 초안 미디어 보존을 검사했습니다. 실행 당시 기존 일기는 2개였으며 변경하지 않았습니다.

## 재실행 안전장치

`ShowcaseSeedTest`는 `-e seedShowcase true`와 QA AVD 이름이 모두 맞을 때만 실행합니다. 일반 테스트 실행에서는 건너뜁니다. 고정 UUID가 있는 일기는 수정하지 않고 건너뛰므로 재실행해도 복제하지 않습니다. 휴지통에 있는 샘플도 자동 복원하지 않습니다.

`Vault.save()`는 초안을 지우는 일반 저장 동작이므로 여기서는 사용하지 않습니다. 평소와 같은 미디어 가져오기·암호화 경로를 사용하고, 테스트 코드가 SQLCipher 트랜잭션으로 새 일기 행만 추가합니다. 기기 초기화·앱 삭제·DB 교체를 하지 않습니다.

이미지는 앱에 번들하지 않고 `.build/showcase-input/`에 내려받은 뒤 QA 기기의 앱 전용 외부 저장소에 복사합니다. 사진 재료가 없으면 데이터 추가 전에 중단합니다.

현재 기기는 이미 이 데이터가 들어 있고 사용자가 직접 조작 중입니다. 새 실행 환경을 준비하거나 명시적으로 추가 요청을 받은 경우에만 아래 절차를 사용하세요. 앱 DB·암호화 키·AVD와 다운로드된 사진은 Git에 포함하지 않으며, Git clone만으로 기록이 복원되지는 않습니다.

### 새 환경에 사진 준비

`drawry/` 기준입니다. 같은 이름의 자료가 있으면 그대로 두고 없는 사진만 내려받습니다. `curl`은 실행 중 외부 사진 서비스에 접속하므로 오프라인에서는 미리 준비한 파일이 필요합니다.

```sh
mkdir -p .build/showcase-input
for drawry_sample_id in 10 11 12 15 16 20 28 29 42 43 48 237; do
  case "$drawry_sample_id" in
    11|20|42|237) drawry_sample_size=900/1200 ;;
    15|28|48) drawry_sample_size=1000/1000 ;;
    *) drawry_sample_size=1200/900 ;;
  esac
  if [ ! -f ".build/showcase-input/$drawry_sample_id.jpg" ]; then
    curl -fL --retry 2 --max-time 40 \
      "https://picsum.photos/id/$drawry_sample_id/$drawry_sample_size.jpg" \
      -o ".build/showcase-input/$drawry_sample_id.jpg" || break
  fi
done
```

### 명시적으로 샘플 추가

아래는 `adb`와 JDK/SDK가 설정된 환경 기준입니다. 같은 Mac의 `.toolchain` 경로와 실행 방법은 [인수인계](../../HANDOFF.md)에 있습니다. 대상 이름을 확인하고 사용자가 조작을 멈춘 상태에서만 진행합니다. 테스트 도구만 갱신하며 Drawry 앱 자체를 제거하지 않습니다.

```sh
# drawry/ 기준. 먼저 대상 AVD 이름과 사진 파일을 확인합니다.
adb -s emulator-5556 emu avd name
adb -s emulator-5556 push .build/showcase-input /sdcard/Android/data/com.poyal.drawry/files/
./android/gradlew -p android :app:assembleDebugAndroidTest
adb -s emulator-5556 install -r android/app/build/outputs/apk/androidTest/debug/app-debug-androidTest.apk
adb -s emulator-5556 shell am instrument -w \
  -e class com.poyal.drawry.ShowcaseSeedTest -e seedShowcase true \
  com.poyal.drawry.test/androidx.test.runner.AndroidJUnitRunner
adb -s emulator-5556 shell am start -n com.poyal.drawry/.MainActivity
```

## 사진 출처

[Lorem Picsum](https://picsum.photos/)에서 제공하는 Unsplash 사진입니다. 생성형 이미지나 사용자 개인 사진이 아닙니다. 원본 출처는 공식 `/id/{id}/info` API 기준으로 기록했습니다.

| Picsum ID | 작가 / 원본 |
| --- | --- |
| 10 | [Paul Jarvis](https://unsplash.com/photos/6J--NXulQCs) |
| 11 | [Paul Jarvis](https://unsplash.com/photos/Cm7oKel-X2Q) |
| 12 | [Paul Jarvis](https://unsplash.com/photos/I_9ILwtsl_k) |
| 15 | [Paul Jarvis](https://unsplash.com/photos/NYDo21ssGao) |
| 16 | [Paul Jarvis](https://unsplash.com/photos/gkT4FfgHO5o) |
| 20 | [Aleks Dorohovich](https://unsplash.com/photos/nJdwUHmaY8A) |
| 28 | [Jerry Adney](https://unsplash.com/photos/_WiFMBRT7Aw) |
| 29 | [Go Wild](https://unsplash.com/photos/V0yAek6BgGk) |
| 42 | [Luke Chesser](https://unsplash.com/photos/KR2mdHJ5qMg) |
| 43 | [Oleg Chursin](https://unsplash.com/photos/IoCWq07GaG4) |
| 48 | [Luke Chesser](https://unsplash.com/photos/1uxV8fAfhVM) |
| 237 | [André Spieker](https://unsplash.com/photos/8wTPqxlnKM4) |

다운로드는 `https://picsum.photos/id/<ID>/<width>/<height>.jpg`를 사용합니다. 10·12·16·29·43은 1200×900, 11·20·42·237은 900×1200, 15·28·48은 1000×1000입니다.

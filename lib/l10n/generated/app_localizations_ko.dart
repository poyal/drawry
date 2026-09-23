// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Korean (`ko`).
class AppLocalizationsKo extends AppLocalizations {
  AppLocalizationsKo([String locale = 'ko']) : super(locale);

  @override
  String get appName => 'Drawry';

  @override
  String get feed => '피드';

  @override
  String get calendar => '캘린더';

  @override
  String get settings => '설정';

  @override
  String get newDiary => '새 일기';

  @override
  String get emptyDiary => '아직 기록이 없어요';

  @override
  String get emptyDiaryHint => '오늘의 사진이나 영상을 일기로 남겨보세요.';

  @override
  String get addDiary => '일기 쓰기';

  @override
  String get trash => '휴지통';

  @override
  String get dataManagement => '데이터 관리';
}

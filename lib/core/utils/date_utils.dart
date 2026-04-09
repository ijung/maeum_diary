/// 날짜 관련 유틸리티 함수
///
/// 모든 함수는 [now] 매개변수를 통해 현재 시각을 주입받을 수 있어
/// 단위 테스트에서 시각을 고정하기 쉽다.
library;

/// 로컬 날짜(년·월·일)만 추출한 [DateTime]을 반환한다.
/// 시·분·초는 0으로 정규화된다.
DateTime toLocalDate(DateTime dt) {
  return DateTime(dt.year, dt.month, dt.day);
}

/// [DateTime]을 'yyyy-MM-dd' 형식의 날짜 키로 변환한다.
///
/// 캘린더와 저장소에서 날짜를 Map 키로 사용할 때 공통으로 사용한다.
String toDateKey(DateTime dt) {
  final local = toLocalDate(dt);
  final y = local.year.toString().padLeft(4, '0');
  final m = local.month.toString().padLeft(2, '0');
  final d = local.day.toString().padLeft(2, '0');
  return '$y-$m-$d';
}

/// [date]의 일기가 작성·수정 가능한 상태인지 판별한다.
///
/// 규칙:
/// - 오늘 날짜 → 항상 가능
/// - 어제 날짜 → 오늘 15시 이전까지만 가능
/// - 그 외 → 불가능
///
/// - [now]: 테스트에서 현재 시각을 주입할 때 사용한다. null이면 [DateTime.now()]를 사용한다.
/// - 날짜 비교는 로컬 날짜(시각 제외) 기준으로 수행된다.
bool isEditableDate(DateTime date, {DateTime? now}) {
  final actualNow = now ?? DateTime.now();
  final today = toLocalDate(actualNow);
  final target = toLocalDate(date);
  final diff = today.difference(target).inDays;

  if (diff == 0) return true;
  if (diff == 1) return actualNow.hour < 15;
  return false;
}

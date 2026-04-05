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

/// [date]가 오늘 또는 어제인지 판별한다.
///
/// - [now]: 테스트에서 현재 시각을 주입할 때 사용한다. null이면 [DateTime.now()]를 사용한다.
/// - 비교는 로컬 날짜(시각 제외) 기준으로 수행된다.
bool isEditableDate(DateTime date, {DateTime? now}) {
    final today = toLocalDate(now ?? DateTime.now());
    final target = toLocalDate(date);
    final diff = today.difference(target).inDays;
    return diff == 0 || diff == 1;
}

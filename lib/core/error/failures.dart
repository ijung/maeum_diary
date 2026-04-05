/// 앱 전반에서 사용하는 도메인/애플리케이션 수준 실패 타입
sealed class Failure {
  final String message;
  const Failure(this.message);
}

/// 오늘/어제가 아닌 날짜에 수정을 시도했을 때
final class EditNotAllowedFailure extends Failure {
  const EditNotAllowedFailure()
      : super('오늘 또는 어제의 일기만 작성·수정할 수 있습니다.');
}

/// 메모가 최대 글자 수(500자)를 초과했을 때
final class MemoTooLongFailure extends Failure {
  const MemoTooLongFailure()
      : super('메모는 최대 500자까지 입력할 수 있습니다.');
}

/// 이모지 선택 개수가 유효하지 않을 때
final class InvalidEmotionsFailure extends Failure {
  const InvalidEmotionsFailure(super.message);
}

/// DB 또는 외부 저장소에서 발생한 오류
final class StorageFailure extends Failure {
  const StorageFailure(super.message);
}

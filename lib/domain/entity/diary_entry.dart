import 'package:maeum_diary/domain/value_object/emotions_selection.dart';

/// 하루 감정 일기를 나타내는 핵심 도메인 엔티티 (불변)
final class DiaryEntry {
  /// 고유 식별자 (UUID v4)
  final String id;

  /// 일기 날짜 (로컬 기준 00:00:00으로 정규화됨)
  final DateTime date;

  /// 선택된 감정 목록 (1~3개)
  final EmotionsSelection emotions;

  /// 메모 (옵셔널, 최대 500자)
  final String? memo;

  final DateTime createdAt;
  final DateTime updatedAt;

  const DiaryEntry({
    required this.id,
    required this.date,
    required this.emotions,
    this.memo,
    required this.createdAt,
    required this.updatedAt,
  });

  /// 변경된 필드만 교체한 새 [DiaryEntry]를 반환한다.
  DiaryEntry copyWith({
    EmotionsSelection? emotions,
    String? memo,
    DateTime? updatedAt,
    bool clearMemo = false,
  }) {
    return DiaryEntry(
      id: id,
      date: date,
      emotions: emotions ?? this.emotions,
      memo: clearMemo ? null : (memo ?? this.memo),
      createdAt: createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is DiaryEntry && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() =>
      'DiaryEntry(id: $id, date: $date, emotions: $emotions, memo: $memo)';
}

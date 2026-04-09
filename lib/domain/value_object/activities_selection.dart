import 'package:maeum_diary/domain/value_object/activity.dart';

/// 오늘 한 일 선택 목록 (옵셔널, 최대 5개)
final class ActivitiesSelection {
  static const int maxCount = 5;

  final List<Activity> values;

  ActivitiesSelection(List<Activity> activities)
      : values = List.unmodifiable(activities) {
    if (activities.length > maxCount) {
      throw ArgumentError('오늘 한 일은 최대 $maxCount개까지 선택할 수 있어요.');
    }
    final unique = activities.toSet();
    if (unique.length != activities.length) {
      throw ArgumentError('오늘 한 일에 중복 항목이 있어요.');
    }
  }

  /// 비어있는 선택 (0개)
  const ActivitiesSelection.empty() : values = const [];

  bool get isEmpty => values.isEmpty;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is ActivitiesSelection &&
          values.length == other.values.length &&
          values.every(other.values.contains));

  @override
  int get hashCode => Object.hashAll(values);
}

import 'package:maeum_diary/domain/value_object/emotion.dart';

/// 하루 일기에 선택된 감정 목록을 나타내는 Value Object
///
/// 불변이며, 1~3개의 중복 없는 [Emotion] 목록을 보장한다.
final class EmotionsSelection {
  static const int minCount = 1;
  static const int maxCount = 3;

  final List<Emotion> _emotions;

  const EmotionsSelection._(this._emotions);

  /// [emotions]를 검증하여 [EmotionsSelection]을 생성한다.
  ///
  /// 빈 목록이거나 3개를 초과하거나 중복이 있으면 [ArgumentError]를 던진다.
  factory EmotionsSelection(List<Emotion> emotions) {
    if (emotions.isEmpty) {
      throw ArgumentError('감정은 최소 $minCount개 이상 선택해야 합니다.');
    }
    if (emotions.length > maxCount) {
      throw ArgumentError('감정은 최대 $maxCount개까지 선택할 수 있습니다.');
    }
    final unique = emotions.toSet();
    if (unique.length != emotions.length) {
      throw ArgumentError('동일한 감정을 중복 선택할 수 없습니다.');
    }
    return EmotionsSelection._(List.unmodifiable(emotions));
  }

  /// 현재 선택된 감정 목록 (불변)
  List<Emotion> get values => _emotions;

  /// 특정 감정이 선택되어 있는지 확인한다.
  bool contains(Emotion emotion) => _emotions.contains(emotion);

  /// 추가 가능 여부 (현재 3개 미만)
  bool get canAddMore => _emotions.length < maxCount;

  /// [emotion]을 추가한 새로운 [EmotionsSelection]을 반환한다.
  ///
  /// 이미 선택된 경우 현재 객체를 그대로 반환한다.
  /// 3개 초과 시 [ArgumentError]를 던진다.
  EmotionsSelection add(Emotion emotion) {
    if (contains(emotion)) return this;
    return EmotionsSelection([..._emotions, emotion]);
  }

  /// [emotion]을 제거한 새로운 [EmotionsSelection]을 반환한다.
  ///
  /// 선택되어 있지 않은 경우 현재 객체를 그대로 반환한다.
  /// 제거 후 0개가 되면 [ArgumentError]를 던진다.
  EmotionsSelection remove(Emotion emotion) {
    if (!contains(emotion)) return this;
    return EmotionsSelection(_emotions.where((e) => e != emotion).toList());
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    if (other is! EmotionsSelection) return false;
    if (_emotions.length != other._emotions.length) return false;
    for (int i = 0; i < _emotions.length; i++) {
      if (_emotions[i] != other._emotions[i]) return false;
    }
    return true;
  }

  @override
  int get hashCode => Object.hashAll(_emotions);

  @override
  String toString() =>
      'EmotionsSelection(${_emotions.map((e) => e.emoji).join()})';
}

/// 앱에서 지원하는 감정 이모지 목록
enum Emotion {
  happy, // 😊
  calm, // 😌
  sad, // 😢
  angry, // 😠
  anxious, // 😰
  neutral, // 😐
  excited, // 🤩
  tired, // 😴
  loved, // 🥰
}

extension EmotionExtension on Emotion {
  /// 감정에 대응하는 이모지 문자열
  String get emoji {
    return switch (this) {
      Emotion.happy => '😊',
      Emotion.calm => '😌',
      Emotion.sad => '😢',
      Emotion.angry => '😠',
      Emotion.anxious => '😰',
      Emotion.neutral => '😐',
      Emotion.excited => '🤩',
      Emotion.tired => '😴',
      Emotion.loved => '🥰',
    };
  }

  /// 감정에 대응하는 한국어 레이블
  String get label {
    return switch (this) {
      Emotion.happy => '행복',
      Emotion.calm => '평온',
      Emotion.sad => '슬픔',
      Emotion.angry => '화남',
      Emotion.anxious => '불안',
      Emotion.neutral => '보통',
      Emotion.excited => '설렘',
      Emotion.tired => '피곤',
      Emotion.loved => '사랑',
    };
  }
}

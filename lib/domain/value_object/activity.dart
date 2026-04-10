/// 오늘 한 일 항목
enum Activity {
  date,
  overslept,
  drinking,
  workDinner,
  study,
  exercise,
  walking,
  hiking,
  shopping,
  travel,
  movie,
  gaming,
  cooking,
  reading,
}

extension ActivityExtension on Activity {
  String get emoji {
    switch (this) {
      case Activity.date:
        return '💑';
      case Activity.overslept:
        return '🛌';
      case Activity.drinking:
        return '🍺';
      case Activity.workDinner:
        return '🍻';
      case Activity.study:
        return '📚';
      case Activity.exercise:
        return '💪';
      case Activity.walking:
        return '🚶';
      case Activity.hiking:
        return '🧗';
      case Activity.shopping:
        return '🛍️';
      case Activity.travel:
        return '✈️';
      case Activity.movie:
        return '🎬';
      case Activity.gaming:
        return '🎮';
      case Activity.cooking:
        return '🍳';
      case Activity.reading:
        return '📖';
    }
  }

  String get label {
    switch (this) {
      case Activity.date:
        return '데이트';
      case Activity.overslept:
        return '늦잠';
      case Activity.drinking:
        return '음주';
      case Activity.workDinner:
        return '모임';
      case Activity.study:
        return '공부';
      case Activity.exercise:
        return '운동';
      case Activity.walking:
        return '산책';
      case Activity.hiking:
        return '등산';
      case Activity.shopping:
        return '쇼핑';
      case Activity.travel:
        return '여행';
      case Activity.movie:
        return '영화';
      case Activity.gaming:
        return '게임';
      case Activity.cooking:
        return '요리';
      case Activity.reading:
        return '독서';
    }
  }
}

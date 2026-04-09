import 'dart:convert';

import 'package:maeum_diary/core/utils/date_utils.dart';
import 'package:maeum_diary/domain/entity/diary_entry.dart';
import 'package:maeum_diary/domain/value_object/activities_selection.dart';
import 'package:maeum_diary/domain/value_object/activity.dart';
import 'package:maeum_diary/domain/value_object/emotion.dart';
import 'package:maeum_diary/domain/value_object/emotions_selection.dart';

/// [DiaryEntry]와 SQLite 행(Map) 사이의 변환을 담당하는 DTO
final class DiaryEntryDto {
  final String id;
  final String date; // 'yyyy-MM-dd'
  final String emotions; // JSON: ["happy","sad"]
  final String activities; // JSON: ["date","study"]
  final String? memo;
  final String createdAt; // ISO8601
  final String updatedAt; // ISO8601

  const DiaryEntryDto({
    required this.id,
    required this.date,
    required this.emotions,
    required this.activities,
    this.memo,
    required this.createdAt,
    required this.updatedAt,
  });

  // ─── DB Map → DTO ────────────────────────────────────────────────────────

  factory DiaryEntryDto.fromMap(Map<String, dynamic> map) {
    return DiaryEntryDto(
      // sqflite는 Android에서 TEXT 컬럼 값을 int로 반환할 수 있으므로
      // as String 대신 _str() 헬퍼로 안전하게 변환한다
      id: _str(map['id']),
      date: _str(map['date']),
      // emotions가 빈 문자열이면 jsonDecode가 FormatException을 던지므로
      // 빈 JSON 배열을 기본값으로 사용한다 (DB 버전 업그레이드로 실제로는 발생하지 않음)
      emotions: _str(map['emotions'], fallback: '[]'),
      activities: _str(map['activities'], fallback: '[]'),
      memo: map['memo'] == null ? null : _str(map['memo']),
      createdAt: _str(map['created_at']),
      updatedAt: _str(map['updated_at']),
    );
  }

  /// sqflite가 반환하는 값을 안전하게 String으로 변환한다.
  ///
  /// TEXT 컬럼에 저장된 값이라도 Android SQLite 드라이버는
  /// 숫자처럼 보이는 값을 int로 반환하는 경우가 있다.
  /// [fallback]: 값이 null이거나 빈 문자열일 때 사용할 기본값
  static String _str(dynamic value, {String fallback = ''}) {
    if (value is String && value.isNotEmpty) return value;
    final s = value?.toString() ?? '';
    return s.isNotEmpty ? s : fallback;
  }

  // ─── DTO → DB Map ────────────────────────────────────────────────────────

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'date': date,
      'emotions': emotions,
      'activities': activities,
      'memo': memo,
      'created_at': createdAt,
      'updated_at': updatedAt,
    };
  }

  // ─── Domain → DTO ────────────────────────────────────────────────────────

  factory DiaryEntryDto.fromDomain(DiaryEntry entry) {
    final emotionNames = entry.emotions.values.map((e) => e.name).toList();
    final activityNames = entry.activities.values.map((a) => a.name).toList();
    return DiaryEntryDto(
      id: entry.id,
      date: toDateKey(entry.date),
      emotions: jsonEncode(emotionNames),
      activities: jsonEncode(activityNames),
      memo: entry.memo,
      createdAt: entry.createdAt.toIso8601String(),
      updatedAt: entry.updatedAt.toIso8601String(),
    );
  }

  // ─── DTO → Domain ────────────────────────────────────────────────────────

  DiaryEntry toDomain() {
    // .cast<String>()은 lazy evaluate되므로, eager하게 String 변환을 보장한다
    final emotionNames = (jsonDecode(emotions) as List)
        .map((e) => e.toString())
        .toList();
    final emotionList = emotionNames
        .map((name) => Emotion.values.firstWhere((e) => e.name == name))
        .toList();

    final activityNames = (jsonDecode(activities) as List)
        .map((a) => a.toString())
        .toList();
    final activityList = activityNames
        .map(
          (name) => Activity.values.firstWhere(
            (a) => a.name == name,
            orElse: () => throw StateError('알 수 없는 활동: $name'),
          ),
        )
        .toList();

    return DiaryEntry(
      id: id,
      date: _parseDate(date),
      emotions: EmotionsSelection(emotionList),
      activities: ActivitiesSelection(activityList),
      memo: memo,
      createdAt: DateTime.parse(createdAt),
      updatedAt: DateTime.parse(updatedAt),
    );
  }

  // ─── 내부 유틸 ────────────────────────────────────────────────────────────

  /// 'yyyy-MM-dd' 문자열을 [DateTime]으로 변환한다.
  static DateTime _parseDate(String s) {
    final parts = s.split('-');
    return DateTime(
      int.parse(parts[0]),
      int.parse(parts[1]),
      int.parse(parts[2]),
    );
  }
}

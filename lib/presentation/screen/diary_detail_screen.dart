import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:maeum_diary/core/utils/date_utils.dart';
import 'package:maeum_diary/domain/entity/diary_entry.dart';
import 'package:maeum_diary/domain/value_object/activity.dart';
import 'package:maeum_diary/domain/value_object/emotion.dart';
import 'package:maeum_diary/presentation/provider/diary_provider.dart';
import 'package:maeum_diary/presentation/screen/diary_edit_screen.dart';

/// 특정 날짜 일기 상세 조회 화면
class DiaryDetailScreen extends ConsumerWidget {
  final DateTime date;

  const DiaryDetailScreen({super.key, required this.date});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final diaryAsync = ref.watch(diaryByDateProvider(date));
    final canEdit = isEditableDate(date);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final colorScheme = Theme.of(context).colorScheme;
    final bgColor = isDark ? colorScheme.surface : const Color(0xFFF5F0E8);
    final titleColor = isDark ? colorScheme.onSurface : const Color(0xFF5C4033);

    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        backgroundColor: bgColor,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        title: Text(
          DateFormat('yyyy년 M월 d일 (E)', 'ko').format(date),
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w700,
            color: titleColor,
          ),
        ),
        iconTheme: IconThemeData(
          color: isDark ? colorScheme.onSurface : const Color(0xFF8D6E63),
        ),
        actions: [
          diaryAsync.maybeWhen(
            data: (entry) => entry != null
                ? IconButton(
                    icon: Icon(
                      Icons.edit_outlined,
                      color: canEdit
                          ? null
                          : (isDark
                                ? colorScheme.onSurface
                                : const Color(0xFF8D6E63))
                              .withValues(alpha: 0.35),
                    ),
                    tooltip: canEdit ? '수정' : '수정 불가',
                    onPressed: () {
                      if (canEdit) {
                        Navigator.of(context).pushReplacement(
                          MaterialPageRoute(
                            builder: (_) => DiaryEditScreen(date: date),
                          ),
                        );
                      } else {
                        ScaffoldMessenger.of(context)
                          ..clearSnackBars()
                          ..showSnackBar(
                            const SnackBar(
                              content: Text(
                                '작성 기간(당일~다음날 15시)이 지나 수정할 수 없어요 🥲',
                              ),
                              behavior: SnackBarBehavior.floating,
                            ),
                          );
                      }
                    },
                  )
                : const SizedBox.shrink(),
            orElse: () => const SizedBox.shrink(),
          ),
        ],
      ),
      body: diaryAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('오류: $e')),
        data: (entry) {
          if (entry == null) {
            return const Center(child: Text('일기가 없습니다.'));
          }

          final isDark = Theme.of(context).brightness == Brightness.dark;
          final cardBg = isDark
              ? Theme.of(context).colorScheme.surfaceContainerLow
              : Colors.white.withValues(alpha: 0.9);
          final borderColor = isDark
              ? Theme.of(context).colorScheme.outline.withValues(alpha: 0.2)
              : const Color(0xFFD7C4A8);

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 이모지 + 메모 카드
                Container(
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: cardBg,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: borderColor, width: 1.5),
                    boxShadow: isDark
                        ? null
                        : [
                            BoxShadow(
                              color: const Color(
                                0xFF8D6E63,
                              ).withValues(alpha: 0.08),
                              blurRadius: 12,
                              offset: const Offset(0, 4),
                            ),
                          ],
                  ),
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _EmotionsDisplay(emotions: entry.emotions.values),
                      if (entry.activities.values.isNotEmpty) ...[
                        const SizedBox(height: 24),
                        _ActivitiesDisplay(
                          activities: entry.activities.values,
                        ),
                      ],
                      if (entry.memo != null && entry.memo!.isNotEmpty) ...[
                        const SizedBox(height: 28),
                        _MemoDisplay(memo: entry.memo!),
                      ],
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                // 작성/수정 일시
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  child: _TimestampDisplay(entry: entry),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

// ─── 이모지 표시 ──────────────────────────────────────────────────────────────

class _EmotionsDisplay extends StatelessWidget {
  final List<Emotion> emotions;

  const _EmotionsDisplay({required this.emotions});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        children: [
          // 이모지 (크게)
          Wrap(
            alignment: WrapAlignment.center,
            spacing: 16,
            children: emotions
                .map((e) => Text(e.emoji, style: const TextStyle(fontSize: 64)))
                .toList(),
          ),
          const SizedBox(height: 12),
          // 감정 레이블
          Wrap(
            alignment: WrapAlignment.center,
            spacing: 8,
            children: emotions
                .map(
                  (e) => Chip(
                    label: Text(e.label),
                    backgroundColor: Theme.of(
                      context,
                    ).colorScheme.primaryContainer,
                  ),
                )
                .toList(),
          ),
        ],
      ),
    );
  }
}

// ─── 오늘 한 일 표시 ──────────────────────────────────────────────────────────

class _ActivitiesDisplay extends StatelessWidget {
  final List<Activity> activities;

  const _ActivitiesDisplay({required this.activities});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final colorScheme = Theme.of(context).colorScheme;
    final labelColor = isDark ? colorScheme.primary : const Color(0xFF8D6E63);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '오늘 한 일',
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w700,
            color: labelColor,
            letterSpacing: 0.3,
          ),
        ),
        const SizedBox(height: 10),
        Wrap(
          alignment: WrapAlignment.start,
          spacing: 8,
          runSpacing: 8,
          children: activities
              .map(
                (a) => Chip(
                  avatar: Text(a.emoji, style: const TextStyle(fontSize: 16)),
                  label: Text(a.label),
                  backgroundColor: colorScheme.secondaryContainer,
                  labelStyle: TextStyle(color: colorScheme.onSecondaryContainer),
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                ),
              )
              .toList(),
        ),
      ],
    );
  }
}

// ─── 메모 표시 ────────────────────────────────────────────────────────────────

class _MemoDisplay extends StatelessWidget {
  final String memo;

  const _MemoDisplay({required this.memo});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final colorScheme = Theme.of(context).colorScheme;
    final labelColor = isDark ? colorScheme.primary : const Color(0xFF8D6E63);
    final memoBg = isDark
        ? colorScheme.surfaceContainerHighest
        : const Color(0xFFF5F0E8);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '메모',
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w700,
            color: labelColor,
            letterSpacing: 0.3,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: memoBg,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(memo, style: const TextStyle(fontSize: 15, height: 1.6)),
        ),
      ],
    );
  }
}

// ─── 작성/수정 일시 표시 ───────────────────────────────────────────────────────

class _TimestampDisplay extends StatelessWidget {
  final DiaryEntry entry;

  const _TimestampDisplay({required this.entry});

  static final _fmt = DateFormat('yyyy년 M월 d일 HH:mm', 'ko');

  @override
  Widget build(BuildContext context) {
    final color = Theme.of(
      context,
    ).colorScheme.onSurface.withValues(alpha: 0.45);
    final style = TextStyle(fontSize: 12, color: color);
    final isModified =
        entry.updatedAt.difference(entry.createdAt).inSeconds > 1;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(Icons.access_time_rounded, size: 13, color: color),
            const SizedBox(width: 4),
            Text('기록: ${_fmt.format(entry.createdAt)}', style: style),
          ],
        ),
        if (isModified) ...[
          const SizedBox(height: 4),
          Row(
            children: [
              Icon(Icons.edit_outlined, size: 13, color: color),
              const SizedBox(width: 4),
              Text('수정: ${_fmt.format(entry.updatedAt)}', style: style),
            ],
          ),
        ],
      ],
    );
  }
}

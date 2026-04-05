import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:maeum_diary/core/utils/date_utils.dart';
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

        return Scaffold(
            appBar: AppBar(
                title: Text(
                    DateFormat('yyyy년 M월 d일 (E)', 'ko').format(date),
                    style: const TextStyle(fontSize: 16),
                ),
                actions: [
                    if (canEdit)
                        diaryAsync.maybeWhen(
                            data: (entry) => entry != null
                                ? IconButton(
                                    icon: const Icon(Icons.edit_outlined),
                                    tooltip: '수정',
                                    onPressed: () {
                                        Navigator.of(context).pushReplacement(
                                            MaterialPageRoute(
                                                builder: (_) =>
                                                    DiaryEditScreen(date: date),
                                            ),
                                        );
                                    },
                                )
                                : const SizedBox.shrink(),
                            orElse: () => const SizedBox.shrink(),
                        ),
                ],
            ),
            body: diaryAsync.when(
                loading: () =>
                    const Center(child: CircularProgressIndicator()),
                error: (e, _) => Center(child: Text('오류: $e')),
                data: (entry) {
                    if (entry == null) {
                        return const Center(child: Text('일기가 없습니다.'));
                    }

                    return SingleChildScrollView(
                        padding: const EdgeInsets.all(24),
                        child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                                // 이모지 크게 표시
                                _EmotionsDisplay(
                                    emotions: entry.emotions.values,
                                ),
                                const SizedBox(height: 32),
                                // 메모
                                if (entry.memo != null && entry.memo!.isNotEmpty)
                                    _MemoDisplay(memo: entry.memo!),
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
                            .map(
                                (e) => Text(
                                    e.emoji,
                                    style: const TextStyle(fontSize: 64),
                                ),
                            )
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
                                    backgroundColor: Theme.of(context)
                                        .colorScheme
                                        .primaryContainer,
                                ),
                            )
                            .toList(),
                    ),
                ],
            ),
        );
    }
}

// ─── 메모 표시 ────────────────────────────────────────────────────────────────

class _MemoDisplay extends StatelessWidget {
    final String memo;

    const _MemoDisplay({required this.memo});

    @override
    Widget build(BuildContext context) {
        final colorScheme = Theme.of(context).colorScheme;
        return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
                Text(
                    '메모',
                    style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: colorScheme.primary,
                    ),
                ),
                const SizedBox(height: 8),
                Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                        color: colorScheme.surfaceContainerHighest,
                        borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                        memo,
                        style: const TextStyle(
                            fontSize: 15,
                            height: 1.6,
                        ),
                    ),
                ),
            ],
        );
    }
}

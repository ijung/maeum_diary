import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:maeum_diary/core/utils/date_utils.dart' as date_utils;
import 'package:maeum_diary/domain/entity/diary_entry.dart';
import 'package:maeum_diary/domain/value_object/emotion.dart';
import 'package:maeum_diary/presentation/provider/calendar_provider.dart';
import 'package:maeum_diary/presentation/screen/diary_detail_screen.dart';
import 'package:maeum_diary/presentation/screen/diary_edit_screen.dart';

/// 앱의 메인 화면 — 월 캘린더
class MainScreen extends ConsumerWidget {
    const MainScreen({super.key});

    @override
    Widget build(BuildContext context, WidgetRef ref) {
        return Scaffold(
            backgroundColor: Theme.of(context).colorScheme.surface,
            appBar: AppBar(
                backgroundColor: Theme.of(context).colorScheme.surface,
                elevation: 0,
                title: const Text(
                    '마음 일기',
                    style: TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 20,
                    ),
                ),
                centerTitle: true,
            ),
            body: const Column(
                children: [
                    _MonthHeader(),
                    SizedBox(height: 8),
                    _WeekDayHeader(),
                    Expanded(child: _CalendarGrid()),
                ],
            ),
        );
    }
}

// ─── 월 헤더 (< 2024년 6월 >) ──────────────────────────────────────────────────

class _MonthHeader extends ConsumerWidget {
    const _MonthHeader();

    @override
    Widget build(BuildContext context, WidgetRef ref) {
        final month = ref.watch(selectedMonthProvider);
        final label = DateFormat('yyyy년 M월', 'ko').format(month);

        return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                    IconButton(
                        icon: const Icon(Icons.chevron_left),
                        onPressed: () {
                            ref.read(selectedMonthProvider.notifier).state =
                                DateTime(month.year, month.month - 1);
                        },
                    ),
                    Text(
                        label,
                        style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                        ),
                    ),
                    IconButton(
                        icon: const Icon(Icons.chevron_right),
                        onPressed: () {
                            ref.read(selectedMonthProvider.notifier).state =
                                DateTime(month.year, month.month + 1);
                        },
                    ),
                ],
            ),
        );
    }
}

// ─── 요일 헤더 (월 화 수 목 금 토 일) ──────────────────────────────────────────

class _WeekDayHeader extends StatelessWidget {
    const _WeekDayHeader();

    static const _labels = ['월', '화', '수', '목', '금', '토', '일'];

    @override
    Widget build(BuildContext context) {
        return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: Row(
                children: _labels
                    .map(
                        (label) => Expanded(
                            child: Center(
                                child: Text(
                                    label,
                                    style: TextStyle(
                                        fontSize: 13,
                                        fontWeight: FontWeight.w600,
                                        color: label == '일'
                                            ? Colors.red.shade400
                                            : label == '토'
                                                ? Colors.blue.shade400
                                                : Theme.of(context)
                                                    .colorScheme
                                                    .onSurface
                                                    .withValues(alpha: 0.6),
                                    ),
                                ),
                            ),
                        ),
                    )
                    .toList(),
            ),
        );
    }
}

// ─── 캘린더 그리드 ─────────────────────────────────────────────────────────────

class _CalendarGrid extends ConsumerWidget {
    const _CalendarGrid();

    @override
    Widget build(BuildContext context, WidgetRef ref) {
        final month = ref.watch(selectedMonthProvider);
        final selectedDate = ref.watch(selectedDateProvider);
        final diaryAsync = ref.watch(monthlyDiaryProvider);

        // 해당 월의 첫 날
        final firstDay = DateTime(month.year, month.month, 1);
        // 월요일 기준 offset (월=0, 화=1, ..., 일=6)
        final offset = (firstDay.weekday - 1) % 7;
        // 해당 월의 마지막 날
        final lastDay = DateTime(month.year, month.month + 1, 0);

        final today = date_utils.toLocalDate(DateTime.now());

        return diaryAsync.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (e, _) => Center(child: Text('오류: $e')),
            data: (diaryMap) {
                final totalCells = offset + lastDay.day;
                final rows = (totalCells / 7).ceil();

                return GridView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    physics: const NeverScrollableScrollPhysics(),
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 7,
                            childAspectRatio: 0.75,
                        ),
                    itemCount: rows * 7,
                    itemBuilder: (context, index) {
                        final dayNumber = index - offset + 1;

                        // 날짜 범위 밖은 빈 셀
                        if (dayNumber < 1 || dayNumber > lastDay.day) {
                            return const SizedBox.shrink();
                        }

                        final cellDate =
                            DateTime(month.year, month.month, dayNumber);
                        final isToday = cellDate == today;
                        final isSelected = cellDate ==
                            date_utils.toLocalDate(selectedDate);

                        final dateKey = _toKey(cellDate);
                        final entry = diaryMap[dateKey];

                        return _DateCell(
                            date: cellDate,
                            entry: entry,
                            isToday: isToday,
                            isSelected: isSelected,
                            onTap: () => _onDateTap(
                                context,
                                ref,
                                cellDate,
                                entry,
                            ),
                        );
                    },
                );
            },
        );
    }

    void _onDateTap(
        BuildContext context,
        WidgetRef ref,
        DateTime date,
        DiaryEntry? entry,
    ) {
        ref.read(selectedDateProvider.notifier).state = date;

        if (entry != null) {
            Navigator.of(context).push(
                MaterialPageRoute(
                    builder: (_) => DiaryDetailScreen(date: date),
                ),
            );
        } else {
            // 오늘/어제만 새 일기 작성 가능
            if (date_utils.isEditableDate(date)) {
                Navigator.of(context).push(
                    MaterialPageRoute(
                        builder: (_) => DiaryEditScreen(date: date),
                    ),
                );
            }
        }
    }

    String _toKey(DateTime dt) {
        final y = dt.year.toString().padLeft(4, '0');
        final m = dt.month.toString().padLeft(2, '0');
        final d = dt.day.toString().padLeft(2, '0');
        return '$y-$m-$d';
    }
}

// ─── 날짜 셀 ──────────────────────────────────────────────────────────────────

class _DateCell extends StatelessWidget {
    final DateTime date;
    final DiaryEntry? entry;
    final bool isToday;
    final bool isSelected;
    final VoidCallback onTap;

    const _DateCell({
        required this.date,
        required this.entry,
        required this.isToday,
        required this.isSelected,
        required this.onTap,
    });

    @override
    Widget build(BuildContext context) {
        final colorScheme = Theme.of(context).colorScheme;
        final isSunday = date.weekday == DateTime.sunday;
        final isSaturday = date.weekday == DateTime.saturday;

        Color dayColor = colorScheme.onSurface;
        if (isSunday) dayColor = Colors.red.shade400;
        if (isSaturday) dayColor = Colors.blue.shade400;

        return GestureDetector(
            onTap: onTap,
            child: Container(
                margin: const EdgeInsets.all(2),
                decoration: BoxDecoration(
                    color: isSelected
                        ? colorScheme.primaryContainer
                        : Colors.transparent,
                    borderRadius: BorderRadius.circular(10),
                    border: isToday
                        ? Border.all(
                            color: colorScheme.primary,
                            width: 2,
                          )
                        : null,
                ),
                child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                        // 날짜 숫자
                        Text(
                            '${date.day}',
                            style: TextStyle(
                                fontSize: 13,
                                fontWeight: isToday
                                    ? FontWeight.w700
                                    : FontWeight.w400,
                                color: isSelected
                                    ? colorScheme.onPrimaryContainer
                                    : dayColor,
                            ),
                        ),
                        const SizedBox(height: 2),
                        // 이모지 (있을 경우)
                        if (entry != null)
                            Text(
                                entry!.emotions.values.first.emoji,
                                style: const TextStyle(fontSize: 18),
                            )
                        else
                            const SizedBox(height: 20),
                    ],
                ),
            ),
        );
    }
}

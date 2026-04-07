import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:maeum_diary/core/utils/date_utils.dart' as date_utils;
import 'package:maeum_diary/domain/entity/diary_entry.dart';
import 'package:maeum_diary/domain/value_object/emotion.dart';
import 'package:maeum_diary/presentation/provider/calendar_provider.dart';
import 'package:maeum_diary/presentation/screen/diary_detail_screen.dart';
import 'package:maeum_diary/presentation/screen/diary_edit_screen.dart';
import 'package:maeum_diary/presentation/screen/settings_screen.dart';

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
                actions: [
                    IconButton(
                        icon: const Icon(Icons.settings_outlined),
                        tooltip: '설정',
                        onPressed: () => Navigator.of(context).push(
                            MaterialPageRoute(
                                builder: (_) => const SettingsScreen(),
                            ),
                        ),
                    ),
                ],
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
        final holidays = ref.watch(holidayProvider(month.year)).valueOrNull ?? {};

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

                        final dateKey = date_utils.toDateKey(cellDate);
                        final entry = diaryMap[dateKey];
                        final holidayName = holidays[dateKey];

                        return _DateCell(
                            date: cellDate,
                            entry: entry,
                            isToday: isToday,
                            isSelected: isSelected,
                            holidayName: holidayName,
                            onTap: () => _onDateTap(
                                context,
                                ref,
                                cellDate,
                                entry,
                                holidayName,
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
        String? holidayName,
    ) {
        ref.read(selectedDateProvider.notifier).state = date;

        final messenger = ScaffoldMessenger.of(context);
        messenger.clearSnackBars();

        if (entry != null) {
            if (holidayName != null) {
                messenger.showSnackBar(
                    SnackBar(
                        content: Text(holidayName),
                        behavior: SnackBarBehavior.floating,
                    ),
                );
            }
            Navigator.of(context).push(
                MaterialPageRoute(
                    builder: (_) => DiaryDetailScreen(date: date),
                ),
            );
        } else if (date_utils.isEditableDate(date)) {
            if (holidayName != null) {
                messenger.showSnackBar(
                    SnackBar(
                        content: Text(holidayName),
                        behavior: SnackBarBehavior.floating,
                    ),
                );
            }
            Navigator.of(context).push(
                MaterialPageRoute(
                    builder: (_) => DiaryEditScreen(date: date),
                ),
            );
        } else {
            final today = date_utils.toLocalDate(DateTime.now());
            final target = date_utils.toLocalDate(date);
            final base = target.isAfter(today)
                ? '아직 오지 않은 하루예요.'
                : '그날의 기록은 남아있지 않아요.';
            final message =
                holidayName != null ? '$holidayName\n$base' : base;

            messenger.showSnackBar(
                SnackBar(
                    content: Text(message),
                    behavior: SnackBarBehavior.floating,
                ),
            );
        }
    }
}

// ─── 날짜 셀 ──────────────────────────────────────────────────────────────────

class _DateCell extends StatelessWidget {
    final DateTime date;
    final DiaryEntry? entry;
    final bool isToday;
    final bool isSelected;
    final String? holidayName;
    final VoidCallback onTap;

    const _DateCell({
        required this.date,
        required this.entry,
        required this.isToday,
        required this.isSelected,
        required this.holidayName,
        required this.onTap,
    });

    @override
    Widget build(BuildContext context) {
        final colorScheme = Theme.of(context).colorScheme;
        final isSunday = date.weekday == DateTime.sunday;
        final isSaturday = date.weekday == DateTime.saturday;
        final isHoliday = holidayName != null;

        Color dayColor = colorScheme.onSurface;
        // 공휴일(일요일 포함)은 빨간색, 토요일 공휴일도 빨간색 우선
        if (isSunday || isHoliday) dayColor = Colors.red.shade400;
        if (isSaturday && !isHoliday) dayColor = Colors.blue.shade400;

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
                        // 선택된 감정 이모지 — 겹쳐서 한 줄 표시
                        if (entry != null)
                            _OverlappingEmojis(emotions: entry!.emotions.values)
                        else
                            const SizedBox(height: 16),
                    ],
                ),
            ),
        );
    }
}

// ─── 겹치는 이모지 행 ──────────────────────────────────────────────────────────

/// 이모지를 일부 겹쳐서 한 줄로 표시하는 위젯
///
/// 셀 너비 초과를 막기 위해 [_step]만큼씩 오른쪽으로 이동하며 배치한다.
class _OverlappingEmojis extends StatelessWidget {
    final Iterable<Emotion> emotions;

    /// 이모지 폰트 크기 (렌더링 높이 ≈ fontSize * 1.3)
    static const double _fontSize = 13;

    /// 각 이모지 사이의 간격 (겹치도록 fontSize보다 작게 유지)
    static const double _step = 9;

    const _OverlappingEmojis({required this.emotions});

    @override
    Widget build(BuildContext context) {
        final list = emotions.toList();
        // 전체 너비: (n-1) * step + 이모지 한 글자 폭(≈fontSize * 1.3)
        final double totalWidth =
            (list.length - 1) * _step + _fontSize * 1.3;
        const double height = _fontSize * 1.35;

        return SizedBox(
            width: totalWidth,
            height: height,
            child: Stack(
                children: [
                    // 역순으로 렌더링해 첫 번째 이모지가 가장 위(앞)에 표시되게 한다
                    for (int i = list.length - 1; i >= 0; i--)
                        Positioned(
                            left: i * _step,
                            top: 0,
                            child: Text(
                                list[i].emoji,
                                style: const TextStyle(fontSize: _fontSize),
                            ),
                        ),
                ],
            ),
        );
    }
}

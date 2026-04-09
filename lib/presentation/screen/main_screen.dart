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
    final colorScheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor = isDark ? colorScheme.surface : const Color(0xFFF5F0E8);

    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        backgroundColor: bgColor,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        title: Text(
          '마음 일기',
          style: TextStyle(
            fontWeight: FontWeight.w800,
            fontSize: 22,
            color: isDark ? colorScheme.onSurface : const Color(0xFF5C4033),
            letterSpacing: 1.5,
          ),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: Icon(
              Icons.settings_outlined,
              color: isDark ? colorScheme.onSurface : const Color(0xFF8D6E63),
            ),
            tooltip: '설정',
            onPressed: () => Navigator.of(
              context,
            ).push(MaterialPageRoute(builder: (_) => const SettingsScreen())),
          ),
        ],
      ),
      body: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
          child: Column(
            children: [
              const _MonthHeader(),
              const SizedBox(height: 8),
              Expanded(child: _CalendarCard(isDark: isDark)),
            ],
          ),
        ),
      ),
    );
  }
}

// ─── 월 헤더 (이전 달 / 2024년 4월 / 다음 달) ─────────────────────────────────

class _MonthHeader extends ConsumerWidget {
  const _MonthHeader();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final month = ref.watch(selectedMonthProvider);
    final label = DateFormat('yyyy년 M월', 'ko').format(month);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final buttonBg = isDark
        ? Theme.of(context).colorScheme.surfaceContainerHighest
        : const Color(0xFFEDE0D4);
    final buttonFg = isDark
        ? Theme.of(context).colorScheme.onSurface
        : const Color(0xFF6D4C41);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
      child: Row(
        children: [
          // 이전 달 버튼
          _NavButton(
            icon: Icons.chevron_left,
            bg: buttonBg,
            fg: buttonFg,
            onTap: () {
              ref.read(selectedMonthProvider.notifier).state = DateTime(
                month.year,
                month.month - 1,
              );
            },
          ),
          // 월 표시 (남은 공간 전부 차지)
          Expanded(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text('🐾', style: TextStyle(fontSize: 14)),
                const SizedBox(width: 6),
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w700,
                    color: isDark
                        ? Theme.of(context).colorScheme.onSurface
                        : const Color(0xFF5C4033),
                  ),
                ),
                const SizedBox(width: 6),
                const Text('🐾', style: TextStyle(fontSize: 14)),
              ],
            ),
          ),
          // 다음 달 버튼
          _NavButton(
            icon: Icons.chevron_right,
            bg: buttonBg,
            fg: buttonFg,
            onTap: () {
              ref.read(selectedMonthProvider.notifier).state = DateTime(
                month.year,
                month.month + 1,
              );
            },
          ),
        ],
      ),
    );
  }
}

/// 이전/다음 달 아이콘 버튼
class _NavButton extends StatelessWidget {
  final IconData icon;
  final Color bg;
  final Color fg;
  final VoidCallback onTap;

  const _NavButton({
    required this.icon,
    required this.bg,
    required this.fg,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(color: bg, shape: BoxShape.circle),
        child: Icon(icon, size: 18, color: fg),
      ),
    );
  }
}

// ─── 캘린더 카드 (요일 헤더 + 그리드) ────────────────────────────────────────

class _CalendarCard extends ConsumerWidget {
  final bool isDark;
  const _CalendarCard({required this.isDark});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cardBg = isDark
        ? Theme.of(context).colorScheme.surfaceContainerLow
        : Colors.white.withValues(alpha: 0.9);
    final borderColor = isDark
        ? Theme.of(context).colorScheme.outline.withValues(alpha: 0.2)
        : const Color(0xFFD7C4A8);

    return GestureDetector(
      onHorizontalDragEnd: (details) {
        final velocity = details.primaryVelocity ?? 0;
        // 오른쪽→왼쪽 스와이프: 다음 달
        // 왼쪽→오른쪽 스와이프: 이전 달
        if (velocity < -300) {
          final month = ref.read(selectedMonthProvider);
          ref.read(selectedMonthProvider.notifier).state =
              DateTime(month.year, month.month + 1);
        } else if (velocity > 300) {
          final month = ref.read(selectedMonthProvider);
          ref.read(selectedMonthProvider.notifier).state =
              DateTime(month.year, month.month - 1);
        }
      },
      child: Container(
        decoration: BoxDecoration(
          color: cardBg,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: borderColor, width: 1.5),
          boxShadow: isDark
              ? null
              : [
                  BoxShadow(
                    color: const Color(0xFF8D6E63).withValues(alpha: 0.08),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(20),
          child: const Column(
            children: [
              _WeekDayHeader(),
              Divider(height: 1, thickness: 1),
              Expanded(child: _AnimatedCalendarGrid()),
            ],
          ),
        ),
      ),
    );
  }
}

// ─── 애니메이션 캘린더 그리드 래퍼 ───────────────────────────────────────────────

/// 월 이동 시 좌우 슬라이드 전환 애니메이션을 적용하는 래퍼
class _AnimatedCalendarGrid extends ConsumerStatefulWidget {
  const _AnimatedCalendarGrid();

  @override
  ConsumerState<_AnimatedCalendarGrid> createState() =>
      _AnimatedCalendarGridState();
}

class _AnimatedCalendarGridState extends ConsumerState<_AnimatedCalendarGrid> {
  // 1 = 다음 달(왼쪽 스와이프), -1 = 이전 달(오른쪽 스와이프)
  int _direction = 1;
  DateTime? _prevMonth;

  @override
  Widget build(BuildContext context) {
    final month = ref.watch(selectedMonthProvider);

    if (_prevMonth != null && month != _prevMonth) {
      _direction = month.isAfter(_prevMonth!) ? 1 : -1;
    }
    _prevMonth = month;

    final direction = _direction;

    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 300),
      transitionBuilder: (child, animation) {
        final isEntering =
            (child.key as ValueKey<DateTime>).value == month;
        final beginOffset = Offset(
          isEntering ? direction.toDouble() : -direction.toDouble(),
          0,
        );
        return SlideTransition(
          position: Tween<Offset>(
            begin: beginOffset,
            end: Offset.zero,
          ).animate(
            CurvedAnimation(parent: animation, curve: Curves.easeInOut),
          ),
          child: child,
        );
      },
      layoutBuilder: (currentChild, previousChildren) => Stack(
        children: [...previousChildren, ?currentChild],
      ),
      child: _CalendarGrid(key: ValueKey(month)),
    );
  }
}

// ─── 요일 헤더 (일 월 화 수 목 금 토) ─────────────────────────────────────────

class _WeekDayHeader extends StatelessWidget {
  const _WeekDayHeader();

  // 월요일 시작
  static const _labels = ['월', '화', '수', '목', '금', '토', '일'];

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final headerBg = isDark
        ? Theme.of(context).colorScheme.surfaceContainerHigh
        : const Color(0xFFF0E6D8);

    return Container(
      color: headerBg,
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        children: _labels.asMap().entries.map((e) {
          final label = e.value;
          Color textColor;
          if (label == '일') {
            textColor = Colors.red.shade400;
          } else if (label == '토') {
            textColor = Colors.blue.shade400;
          } else {
            textColor = isDark
                ? Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7)
                : const Color(0xFF6D4C41).withValues(alpha: 0.8);
          }
          return Expanded(
            child: Center(
              child: Text(
                label,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: textColor,
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}

// ─── 캘린더 그리드 ─────────────────────────────────────────────────────────────

class _CalendarGrid extends ConsumerWidget {
  const _CalendarGrid({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final month = ref.watch(selectedMonthProvider);
    final selectedDate = ref.watch(selectedDateProvider);
    final diaryAsync = ref.watch(monthlyDiaryProvider);
    final holidays = ref.watch(holidayProvider(month.year)).value ?? {};

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

        // LayoutBuilder로 실제 높이를 얻어 행 높이를 동적으로 결정
        return LayoutBuilder(
          builder: (context, constraints) {
            final rowHeight = constraints.maxHeight / rows;

            return Column(
              children: List.generate(rows, (rowIndex) {
                return SizedBox(
                  height: rowHeight,
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: List.generate(7, (colIndex) {
                      final index = rowIndex * 7 + colIndex;
                      final dayNumber = index - offset + 1;

                      // 날짜 범위 밖은 빈 셀
                      if (dayNumber < 1 || dayNumber > lastDay.day) {
                        return const Expanded(child: SizedBox.shrink());
                      }

                      final cellDate = DateTime(
                        month.year,
                        month.month,
                        dayNumber,
                      );
                      final isToday = cellDate == today;
                      final isSelected =
                          cellDate == date_utils.toLocalDate(selectedDate);
                      final dateKey = date_utils.toDateKey(cellDate);
                      final entry = diaryMap[dateKey];
                      final holidayName = holidays[dateKey];

                      return Expanded(
                        child: _DateCell(
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
                        ),
                      );
                    }),
                  ),
                );
              }),
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

    if (entry != null || date_utils.isEditableDate(date)) {
      // 작성·조회 가능한 날짜: 공휴일이면 이름 표시 후 화면 전환
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
          builder: (_) => entry != null
              ? DiaryDetailScreen(date: date)
              : DiaryEditScreen(date: date),
        ),
      );
    } else {
      // 작성 불가 날짜: 사유 메시지 표시
      final today = date_utils.toLocalDate(DateTime.now());
      final target = date_utils.toLocalDate(date);
      final base = target.isAfter(today)
          ? '아직 오지 않은 하루예요.'
          : '이 날짜는 작성 기간(당일~다음날 15시)이 지나 기록할 수 없어요 🥲';
      final message = holidayName != null ? '$holidayName\n$base' : base;

      messenger.showSnackBar(
        SnackBar(content: Text(message), behavior: SnackBarBehavior.floating),
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
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isSunday = date.weekday == DateTime.sunday;
    final isSaturday = date.weekday == DateTime.saturday;
    final isHoliday = holidayName != null;

    Color dayColor = isDark ? colorScheme.onSurface : const Color(0xFF5C4033);
    // 공휴일(일요일 포함)은 빨간색
    if (isSunday || isHoliday) dayColor = Colors.red.shade400;
    if (isSaturday && !isHoliday) dayColor = Colors.blue.shade400;

    // 셀 배경
    Color? cellBg;
    if (isSelected) {
      cellBg = colorScheme.primaryContainer;
    } else if (entry != null && !isDark) {
      cellBg = const Color(0xFFFFF8F0);
    }

    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.all(2),
        width: double.infinity,
        height: double.infinity,
        decoration: BoxDecoration(
          color: cellBg,
          borderRadius: BorderRadius.circular(10),
          border: isToday
              ? Border.all(color: colorScheme.primary, width: 2)
              : null,
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // 날짜 숫자
            Text(
              '${date.day}',
              style: TextStyle(
                fontSize: 12,
                fontWeight: isToday ? FontWeight.w800 : FontWeight.w500,
                color: isSelected ? colorScheme.onPrimaryContainer : dayColor,
              ),
            ),
            const SizedBox(height: 3),
            // 감정 이모지 — 세로 2줄로 표시
            if (entry != null)
              _OverlappingEmojis(emotions: entry!.emotions.values)
            else
              const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
}

// ─── 이모지 표시 ──────────────────────────────────────────────────────────────

/// 감정 이모지를 셀 안에 겹쳐서 한 줄로 표시하는 위젯
///
/// 개수가 적을수록 크게, 많을수록 작게 표시한다.
/// - 1개: 20px / 2개: 17px / 3개: 14px
class _OverlappingEmojis extends StatelessWidget {
  final Iterable<Emotion> emotions;

  const _OverlappingEmojis({required this.emotions});

  // 개수별 폰트 크기
  static double _fontSize(int count) => switch (count) {
    1 => 20,
    2 => 17,
    _ => 14,
  };

  // 이모지 간 겹침 간격 (fontSize보다 약간 작게)
  static double _step(int count) => switch (count) {
    1 => 0,
    2 => 12,
    _ => 10,
  };

  @override
  Widget build(BuildContext context) {
    final list = emotions.toList();
    if (list.isEmpty) return const SizedBox(height: 20);

    final fontSize = _fontSize(list.length);
    final step = _step(list.length);
    final double totalWidth = list.length == 1
        ? fontSize * 1.3
        : (list.length - 1) * step + fontSize * 1.3;
    final double height = fontSize * 1.35;

    return SizedBox(
      width: totalWidth,
      height: height,
      child: Stack(
        children: [
          // 역순 렌더링: 첫 번째 이모지가 가장 앞에 표시됨
          for (int i = list.length - 1; i >= 0; i--)
            Positioned(
              left: i * step,
              top: 0,
              child: Text(list[i].emoji, style: TextStyle(fontSize: fontSize)),
            ),
        ],
      ),
    );
  }
}

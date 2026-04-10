import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:maeum_diary/application/use_case/save_diary_use_case.dart';
import 'package:maeum_diary/core/constants/diary_constants.dart';
import 'package:maeum_diary/core/service/notification_service.dart';
import 'package:maeum_diary/core/utils/date_utils.dart' as date_utils;
import 'package:maeum_diary/domain/value_object/activities_selection.dart';
import 'package:maeum_diary/domain/value_object/activity.dart';
import 'package:maeum_diary/domain/value_object/emotion.dart';
import 'package:maeum_diary/domain/value_object/emotions_selection.dart';
import 'package:maeum_diary/presentation/provider/diary_provider.dart';
import 'package:maeum_diary/presentation/provider/notification_settings_provider.dart';
import 'package:maeum_diary/presentation/theme/app_colors.dart';
import 'package:maeum_diary/presentation/utils/snackbar_helper.dart';

/// 일기 기록 / 수정 화면
class DiaryEditScreen extends ConsumerStatefulWidget {
  final DateTime date;

  const DiaryEditScreen({super.key, required this.date});

  @override
  ConsumerState<DiaryEditScreen> createState() => _DiaryEditScreenState();
}

class _DiaryEditScreenState extends ConsumerState<DiaryEditScreen> {
  late final TextEditingController _memoController;

  // 선택된 감정 목록 (UI 상태로만 관리)
  List<Emotion> _selectedEmotions = [];
  // 선택된 오늘 한 일 목록 (UI 상태로만 관리)
  List<Activity> _selectedActivities = [];
  bool _initialized = false;

  @override
  void initState() {
    super.initState();
    _memoController = TextEditingController();
  }

  @override
  void dispose() {
    _memoController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final diaryAsync = ref.watch(diaryByDateProvider(widget.date));
    final saveState = ref.watch(saveDiaryProvider);

    // 기존 일기가 있으면 초기값 설정 (최초 1회)
    diaryAsync.whenData((entry) {
      if (!_initialized) {
        _initialized = true;
        if (entry != null) {
          setState(() {
            _selectedEmotions = List.of(entry.emotions.values);
            _selectedActivities = List.of(entry.activities.values);
            _memoController.text = entry.memo ?? '';
          });
        }
      }
    });

    final isLoading = saveState is SaveDiaryLoading;
    final canSave = _selectedEmotions.isNotEmpty && !isLoading;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final colorScheme = Theme.of(context).colorScheme;
    final bgColor = isDark ? colorScheme.surface : AppColors.background;
    final titleColor = isDark ? colorScheme.onSurface : AppColors.titleText;

    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        backgroundColor: bgColor,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        title: Text(
          DateFormat('yyyy년 M월 d일 (E)', 'ko').format(widget.date),
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w700,
            color: titleColor,
          ),
        ),
        iconTheme: IconThemeData(
          color: isDark ? colorScheme.onSurface : AppColors.primary,
        ),
        actions: [
          if (isLoading)
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 16),
              child: SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            )
          else
            IconButton(
              onPressed: canSave ? _onSave : null,
              color: isDark ? colorScheme.primary : AppColors.primary,
              icon: const Icon(Icons.check_rounded),
              tooltip: '기록하기',
            ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const _SectionLabel(label: '오늘 어떤 감정을 느꼈나요? (필수, 최대 3개)'),
            const SizedBox(height: 12),
            _EmotionPicker(
              selected: _selectedEmotions,
              onToggle: _toggleEmotion,
              onMaxReached: _onEmotionMaxReached,
            ),
            const SizedBox(height: 32),
            const _SectionLabel(label: '오늘 무엇을 했나요? (최대 5개)'),
            const SizedBox(height: 12),
            _ActivityPicker(
              selected: _selectedActivities,
              onToggle: _toggleActivity,
              onMaxReached: _onActivityMaxReached,
            ),
            const SizedBox(height: 32),
            const _SectionLabel(label: '오늘의 이야기'),
            const SizedBox(height: 12),
            _MemoField(controller: _memoController, maxLength: DiaryConstants.maxMemoLength),
            // 에러 메시지 표시
            if (saveState is SaveDiaryError)
              Padding(
                padding: const EdgeInsets.only(top: 16),
                child: Text(
                  saveState.failure.message,
                  style: TextStyle(color: Theme.of(context).colorScheme.error),
                ),
              ),
          ],
        ),
      ),
    );
  }

  void _onActivityMaxReached() {
    showFloatingSnackBar(context, '오늘 한 일은 최대 5개까지 선택할 수 있어요.');
  }

  void _toggleActivity(Activity activity) {
    setState(() {
      if (_selectedActivities.contains(activity)) {
        _selectedActivities.remove(activity);
      } else {
        if (_selectedActivities.length >= ActivitiesSelection.maxCount) {
          return;
        }
        _selectedActivities.add(activity);
      }
    });
  }

  void _onEmotionMaxReached() {
    showFloatingSnackBar(context, '감정은 최대 3개까지 선택할 수 있어요.');
  }

  void _toggleEmotion(Emotion emotion) {
    setState(() {
      if (_selectedEmotions.contains(emotion)) {
        // 마지막 하나는 제거 불가
        if (_selectedEmotions.length == 1) return;
        _selectedEmotions.remove(emotion);
      } else {
        if (_selectedEmotions.length >= EmotionsSelection.maxCount) {
          return; // 3개 초과 선택 차단
        }
        _selectedEmotions.add(emotion);
      }
    });
  }

  Future<void> _onSave() async {
    if (_selectedEmotions.isEmpty) return;

    EmotionsSelection selection;
    try {
      selection = EmotionsSelection(_selectedEmotions);
    } on ArgumentError catch (e) {
      showFloatingSnackBar(context, e.message.toString());
      return;
    }

    final input = SaveDiaryInput(
      date: widget.date,
      emotions: selection,
      activities: _selectedActivities.isNotEmpty
          ? ActivitiesSelection(_selectedActivities)
          : const ActivitiesSelection.empty(),
      memo: _memoController.text.trim().isEmpty
          ? null
          : _memoController.text.trim(),
    );

    final success = await ref.read(saveDiaryProvider.notifier).save(input);

    if (!mounted) return;

    if (success) {
      final today = date_utils.toLocalDate(DateTime.now());
      if (widget.date == today) {
        final notifSettings = ref.read(notificationSettingsProvider).value;
        if (notifSettings != null &&
            notifSettings.enabled &&
            !notifSettings.alwaysNotify) {
          // 오늘 일기를 방금 저장했으므로 skipToday=true 확정
          unawaited(
            NotificationService.instance.reschedule(
              enabled: true,
              time: notifSettings.time,
              skipToday: true,
            ),
          );
        }
      }
      Navigator.of(context).pop();
    }
  }
}

// ─── 섹션 레이블 ──────────────────────────────────────────────────────────────

class _SectionLabel extends StatelessWidget {
  final String label;

  const _SectionLabel({required this.label});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final color = isDark
        ? Theme.of(context).colorScheme.primary
        : AppColors.primary;
    return Text(
      label,
      style: TextStyle(
        fontSize: 13,
        fontWeight: FontWeight.w700,
        color: color,
        letterSpacing: 0.3,
      ),
    );
  }
}

// ─── 감정 선택기 ──────────────────────────────────────────────────────────────

class _EmotionPicker extends StatelessWidget {
  final List<Emotion> selected;
  final ValueChanged<Emotion> onToggle;
  final VoidCallback onMaxReached;

  const _EmotionPicker({
    required this.selected,
    required this.onToggle,
    required this.onMaxReached,
  });

  @override
  Widget build(BuildContext context) {
    final isMaxSelected = selected.length >= EmotionsSelection.maxCount;
    final colorScheme = Theme.of(context).colorScheme;

    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: Emotion.values.map((emotion) {
        final isSelected = selected.contains(emotion);
        final isDisabled = !isSelected && isMaxSelected;

        final isDark = Theme.of(context).brightness == Brightness.dark;
        final unselectedBg = isDark
            ? colorScheme.surfaceContainerHighest
            : AppColors.selectedBg;
        final borderColor = isDark
            ? colorScheme.primary
            : AppColors.primary;

        return GestureDetector(
          onTap: isDisabled ? onMaxReached : () => onToggle(emotion),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 150),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: isSelected
                  ? colorScheme.primaryContainer
                  : isDisabled
                  ? unselectedBg.withValues(alpha: 0.4)
                  : unselectedBg,
              borderRadius: BorderRadius.circular(20),
              border: isSelected
                  ? Border.all(color: borderColor, width: 2)
                  : null,
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(emotion.emoji, style: const TextStyle(fontSize: 22)),
                const SizedBox(width: 6),
                Text(
                  emotion.label,
                  style: TextStyle(
                    fontSize: 13,
                    color: isDisabled
                        ? colorScheme.onSurface.withValues(alpha: 0.4)
                        : isSelected
                        ? colorScheme.onPrimaryContainer
                        : colorScheme.onSurface,
                  ),
                ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }
}

// ─── 오늘 한 일 선택기 ─────────────────────────────────────────────────────────

class _ActivityPicker extends StatelessWidget {
  final List<Activity> selected;
  final ValueChanged<Activity> onToggle;
  final VoidCallback onMaxReached;

  const _ActivityPicker({
    required this.selected,
    required this.onToggle,
    required this.onMaxReached,
  });

  @override
  Widget build(BuildContext context) {
    final isMaxSelected = selected.length >= ActivitiesSelection.maxCount;
    final colorScheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final unselectedBg = isDark
        ? colorScheme.surfaceContainerHighest
        : AppColors.selectedBg;
    final borderColor = isDark ? colorScheme.primary : AppColors.primary;

    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: Activity.values.map((activity) {
        final isSelected = selected.contains(activity);
        final isDisabled = !isSelected && isMaxSelected;

        return GestureDetector(
          onTap: isDisabled ? onMaxReached : () => onToggle(activity),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 150),
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: isSelected
                  ? colorScheme.primaryContainer
                  : isDisabled
                  ? unselectedBg.withValues(alpha: 0.4)
                  : unselectedBg,
              borderRadius: BorderRadius.circular(14),
              border: isSelected
                  ? Border.all(color: borderColor, width: 2)
                  : null,
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(activity.emoji, style: const TextStyle(fontSize: 16)),
                const SizedBox(width: 3),
                Text(
                  activity.label,
                  style: TextStyle(
                    fontSize: 11,
                    color: isDisabled
                        ? colorScheme.onSurface.withValues(alpha: 0.4)
                        : isSelected
                        ? colorScheme.onPrimaryContainer
                        : colorScheme.onSurface,
                  ),
                ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }
}

// ─── 메모 입력 필드 ───────────────────────────────────────────────────────────

class _MemoField extends StatefulWidget {
  final TextEditingController controller;
  final int maxLength;

  const _MemoField({required this.controller, required this.maxLength});

  @override
  State<_MemoField> createState() => _MemoFieldState();
}

class _MemoFieldState extends State<_MemoField> {
  int _length = 0;

  @override
  void initState() {
    super.initState();
    _length = widget.controller.text.length;
    widget.controller.addListener(_onChanged);
  }

  @override
  void dispose() {
    widget.controller.removeListener(_onChanged);
    super.dispose();
  }

  void _onChanged() {
    setState(() => _length = widget.controller.text.length);
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final colorScheme = Theme.of(context).colorScheme;
    final isOver = _length > widget.maxLength;
    final fieldBg = isDark
        ? colorScheme.surfaceContainerHighest
        : Colors.white.withValues(alpha: 0.9);
    final borderColor = isDark
        ? colorScheme.outline.withValues(alpha: 0.3)
        : AppColors.cardBorder;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        TextField(
          controller: widget.controller,
          maxLines: 8,
          minLines: 4,
          decoration: InputDecoration(
            hintText: '오늘의 이야기를 남겨보세요',
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: BorderSide(color: borderColor, width: 1.5),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: BorderSide(color: borderColor, width: 1.5),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: BorderSide(
                color: isDark ? colorScheme.primary : AppColors.primary,
                width: 2,
              ),
            ),
            filled: true,
            fillColor: fieldBg,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          '$_length / ${widget.maxLength}',
          style: TextStyle(
            fontSize: 12,
            color: isOver
                ? colorScheme.error
                : colorScheme.onSurface.withValues(alpha: 0.5),
          ),
        ),
      ],
    );
  }
}

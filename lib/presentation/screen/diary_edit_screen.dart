import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:maeum_diary/application/use_case/save_diary_use_case.dart';
import 'package:maeum_diary/core/service/notification_service.dart';
import 'package:maeum_diary/core/utils/date_utils.dart' as date_utils;
import 'package:maeum_diary/domain/value_object/emotion.dart';
import 'package:maeum_diary/domain/value_object/emotions_selection.dart';
import 'package:maeum_diary/presentation/provider/diary_provider.dart';
import 'package:maeum_diary/presentation/provider/settings_provider.dart';

/// 일기 작성 / 수정 화면
class DiaryEditScreen extends ConsumerStatefulWidget {
    final DateTime date;

    const DiaryEditScreen({super.key, required this.date});

    @override
    ConsumerState<DiaryEditScreen> createState() => _DiaryEditScreenState();
}

class _DiaryEditScreenState extends ConsumerState<DiaryEditScreen> {
    static const int _maxMemoLength = 500;

    late final TextEditingController _memoController;

    // 선택된 감정 목록 (UI 상태로만 관리)
    List<Emotion> _selectedEmotions = [];
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
                        _memoController.text = entry.memo ?? '';
                    });
                }
            }
        });

        final isLoading = saveState is SaveDiaryLoading;
        final canSave = _selectedEmotions.isNotEmpty && !isLoading;

        return Scaffold(
            appBar: AppBar(
                title: Text(
                    DateFormat('yyyy년 M월 d일 (E)', 'ko').format(widget.date),
                    style: const TextStyle(fontSize: 16),
                ),
                actions: [
                    TextButton(
                        onPressed: canSave ? _onSave : null,
                        child: isLoading
                            ? const SizedBox(
                                width: 18,
                                height: 18,
                                child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                ),
                              )
                            : const Text(
                                '저장',
                                style: TextStyle(fontWeight: FontWeight.w700),
                              ),
                    ),
                ],
            ),
            body: SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                        const _SectionLabel(label: '오늘의 감정 (최대 3개)'),
                        const SizedBox(height: 12),
                        _EmotionPicker(
                            selected: _selectedEmotions,
                            onToggle: _toggleEmotion,
                            onMaxReached: _onEmotionMaxReached,
                        ),
                        const SizedBox(height: 32),
                        const _SectionLabel(label: '메모 (선택)'),
                        const SizedBox(height: 12),
                        _MemoField(
                            controller: _memoController,
                            maxLength: _maxMemoLength,
                        ),
                        // 에러 메시지 표시
                        if (saveState is SaveDiaryError)
                            Padding(
                                padding: const EdgeInsets.only(top: 16),
                                child: Text(
                                    saveState.failure.message,
                                    style: TextStyle(
                                        color: Theme.of(context)
                                            .colorScheme
                                            .error,
                                    ),
                                ),
                            ),
                    ],
                ),
            ),
        );
    }

    void _onEmotionMaxReached() {
        final messenger = ScaffoldMessenger.of(context);
        messenger.clearSnackBars();
        messenger.showSnackBar(
            const SnackBar(
                content: Text('감정은 최대 3개까지 선택할 수 있어요.'),
                behavior: SnackBarBehavior.floating,
            ),
        );
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
            final messenger = ScaffoldMessenger.of(context);
            messenger.clearSnackBars();
            messenger.showSnackBar(
                SnackBar(content: Text(e.message.toString())),
            );
            return;
        }

        final input = SaveDiaryInput(
            date: widget.date,
            emotions: selection,
            memo: _memoController.text.trim().isEmpty
                ? null
                : _memoController.text.trim(),
        );

        final success = await ref.read(saveDiaryProvider.notifier).save(input);

        if (!mounted) return;

        if (success) {
            final today = date_utils.toLocalDate(DateTime.now());
            if (widget.date == today) {
                final notifSettings =
                    ref.read(notificationSettingsProvider).valueOrNull;
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
        return Text(
            label,
            style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: Theme.of(context).colorScheme.primary,
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

                return GestureDetector(
                    onTap: isDisabled ? onMaxReached : () => onToggle(emotion),
                    child: AnimatedContainer(
                        duration: const Duration(milliseconds: 150),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 8,
                        ),
                        decoration: BoxDecoration(
                            color: isSelected
                                ? colorScheme.primaryContainer
                                : isDisabled
                                    ? colorScheme.surfaceContainerHighest
                                        .withValues(alpha:0.4)
                                    : colorScheme.surfaceContainerHighest,
                            borderRadius: BorderRadius.circular(20),
                            border: isSelected
                                ? Border.all(
                                    color: colorScheme.primary,
                                    width: 2,
                                  )
                                : null,
                        ),
                        child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                                Text(
                                    emotion.emoji,
                                    style: const TextStyle(fontSize: 22),
                                ),
                                const SizedBox(width: 6),
                                Text(
                                    emotion.label,
                                    style: TextStyle(
                                        fontSize: 13,
                                        color: isDisabled
                                            ? colorScheme.onSurface
                                                .withValues(alpha:0.4)
                                            : isSelected
                                                ? colorScheme
                                                    .onPrimaryContainer
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

    const _MemoField({
        required this.controller,
        required this.maxLength,
    });

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
        final colorScheme = Theme.of(context).colorScheme;
        final isOver = _length > widget.maxLength;

        return Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
                TextField(
                    controller: widget.controller,
                    maxLines: 8,
                    minLines: 4,
                    decoration: InputDecoration(
                        hintText: '오늘 하루 어떠셨나요?',
                        border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                        ),
                        filled: true,
                        fillColor: colorScheme.surfaceContainerHighest,
                    ),
                ),
                const SizedBox(height: 4),
                Text(
                    '$_length / ${widget.maxLength}',
                    style: TextStyle(
                        fontSize: 12,
                        color: isOver
                            ? colorScheme.error
                            : colorScheme.onSurface.withValues(alpha:0.5),
                    ),
                ),
            ],
        );
    }
}

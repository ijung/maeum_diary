import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:maeum_diary/presentation/provider/settings_provider.dart';

/// 설정 화면
class SettingsScreen extends StatelessWidget {
    const SettingsScreen({super.key});

    @override
    Widget build(BuildContext context) {
        return Scaffold(
            backgroundColor: Theme.of(context).colorScheme.surface,
            appBar: AppBar(
                backgroundColor: Theme.of(context).colorScheme.surface,
                elevation: 0,
                title: const Text(
                    '설정',
                    style: TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 20,
                    ),
                ),
                centerTitle: true,
            ),
            body: ListView(
                children: const [
                    _SectionHeader('테마'),
                    _ThemeTile(),
                    Divider(indent: 16, endIndent: 16),
                    _SectionHeader('알림'),
                    _NotificationSwitchTile(),
                    _NotificationTimeTile(),
                    Divider(indent: 16, endIndent: 16),
                    _SectionHeader('앱 정보'),
                    _AppVersionTile(),
                ],
            ),
        );
    }
}

// ─── 섹션 헤더 ────────────────────────────────────────────────────────────────

class _SectionHeader extends StatelessWidget {
    final String title;
    const _SectionHeader(this.title);

    @override
    Widget build(BuildContext context) {
        return Padding(
            padding: const EdgeInsets.fromLTRB(16, 20, 16, 8),
            child: Text(
                title,
                style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: Theme.of(context).colorScheme.primary,
                ),
            ),
        );
    }
}

// ─── 테마 설정 ────────────────────────────────────────────────────────────────

class _ThemeTile extends ConsumerWidget {
    const _ThemeTile();

    @override
    Widget build(BuildContext context, WidgetRef ref) {
        final themeMode =
            ref.watch(themeModeProvider).valueOrNull ?? ThemeMode.system;

        return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                    const Text('테마 설정', style: TextStyle(fontSize: 15)),
                    const SizedBox(height: 10),
                    SegmentedButton<ThemeMode>(
                        segments: const [
                            ButtonSegment(
                                value: ThemeMode.system,
                                label: Text('시스템'),
                                icon: Icon(Icons.brightness_auto_outlined),
                            ),
                            ButtonSegment(
                                value: ThemeMode.light,
                                label: Text('라이트'),
                                icon: Icon(Icons.light_mode_outlined),
                            ),
                            ButtonSegment(
                                value: ThemeMode.dark,
                                label: Text('다크'),
                                icon: Icon(Icons.dark_mode_outlined),
                            ),
                        ],
                        selected: {themeMode},
                        onSelectionChanged: (selected) {
                            ref
                                .read(themeModeProvider.notifier)
                                .setThemeMode(selected.first);
                        },
                    ),
                ],
            ),
        );
    }
}

// ─── 알림 설정 ────────────────────────────────────────────────────────────────

class _NotificationSwitchTile extends ConsumerWidget {
    const _NotificationSwitchTile();

    @override
    Widget build(BuildContext context, WidgetRef ref) {
        final settingsAsync = ref.watch(notificationSettingsProvider);
        final settings = settingsAsync.valueOrNull;

        return SwitchListTile(
            title: const Text('매일 일기 알림'),
            subtitle: const Text('설정한 시간에 일기 작성을 알려드려요'),
            value: settings?.enabled ?? false,
            onChanged: settings == null
                ? null
                : (value) {
                    ref
                        .read(notificationSettingsProvider.notifier)
                        .setEnabled(value);
                },
        );
    }
}

class _NotificationTimeTile extends ConsumerWidget {
    const _NotificationTimeTile();

    @override
    Widget build(BuildContext context, WidgetRef ref) {
        final settingsAsync = ref.watch(notificationSettingsProvider);
        final settings = settingsAsync.valueOrNull;
        final enabled = settings?.enabled ?? false;
        final time = settings?.time ?? const TimeOfDay(hour: 21, minute: 0);

        return ListTile(
            title: const Text('알림 시간'),
            trailing: Text(
                _formatTime(time),
                style: TextStyle(
                    fontSize: 15,
                    color: enabled
                        ? Theme.of(context).colorScheme.primary
                        : Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.4),
                ),
            ),
            enabled: enabled,
            onTap: enabled
                ? () async {
                    final picked = await showTimePicker(
                        context: context,
                        initialTime: time,
                        helpText: '알림 시간 선택',
                    );
                    if (picked != null) {
                        await ref
                            .read(notificationSettingsProvider.notifier)
                            .setTime(picked);
                    }
                }
                : null,
        );
    }

    String _formatTime(TimeOfDay time) {
        final hour = time.hour;
        final minute = time.minute;
        final period = hour < 12 ? '오전' : '오후';
        final displayHour = hour == 0 ? 12 : (hour > 12 ? hour - 12 : hour);
        final displayMinute = minute.toString().padLeft(2, '0');
        return '$period $displayHour:$displayMinute';
    }
}

// ─── 앱 정보 ──────────────────────────────────────────────────────────────────

class _AppVersionTile extends ConsumerWidget {
    const _AppVersionTile();

    @override
    Widget build(BuildContext context, WidgetRef ref) {
        return ref.watch(packageInfoProvider).when(
            data: (info) => ListTile(
                title: const Text('버전'),
                trailing: Text(
                    '${info.version} (${info.buildNumber})',
                    style: TextStyle(
                        fontSize: 14,
                        color: Theme.of(context)
                            .colorScheme
                            .onSurface
                            .withValues(alpha: 0.6),
                    ),
                ),
            ),
            loading: () => const ListTile(
                title: Text('버전'),
                trailing: SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                ),
            ),
            error: (_, _) => const ListTile(
                title: Text('버전'),
                trailing: Text('-'),
            ),
        );
    }
}

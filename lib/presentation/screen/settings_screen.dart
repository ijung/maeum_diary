import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:maeum_diary/presentation/provider/app_info_provider.dart';
import 'package:maeum_diary/presentation/provider/notification_settings_provider.dart';
import 'package:maeum_diary/presentation/provider/theme_provider.dart';

/// 설정 화면
class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor = isDark ? cs.surface : const Color(0xFFF5F0E8);
    final titleColor = isDark ? cs.onSurface : const Color(0xFF5C4033);

    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        backgroundColor: bgColor,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        title: Text(
          '설정',
          style: TextStyle(
            fontWeight: FontWeight.w800,
            fontSize: 20,
            color: titleColor,
            letterSpacing: 0.5,
          ),
        ),
        iconTheme: IconThemeData(
          color: isDark ? cs.onSurface : const Color(0xFF8D6E63),
        ),
        centerTitle: true,
      ),
      body: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        children: const [
          _SectionLabel('테마'),
          _SectionCard(children: [_ThemeTile()]),
          _SectionLabel('알림'),
          _SectionCard(
            children: [
              _NotificationSwitchTile(),
              _SectionDivider(),
              _NotificationTimeTile(),
              _SectionDivider(),
              _AlwaysNotifyTile(),
            ],
          ),
          _SectionLabel('앱 정보'),
          _SectionCard(children: [_AppVersionTile()]),
          SizedBox(height: 24),
        ],
      ),
    );
  }
}

// ─── 공통 레이아웃 ────────────────────────────────────────────────────────────

class _SectionLabel extends StatelessWidget {
  final String text;
  const _SectionLabel(this.text);

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final color = isDark
        ? Theme.of(context).colorScheme.primary
        : const Color(0xFF8D6E63);
    return Padding(
      padding: const EdgeInsets.fromLTRB(4, 20, 4, 8),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.5,
          color: color,
        ),
      ),
    );
  }
}

class _SectionCard extends StatelessWidget {
  final List<Widget> children;
  const _SectionCard({required this.children});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardBg = isDark
        ? Theme.of(context).colorScheme.surfaceContainerLow
        : Colors.white.withValues(alpha: 0.9);
    final borderColor = isDark
        ? Theme.of(context).colorScheme.outline.withValues(alpha: 0.2)
        : const Color(0xFFD7C4A8);

    return Container(
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
        child: Column(children: children),
      ),
    );
  }
}

class _SectionDivider extends StatelessWidget {
  const _SectionDivider();

  @override
  Widget build(BuildContext context) {
    return Divider(
      height: 1,
      indent: 56,
      endIndent: 16,
      color: Theme.of(
        context,
      ).colorScheme.outlineVariant.withValues(alpha: 0.5),
    );
  }
}

// ─── 테마 설정 ────────────────────────────────────────────────────────────────

class _ThemeTile extends ConsumerWidget {
  const _ThemeTile();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeMode = ref.watch(themeModeProvider).value ?? ThemeMode.system;
    final cs = Theme.of(context).colorScheme;

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.palette_outlined,
                color: cs.onSurfaceVariant,
                size: 22,
              ),
              const SizedBox(width: 16),
              const Text('테마', style: TextStyle(fontSize: 15)),
            ],
          ),
          const SizedBox(height: 12),
          SegmentedButton<ThemeMode>(
            style: SegmentedButton.styleFrom(
              visualDensity: VisualDensity.compact,
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
            segments: const [
              ButtonSegment(value: ThemeMode.system, label: Text('시스템', maxLines: 1)),
              ButtonSegment(value: ThemeMode.light, label: Text('밝게', maxLines: 1)),
              ButtonSegment(value: ThemeMode.dark, label: Text('어둡게', maxLines: 1)),
            ],
            selected: {themeMode},
            showSelectedIcon: false,
            expandedInsets: EdgeInsets.zero,
            onSelectionChanged: (selected) {
              ref.read(themeModeProvider.notifier).setThemeMode(selected.first);
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
    final settings = ref.watch(notificationSettingsProvider).value;

    return SwitchListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 16),
      secondary: Icon(
        Icons.notifications_outlined,
        color: Theme.of(context).colorScheme.onSurfaceVariant,
        size: 22,
      ),
      title: const Text('매일 일기 알림', style: TextStyle(fontSize: 15)),
      subtitle: const Text('설정한 시간에 일기 작성을 알려드려요'),
      value: settings?.enabled ?? false,
      onChanged: settings == null
          ? null
          : (value) => ref
                .read(notificationSettingsProvider.notifier)
                .setEnabled(value),
    );
  }
}

class _NotificationTimeTile extends ConsumerWidget {
  const _NotificationTimeTile();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(notificationSettingsProvider).value;
    final enabled = settings?.enabled ?? false;
    final time = settings?.time ?? const TimeOfDay(hour: 21, minute: 0);
    final cs = Theme.of(context).colorScheme;

    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 16),
      leading: Icon(
        Icons.access_time_outlined,
        color: cs.onSurfaceVariant,
        size: 22,
      ),
      title: const Text('알림 시간', style: TextStyle(fontSize: 15)),
      trailing: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
          color: enabled ? cs.primaryContainer : cs.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Text(
          _formatTime(time),
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: enabled
                ? cs.onPrimaryContainer
                : cs.onSurface.withValues(alpha: 0.38),
          ),
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

class _AlwaysNotifyTile extends ConsumerWidget {
  const _AlwaysNotifyTile();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(notificationSettingsProvider).value;

    return SwitchListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 16),
      secondary: Icon(
        Icons.edit_calendar_outlined,
        color: Theme.of(context).colorScheme.onSurfaceVariant,
        size: 22,
      ),
      title: const Text('기록 후에도 알림', style: TextStyle(fontSize: 15)),
      subtitle: const Text('일기를 썼어도 알림을 받아요'),
      value: settings?.alwaysNotify ?? false,
      onChanged: (settings?.enabled == true)
          ? (value) => ref
                .read(notificationSettingsProvider.notifier)
                .setAlwaysNotify(value)
          : null,
    );
  }
}

// ─── 앱 정보 ──────────────────────────────────────────────────────────────────

class _AppVersionTile extends ConsumerWidget {
  const _AppVersionTile();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cs = Theme.of(context).colorScheme;

    return ref
        .watch(packageInfoProvider)
        .when(
          data: (info) => ListTile(
            contentPadding: const EdgeInsets.symmetric(horizontal: 16),
            leading: Icon(
              Icons.info_outline,
              color: cs.onSurfaceVariant,
              size: 22,
            ),
            title: const Text('버전', style: TextStyle(fontSize: 15)),
            trailing: Text(
              '${info.version} (${info.buildNumber})',
              style: TextStyle(
                fontSize: 13,
                color: cs.onSurface.withValues(alpha: 0.5),
              ),
            ),
          ),
          loading: () => ListTile(
            contentPadding: const EdgeInsets.symmetric(horizontal: 16),
            leading: Icon(
              Icons.info_outline,
              color: cs.onSurfaceVariant,
              size: 22,
            ),
            title: const Text('버전', style: TextStyle(fontSize: 15)),
            trailing: SizedBox(
              width: 16,
              height: 16,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: cs.primary,
              ),
            ),
          ),
          error: (_, _) => ListTile(
            contentPadding: const EdgeInsets.symmetric(horizontal: 16),
            leading: Icon(
              Icons.info_outline,
              color: cs.onSurfaceVariant,
              size: 22,
            ),
            title: const Text('버전', style: TextStyle(fontSize: 15)),
            trailing: Text(
              '-',
              style: TextStyle(color: cs.onSurface.withValues(alpha: 0.5)),
            ),
          ),
        );
  }
}

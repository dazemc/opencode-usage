import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import 'api.dart';
import 'theme.dart';
import 'widgets.dart';

/// The window body: a strip of floating pills over an accent-lit backdrop.
class UsageDashboard extends StatelessWidget {
  const UsageDashboard({
    required this.accent,
    required this.snapshot,
    required this.onRefresh,
    this.error,
    this.loading = false,
    this.onOpenConsole,
    super.key,
  });

  final WallpaperAccent accent;
  final UsageSnapshot? snapshot;
  final String? error;
  final bool loading;
  final VoidCallback onRefresh;
  final VoidCallback? onOpenConsole;

  @override
  Widget build(BuildContext context) {
    return TricksterBackdrop(
      accent: accent,
      child: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(26, 24, 26, 8),
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 900),
                    child: _Body(
                      accent: accent,
                      snapshot: snapshot,
                      error: error,
                      loading: loading,
                      onRefresh: onRefresh,
                    ),
                  ),
                ),
              ),
            ),
            if (snapshot != null)
              Padding(
                padding: const EdgeInsets.fromLTRB(26, 4, 26, 22),
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 900),
                    child: TricksterEntrance(
                      index: 8,
                      child: _Footer(
                        accent: accent,
                        snapshot: snapshot!,
                        onOpenConsole: onOpenConsole,
                      ),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _Body extends StatelessWidget {
  const _Body({
    required this.accent,
    required this.snapshot,
    required this.error,
    required this.loading,
    required this.onRefresh,
  });

  final WallpaperAccent accent;
  final UsageSnapshot? snapshot;
  final String? error;
  final bool loading;
  final VoidCallback onRefresh;

  @override
  Widget build(BuildContext context) {
    final data = snapshot;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        TricksterEntrance(
          index: 0,
          child: _Header(
            accent: accent,
            workspace: data?.workspaceName,
            updatedAt: data?.fetchedAt,
            loading: loading,
            onRefresh: onRefresh,
          ),
        ),
        if (error != null && data != null) ...[
          const SizedBox(height: 14),
          _ErrorNote(accent: accent, message: error!, onRetry: onRefresh),
        ],
        const SizedBox(height: 22),
        if (data == null)
          _Empty(
            accent: accent,
            error: error,
            loading: loading,
            onRetry: onRefresh,
          )
        else ...[
          TricksterEntrance(
            index: 1,
            child: _SectionLabel(
              accent: accent,
              label: 'ALLOWANCE',
              trailing: 'OpenCode Go',
            ),
          ),
          const SizedBox(height: 10),
          _MeterGrid(accent: accent, snapshot: data),
          if (data.budgets.isNotEmpty) ...[
            const SizedBox(height: 14),
            TricksterEntrance(
              index: 5,
              child: _BudgetsPanel(accent: accent, budgets: data.budgets),
            ),
          ],
          const SizedBox(height: 14),
          TricksterEntrance(
            index: 6,
            child: _SessionPanel(accent: accent, session: data.session),
          ),
          if (data.session != null && data.session!.totalTokens > 0) ...[
            const SizedBox(height: 14),
            TricksterEntrance(
              index: 7,
              child: _TokenBreakdown(accent: accent, session: data.session!),
            ),
          ],
        ],
      ],
    );
  }
}

class _Header extends StatelessWidget {
  const _Header({
    required this.accent,
    required this.workspace,
    required this.updatedAt,
    required this.loading,
    required this.onRefresh,
  });

  final WallpaperAccent accent;
  final String? workspace;
  final DateTime? updatedAt;
  final bool loading;
  final VoidCallback onRefresh;

  @override
  Widget build(BuildContext context) {
    return TricksterPanel(
      accent: accent,
      radius: 999,
      padding: const EdgeInsets.fromLTRB(14, 10, 12, 10),
      child: Row(
        children: [
          TricksterMark(accent: accent),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'OpenCode',
                  style: ShellText.systemBarValue.copyWith(
                    fontSize: 16,
                    color: ShellMediaColors.lightForeground,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  workspace ?? 'Waiting for a workspace',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: ShellText.systemBarCaption.copyWith(
                    color: accent.captionColor(),
                  ),
                ),
              ],
            ),
          ),
          if (updatedAt != null) ...[
            const SizedBox(width: 12),
            Text(
              'UPDATED ${_clock(updatedAt!)}',
              style: ShellText.systemBarCaption.copyWith(
                color: accent.captionColor().withValues(alpha: 0.75),
                fontSize: 10,
                letterSpacing: 0.8,
              ),
            ),
          ],
          const SizedBox(width: 10),
          TricksterIconButton(
            accent: accent,
            icon: LucideIcons.refreshCw,
            label: 'Refresh',
            loading: loading,
            onPressed: loading ? null : onRefresh,
          ),
        ],
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  const _SectionLabel({
    required this.accent,
    required this.label,
    this.trailing,
  });

  final WallpaperAccent accent;
  final String label;
  final String? trailing;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 6,
          height: 6,
          decoration: BoxDecoration(
            color: accent.color,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 8),
        Text(
          label,
          style: ShellText.systemBarCaption.copyWith(
            color: accent.captionColor(),
            letterSpacing: 1.3,
          ),
        ),
        const Spacer(),
        if (trailing != null)
          Text(
            trailing!,
            style: ShellText.systemBarCaption.copyWith(
              color: ShellMediaColors.lightForegroundSecondary.withValues(
                alpha: 0.5,
              ),
            ),
          ),
      ],
    );
  }
}

class _MeterGrid extends StatelessWidget {
  const _MeterGrid({required this.accent, required this.snapshot});

  final WallpaperAccent accent;
  final UsageSnapshot snapshot;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final cards = [
          TricksterEntrance(
            index: 2,
            child: _MeterCard(
              accent: accent,
              label: 'Rolling',
              meter: snapshot.rolling,
            ),
          ),
          TricksterEntrance(
            index: 3,
            child: _MeterCard(
              accent: accent,
              label: 'Weekly',
              meter: snapshot.weekly,
            ),
          ),
          TricksterEntrance(
            index: 4,
            child: _MeterCard(
              accent: accent,
              label: 'Monthly',
              meter: snapshot.monthly,
            ),
          ),
        ];
        if (constraints.maxWidth < 700) {
          return Column(
            children: [
              for (final card in cards) ...[
                card,
                if (card != cards.last) const SizedBox(height: 12),
              ],
            ],
          );
        }
        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            for (final card in cards) ...[
              Expanded(child: card),
              if (card != cards.last) const SizedBox(width: 12),
            ],
          ],
        );
      },
    );
  }
}

class _MeterCard extends StatelessWidget {
  const _MeterCard({
    required this.accent,
    required this.label,
    required this.meter,
  });

  final WallpaperAccent accent;
  final String label;
  final MeterUsage meter;

  @override
  Widget build(BuildContext context) {
    final used = meter.percent.round();
    final left = meter.remaining.round();
    final valueColor = meter.limited
        ? ShellTelemetryColors.danger
        : accent.color;
    return TricksterPanel(
      accent: accent,
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Container(
                width: 7,
                height: 7,
                decoration: BoxDecoration(
                  color: valueColor,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 7),
              Text(
                label,
                style: ShellText.systemBarCaption.copyWith(
                  color: accent.captionColor(),
                ),
              ),
              const Spacer(),
              if (meter.limited)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 7,
                    vertical: 3,
                  ),
                  decoration: BoxDecoration(
                    color: ShellTelemetryColors.danger.withValues(alpha: 0.14),
                    borderRadius: const BorderRadius.all(Radius.circular(999)),
                    border: Border.all(
                      color: ShellTelemetryColors.danger.withValues(alpha: 0.3),
                    ),
                  ),
                  child: Text(
                    'LIMIT',
                    style: ShellText.systemBarCaption.copyWith(
                      color: ShellTelemetryColors.danger,
                      fontSize: 9,
                      letterSpacing: 0.8,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              TricksterGauge(
                accent: accent,
                percent: meter.percent,
                limited: meter.limited,
                size: 76,
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      '$used%',
                      style: ShellText.systemBarValue.copyWith(
                        fontSize: 28,
                        color: valueColor,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'used',
                      style: ShellText.systemBarCaption.copyWith(
                        color: ShellMediaColors.lightForegroundSecondary
                            .withValues(alpha: 0.65),
                      ),
                    ),
                    const SizedBox(height: 7),
                    Text(
                      '$left% left',
                      style: ShellText.systemBarCaption.copyWith(
                        color: accent.captionColor(),
                      ),
                    ),
                    const SizedBox(height: 5),
                    Text(
                      formatReset(meter.resetsAt),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: ShellText.systemBarCaption.copyWith(
                        color: ShellMediaColors.lightForegroundSecondary
                            .withValues(alpha: 0.55),
                        fontSize: 10,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _SessionPanel extends StatelessWidget {
  const _SessionPanel({required this.accent, required this.session});

  final WallpaperAccent accent;
  final SessionUsage? session;

  @override
  Widget build(BuildContext context) {
    final data = session;
    return TricksterPanel(
      accent: accent,
      padding: const EdgeInsets.fromLTRB(18, 15, 18, 18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                'NEWEST SESSION',
                style: ShellText.systemBarCaption.copyWith(
                  color: accent.captionColor(),
                  letterSpacing: 1.1,
                ),
              ),
              const Spacer(),
              if (data?.model != null)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: accent.color.withValues(alpha: 0.10),
                    borderRadius: const BorderRadius.all(Radius.circular(999)),
                    border: Border.all(
                      color: accent.color.withValues(alpha: 0.16),
                    ),
                  ),
                  child: Text(
                    data!.model!,
                    style: ShellText.systemBarCaption.copyWith(
                      color: accent.captionColor(),
                      fontSize: 10,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 10),
          if (data == null)
            Text(
              'No session has been recorded yet.',
              style: ShellText.systemBarCaption.copyWith(
                color: ShellMediaColors.lightForegroundSecondary.withValues(
                  alpha: 0.65,
                ),
              ),
            )
          else ...[
            Text(
              data.title ?? 'Untitled session',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: ShellText.systemBarValue.copyWith(
                fontSize: 15,
                height: 1.2,
              ),
            ),
            const SizedBox(height: 14),
            Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  formatCost(data.cost),
                  style: ShellText.systemBarValue.copyWith(
                    fontSize: 28,
                    color: data.cost > 0
                        ? ShellTelemetryColors.nominal
                        : ShellMediaColors.lightForegroundSecondary.withValues(
                            alpha: 0.7,
                          ),
                  ),
                ),
                const SizedBox(width: 10),
                Padding(
                  padding: const EdgeInsets.only(bottom: 3),
                  child: Text(
                    '${formatTokens(data.totalTokens)} tokens',
                    style: ShellText.systemBarCaption.copyWith(
                      color: accent.captionColor(),
                    ),
                  ),
                ),
                const Spacer(),
                if (data.updatedAt != null)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 3),
                    child: Text(
                      'UPDATED ${_clock(data.updatedAt!)}',
                      style: ShellText.systemBarCaption.copyWith(
                        color: ShellMediaColors.lightForegroundSecondary
                            .withValues(alpha: 0.45),
                        fontSize: 9,
                        letterSpacing: 0.7,
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 16),
            Container(height: 1, color: accent.color.withValues(alpha: 0.08)),
            const SizedBox(height: 14),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                TricksterChip(
                  accent: accent,
                  label: 'INPUT',
                  value: formatTokens(data.input),
                ),
                TricksterChip(
                  accent: accent,
                  label: 'OUTPUT',
                  value: formatTokens(data.output),
                ),
                TricksterChip(
                  accent: accent,
                  label: 'REASONING',
                  value: formatTokens(data.reasoning),
                ),
                TricksterChip(
                  accent: accent,
                  label: 'CACHE READ',
                  value: formatTokens(data.cacheRead),
                ),
                TricksterChip(
                  accent: accent,
                  label: 'CACHE WRITE',
                  value: formatTokens(data.cacheWrite),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

class _BudgetsPanel extends StatelessWidget {
  const _BudgetsPanel({required this.accent, required this.budgets});

  final WallpaperAccent accent;
  final List<BudgetUsage> budgets;

  @override
  Widget build(BuildContext context) {
    return TricksterPanel(
      accent: accent,
      padding: const EdgeInsets.fromLTRB(18, 14, 18, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'BUDGETS',
            style: ShellText.systemBarCaption.copyWith(
              color: accent.captionColor(),
              letterSpacing: 1.1,
            ),
          ),
          for (final budget in budgets) ...[
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: Text(
                    budget.id,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: ShellText.systemBarCaption.copyWith(
                      color: ShellMediaColors.lightForegroundSecondary,
                    ),
                  ),
                ),
                Text(
                  '${formatCost(budget.spent)} / ${formatCost(budget.limit)}',
                  style: ShellText.systemBarValue.copyWith(fontSize: 12),
                ),
              ],
            ),
            const SizedBox(height: 7),
            ClipRRect(
              borderRadius: const BorderRadius.all(Radius.circular(999)),
              child: LinearProgressIndicator(
                value: budget.limit <= 0
                    ? 0
                    : (budget.spent / budget.limit).clamp(0.0, 1.0),
                minHeight: 5,
                backgroundColor: accent.color.withValues(alpha: 0.10),
                color: ShellTelemetryColors.nominal,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _TokenBreakdown extends StatelessWidget {
  const _TokenBreakdown({required this.accent, required this.session});

  final WallpaperAccent accent;
  final SessionUsage session;

  @override
  Widget build(BuildContext context) {
    final parts = [
      ('Input', session.input, accent.color),
      ('Output', session.output, ShellTelemetryColors.nominal),
      ('Reasoning', session.reasoning, ShellTelemetryColors.warning),
      ('Cache read', session.cacheRead, accent.captionColor()),
      ('Cache write', session.cacheWrite, ShellTelemetryColors.danger),
    ];
    return TricksterPanel(
      accent: accent,
      padding: const EdgeInsets.fromLTRB(18, 14, 18, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                'TOKEN BREAKDOWN',
                style: ShellText.systemBarCaption.copyWith(
                  color: accent.captionColor(),
                  letterSpacing: 1.1,
                ),
              ),
              const Spacer(),
              Text(
                '${formatTokens(session.totalTokens)} total',
                style: ShellText.systemBarCaption.copyWith(
                  color: ShellMediaColors.lightForegroundSecondary.withValues(
                    alpha: 0.55,
                  ),
                  fontSize: 10,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: const BorderRadius.all(Radius.circular(999)),
            child: SizedBox(
              height: 9,
              child: Row(
                children: [
                  for (final part in parts)
                    if (part.$2 > 0)
                      Expanded(
                        flex: part.$2,
                        child: SizedBox.expand(
                          child: ColoredBox(color: part.$3),
                        ),
                      ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 13),
          Wrap(
            spacing: 16,
            runSpacing: 8,
            children: [
              for (final part in parts)
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 6,
                      height: 6,
                      decoration: BoxDecoration(
                        color: part.$3,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      '${part.$1} ',
                      style: ShellText.systemBarCaption.copyWith(
                        color: ShellMediaColors.lightForegroundSecondary
                            .withValues(alpha: 0.7),
                        fontSize: 10,
                      ),
                    ),
                    Text(
                      formatTokens(part.$2),
                      style: ShellText.systemBarValue.copyWith(fontSize: 11),
                    ),
                  ],
                ),
            ],
          ),
        ],
      ),
    );
  }
}

class _Footer extends StatelessWidget {
  const _Footer({
    required this.accent,
    required this.snapshot,
    required this.onOpenConsole,
  });

  final WallpaperAccent accent;
  final UsageSnapshot snapshot;
  final VoidCallback? onOpenConsole;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Text(
          'Updated ${_clock(snapshot.fetchedAt)} · refreshes every 30 s',
          style: ShellText.systemBarCaption.copyWith(
            color: ShellMediaColors.lightForegroundSecondary.withValues(
              alpha: 0.45,
            ),
            fontSize: 10,
          ),
        ),
        const Spacer(),
        if (onOpenConsole != null)
          TricksterButton(
            accent: accent,
            icon: LucideIcons.externalLink,
            label: 'Console',
            onPressed: onOpenConsole,
          ),
      ],
    );
  }
}

class _ErrorNote extends StatelessWidget {
  const _ErrorNote({
    required this.accent,
    required this.message,
    required this.onRetry,
  });

  final WallpaperAccent accent;
  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(14, 10, 10, 10),
      decoration: BoxDecoration(
        color: ShellTelemetryColors.danger.withValues(alpha: 0.10),
        borderRadius: const BorderRadius.all(Radius.circular(16)),
        border: Border.all(
          color: ShellTelemetryColors.danger.withValues(alpha: 0.35),
        ),
      ),
      child: Row(
        children: [
          Icon(
            LucideIcons.triangleAlert,
            size: 16,
            color: ShellTelemetryColors.danger,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              message,
              style: ShellText.systemBarCaption.copyWith(
                color: ShellTelemetryColors.danger,
              ),
            ),
          ),
          const SizedBox(width: 8),
          TricksterButton(
            accent: accent,
            icon: LucideIcons.refreshCw,
            label: 'Retry',
            onPressed: onRetry,
          ),
        ],
      ),
    );
  }
}

class _Empty extends StatelessWidget {
  const _Empty({
    required this.accent,
    required this.error,
    required this.loading,
    required this.onRetry,
  });

  final WallpaperAccent accent;
  final String? error;
  final bool loading;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return TricksterEntrance(
      index: 1,
      child: TricksterPanel(
        accent: accent,
        padding: const EdgeInsets.fromLTRB(28, 34, 28, 30),
        child: Column(
          children: [
            if (loading && error == null)
              SizedBox.square(
                dimension: 28,
                child: CircularProgressIndicator(
                  strokeWidth: 2.5,
                  color: accent.color,
                ),
              )
            else
              Icon(
                LucideIcons.cloudOff,
                size: 38,
                color: accent.captionColor().withValues(alpha: 0.7),
              ),
            const SizedBox(height: 18),
            Text(
              loading && error == null
                  ? 'Reading OpenCode…'
                  : error ?? 'No OpenCode data yet.',
              textAlign: TextAlign.center,
              style: ShellText.systemBarCaption.copyWith(
                color: ShellMediaColors.lightForegroundSecondary,
                fontSize: 13,
                height: 1.5,
              ),
            ),
            const SizedBox(height: 20),
            TricksterButton(
              accent: accent,
              icon: LucideIcons.refreshCw,
              label: 'Retry',
              onPressed: onRetry,
            ),
          ],
        ),
      ),
    );
  }
}

String _clock(DateTime time) {
  final local = time.toLocal();
  String two(int value) => value.toString().padLeft(2, '0');
  return '${two(local.hour)}:${two(local.minute)}:${two(local.second)}';
}

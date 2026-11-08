import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:opencode_usage/src/api.dart';
import 'package:opencode_usage/src/dashboard.dart';
import 'package:opencode_usage/src/theme.dart';

UsageSnapshot _snapshot({SessionUsage? session}) {
  return UsageSnapshot(
    workspaceName: 'Default',
    usageUrl: 'https://opencode.ai/console/wrk_1',
    rolling: const MeterUsage(percent: 26),
    weekly: const MeterUsage(percent: 40),
    monthly: const MeterUsage(percent: 20, limited: true),
    budgets: const [BudgetUsage(id: 'budget_1', limit: 20, spent: 7.5)],
    session:
        session ??
        const SessionUsage(
          id: 'ses_1',
          title: 'Build the dashboard',
          cost: 0.25,
          input: 100,
          output: 20,
          reasoning: 5,
          cacheRead: 900,
          cacheWrite: 10,
          providerID: 'opencode-go',
          modelID: 'deepseek-v4.1',
        ),
    fetchedAt: DateTime(2026, 11, 7, 20, 45),
  );
}

Future<void> _pump(WidgetTester tester, UsageDashboard dashboard) async {
  await tester.binding.setSurfaceSize(const Size(900, 900));
  addTearDown(() => tester.binding.setSurfaceSize(null));
  await tester.pumpWidget(
    MaterialApp(
      theme: tricksterTheme(WallpaperAccent.fallback),
      home: Scaffold(body: dashboard),
    ),
  );
  await tester.pump();
}

void main() {
  testWidgets('the dashboard renders all three windows and the session', (
    tester,
  ) async {
    await _pump(
      tester,
      UsageDashboard(
        accent: WallpaperAccent.fallback,
        snapshot: _snapshot(),
        onRefresh: () {},
      ),
    );
    expect(find.text('Rolling'), findsOneWidget);
    expect(find.text('Weekly'), findsOneWidget);
    expect(find.text('Monthly'), findsOneWidget);
    expect(find.text('26%'), findsWidgets);
    expect(find.text('74% left'), findsOneWidget);
    expect(find.text('LIMIT'), findsOneWidget);
    expect(find.text('Build the dashboard'), findsOneWidget);
    expect(find.text('opencode-go/deepseek-v4.1'), findsOneWidget);
    expect(find.text('\$0.25'), findsOneWidget);
    expect(find.text('1.0k tokens'), findsOneWidget);
    expect(find.text('INPUT'), findsOneWidget);
    expect(find.text('CACHE READ'), findsOneWidget);
    expect(find.text('BUDGETS'), findsOneWidget);
  });

  testWidgets('refresh and console actions fire', (tester) async {
    var refreshed = 0;
    var console = 0;
    await _pump(
      tester,
      UsageDashboard(
        accent: WallpaperAccent.fallback,
        snapshot: _snapshot(),
        onRefresh: () => refreshed += 1,
        onOpenConsole: () => console += 1,
      ),
    );
    await tester.tap(find.byTooltip('Refresh'));
    await tester.pump();
    expect(refreshed, 1);
    await tester.ensureVisible(find.text('Console'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Console'));
    await tester.pump();
    expect(console, 1);
  });

  testWidgets('a stopped server shows the error with retry', (tester) async {
    var retries = 0;
    await _pump(
      tester,
      UsageDashboard(
        accent: WallpaperAccent.fallback,
        snapshot: null,
        error: 'OpenCode is not running.',
        onRefresh: () => retries += 1,
      ),
    );
    expect(find.text('OpenCode is not running.'), findsOneWidget);
    await tester.tap(find.text('Retry'));
    await tester.pump();
    expect(retries, 1);
  });

  testWidgets('a missing session states it plainly', (tester) async {
    await _pump(
      tester,
      UsageDashboard(
        accent: WallpaperAccent.fallback,
        snapshot: UsageSnapshot(
          workspaceName: 'Default',
          rolling: const MeterUsage(percent: 26),
          weekly: const MeterUsage(percent: 40),
          monthly: const MeterUsage(percent: 20),
          fetchedAt: DateTime(2026, 11, 7, 20, 45),
        ),
        onRefresh: () {},
      ),
    );
    expect(find.text('No session has been recorded yet.'), findsOneWidget);
    expect(find.text('BUDGETS'), findsNothing);
  });
}

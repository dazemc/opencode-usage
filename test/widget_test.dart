import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:opencode_usage/src/api.dart';
import 'package:opencode_usage/src/app.dart';

UsageSnapshot _snapshot() {
  return UsageSnapshot(
    workspaceName: 'Default',
    rolling: const MeterUsage(percent: 26),
    weekly: const MeterUsage(percent: 40),
    monthly: const MeterUsage(percent: 20),
    fetchedAt: DateTime(2026, 11, 7, 20, 45),
  );
}

void main() {
  testWidgets('the page renders an injected snapshot', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: OpenCodeUsagePage(
          fetch: () async => _snapshot(),
          autoRefresh: false,
        ),
      ),
    );
    await tester.pump();
    await tester.pump();
    expect(find.text('Rolling'), findsOneWidget);
    expect(find.text('74% left'), findsOneWidget);
  });

  testWidgets('the page renders a fetch failure', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: OpenCodeUsagePage(
          fetch: () async => throw const UsageException('OpenCode is offline.'),
          autoRefresh: false,
        ),
      ),
    );
    await tester.pump();
    await tester.pump();
    expect(find.text('OpenCode is offline.'), findsOneWidget);
    expect(find.text('Retry'), findsWidgets);
  });
}

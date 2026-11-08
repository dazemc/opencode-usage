import 'package:flutter_test/flutter_test.dart';
import 'package:opencode_usage/src/api.dart';

Map<String, Object?> _limits() {
  return {
    'data': {
      'workspace': {
        'id': 'wrk_1',
        'name': 'Default',
        'usageURL': 'https://opencode.ai/console/wrk_1/activity/overview',
      },
      'go': {
        'rolling': {'percent': 26, 'limited': false, 'resetsAt': 1794121576000},
        'weekly': {'percent': 40, 'limited': false, 'resetsAt': 1794182400000},
        'monthly': {'percent': 20, 'limited': true, 'resetsAt': 1794529208000},
      },
      'budgets': [
        {
          'id': 'budget_1',
          'limit': 20,
          'spent': 7.5,
          'resetsAt': 1794529208000,
        },
      ],
    },
  };
}

Map<String, Object?> _sessions() {
  return {
    'data': [
      {
        'id': 'ses_1',
        'title': 'Build the dashboard',
        'cost': 0.25,
        'model': {'providerID': 'opencode-go', 'modelID': 'deepseek-v4.1'},
        'tokens': {
          'input': 100,
          'output': 20,
          'reasoning': 5,
          'cache': {'read': 900, 'write': 10},
        },
        'time': {'created': 1794110000000, 'updated': 1794111000000},
      },
    ],
  };
}

void main() {
  test('usage limits parse every window, budget, and reset', () {
    final snapshot = parseUsageLimits(
      _limits(),
      now: DateTime.fromMillisecondsSinceEpoch(1794110000000),
    )!;
    expect(snapshot.workspaceName, 'Default');
    expect(snapshot.usageUrl, contains('wrk_1'));
    expect(snapshot.rolling.percent, 26);
    expect(snapshot.rolling.remaining, 74);
    expect(snapshot.weekly.percent, 40);
    expect(snapshot.monthly.percent, 20);
    expect(snapshot.monthly.limited, isTrue);
    expect(snapshot.budgets.single.limit, 20);
    expect(snapshot.budgets.single.spent, 7.5);
    expect(snapshot.budgets.single.remaining, 12.5);
    expect(snapshot.session, isNull);
  });

  test('an unsigned workspace yields no snapshot', () {
    expect(parseUsageLimits({'data': null}), isNull);
    expect(parseUsageLimits(null), isNull);
    expect(
      parseUsageLimits({
        'data': {
          'go': {
            'rolling': {'percent': 1},
          },
        },
      }),
      isNull,
    );
  });

  test('the newest session parses model and token totals', () {
    final session = parseSession(_sessions())!;
    expect(session.id, 'ses_1');
    expect(session.title, 'Build the dashboard');
    expect(session.cost, closeTo(0.25, 1e-9));
    expect(session.model, 'opencode-go/deepseek-v4.1');
    expect(session.totalTokens, 1035);
    expect(session.input, 100);
    expect(session.output, 20);
    expect(session.reasoning, 5);
    expect(session.cacheRead, 900);
    expect(session.cacheWrite, 10);
    expect(parseSession({'data': []}), isNull);
  });

  test('state discovery follows XDG_STATE_HOME', () {
    expect(
      opencodeServiceStatePath(
        environment: {'XDG_STATE_HOME': '/state', 'HOME': '/home/me'},
      ),
      '/state/opencode/service.json',
    );
    expect(
      opencodeServiceStatePath(environment: {'HOME': '/home/me'}),
      '/home/me/.local/state/opencode/service.json',
    );
  });

  test('tokens compact past a thousand', () {
    expect(formatTokens(999), '999');
    expect(formatTokens(1000), '1.0k');
    expect(formatTokens(12345), '12.3k');
    expect(formatTokens(123456), '123k');
    expect(formatTokens(1234567), '1.2M');
  });

  test('costs keep sub-cent precision', () {
    expect(formatCost(0), '\$0.00');
    expect(formatCost(0.25), '\$0.25');
    expect(formatCost(0.1234), '\$0.12');
    expect(formatCost(0.0123), '\$0.012');
    expect(formatCost(0.002686), '\$0.0027');
    expect(formatCost(12.5), '\$12.50');
  });

  test('reset times read today, tomorrow, then a date', () {
    final now = DateTime(2026, 11, 7, 20, 0);
    expect(formatReset(DateTime(2026, 11, 7, 21, 46), now: now), 'today 21:46');
    expect(
      formatReset(DateTime(2026, 11, 8, 0, 0), now: now),
      'tomorrow 00:00',
    );
    expect(formatReset(DateTime(2026, 11, 12, 9, 5), now: now), 'Nov 12 09:05');
    expect(formatReset(null), 'no reset time');
  });
}

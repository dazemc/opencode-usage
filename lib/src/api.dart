import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data' show BytesBuilder;

/// One OpenCode Go allowance window.
class MeterUsage {
  const MeterUsage({
    required this.percent,
    this.limited = false,
    this.resetsAt,
  });

  /// Percent of the window's allowance already used (0–100).
  final double percent;

  /// Whether OpenCode Go refuses requests until [resetsAt].
  final bool limited;

  /// When the window refills.
  final DateTime? resetsAt;

  /// Percent of the window's allowance left.
  double get remaining => (100 - percent).clamp(0, 100).toDouble();
}

/// A Console spending budget attached to the signed-in workspace.
class BudgetUsage {
  const BudgetUsage({
    required this.id,
    required this.limit,
    required this.spent,
    this.resetsAt,
  });

  final String id;
  final double limit;
  final double spent;
  final DateTime? resetsAt;

  double get remaining => (limit - spent).clamp(0, limit).toDouble();
}

/// Token and cost totals for one OpenCode session.
class SessionUsage {
  const SessionUsage({
    required this.id,
    this.title,
    this.cost = 0,
    this.input = 0,
    this.output = 0,
    this.reasoning = 0,
    this.cacheRead = 0,
    this.cacheWrite = 0,
    this.providerID,
    this.modelID,
    this.updatedAt,
  });

  final String id;
  final String? title;
  final double cost;
  final int input;
  final int output;
  final int reasoning;
  final int cacheRead;
  final int cacheWrite;
  final String? providerID;
  final String? modelID;
  final DateTime? updatedAt;

  int get totalTokens => input + output + reasoning + cacheRead + cacheWrite;

  String? get model {
    if (providerID != null && modelID != null) {
      return '$providerID/$modelID';
    }
    return modelID;
  }
}

/// The dashboard's data: the three Go allowance windows, any Console budgets,
/// and the newest session.
class UsageSnapshot {
  const UsageSnapshot({
    required this.workspaceName,
    required this.rolling,
    required this.weekly,
    required this.monthly,
    required this.fetchedAt,
    this.usageUrl,
    this.budgets = const <BudgetUsage>[],
    this.session,
  });

  final String? workspaceName;
  final String? usageUrl;
  final MeterUsage rolling;
  final MeterUsage weekly;
  final MeterUsage monthly;
  final List<BudgetUsage> budgets;
  final SessionUsage? session;
  final DateTime fetchedAt;

  UsageSnapshot withSession(SessionUsage? session) {
    return UsageSnapshot(
      workspaceName: workspaceName,
      usageUrl: usageUrl,
      rolling: rolling,
      weekly: weekly,
      monthly: monthly,
      budgets: budgets,
      session: session,
      fetchedAt: fetchedAt,
    );
  }
}

/// A user-facing failure: the server is stopped, the workspace is signed out,
/// or OpenCode answered something unusable.
class UsageException implements Exception {
  const UsageException(this.message);

  final String message;

  @override
  String toString() => message;
}

/// The running OpenCode server's state document. It carries the loopback URL
/// and the Basic-auth password; the config document of the same name does not
/// carry the port.
String opencodeServiceStatePath({Map<String, String>? environment}) {
  final env = environment ?? Platform.environment;
  final state = env['XDG_STATE_HOME'];
  final base = state == null || state.isEmpty
      ? '${env['HOME'] ?? ''}/.local/state'
      : state;
  return '$base/opencode/service.json';
}

Map<String, dynamic>? _map(Object? value) {
  if (value is Map<String, dynamic>) {
    return value;
  }
  if (value is Map) {
    return Map<String, dynamic>.from(value);
  }
  return null;
}

DateTime? _time(Object? value) =>
    value is num ? DateTime.fromMillisecondsSinceEpoch(value.toInt()) : null;

MeterUsage? _meter(Object? value) {
  final map = _map(value);
  if (map == null) {
    return null;
  }
  final percent = map['percent'];
  if (percent is! num) {
    return null;
  }
  return MeterUsage(
    percent: percent.toDouble().clamp(0, 100).toDouble(),
    limited: map['limited'] == true,
    resetsAt: _time(map['resetsAt']),
  );
}

/// Decodes `/api/experimental/usage/limits`. Null means the workspace is not
/// signed in or the response carried no complete Go allowance.
UsageSnapshot? parseUsageLimits(Object? json, {DateTime? now}) {
  final data = _map(_map(json)?['data']);
  if (data == null) {
    return null;
  }
  final go = _map(data['go']);
  final rolling = _meter(go?['rolling']);
  final weekly = _meter(go?['weekly']);
  final monthly = _meter(go?['monthly']);
  if (rolling == null || weekly == null || monthly == null) {
    return null;
  }
  final workspace = _map(data['workspace']);
  final budgets = <BudgetUsage>[];
  final rawBudgets = data['budgets'];
  if (rawBudgets is List) {
    for (final entry in rawBudgets) {
      final map = _map(entry);
      if (map == null) {
        continue;
      }
      final id = map['id'];
      final limit = map['limit'];
      final spent = map['spent'];
      if (id is String && limit is num && spent is num) {
        budgets.add(
          BudgetUsage(
            id: id,
            limit: limit.toDouble(),
            spent: spent.toDouble(),
            resetsAt: _time(map['resetsAt']),
          ),
        );
      }
    }
  }
  return UsageSnapshot(
    workspaceName: workspace?['name'] is String
        ? workspace!['name'] as String
        : null,
    usageUrl: workspace?['usageURL'] is String
        ? workspace!['usageURL'] as String
        : null,
    rolling: rolling,
    weekly: weekly,
    monthly: monthly,
    budgets: List<BudgetUsage>.unmodifiable(budgets),
    fetchedAt: now ?? DateTime.now(),
  );
}

/// Decodes the newest session from `/api/session?limit=1&order=desc`.
SessionUsage? parseSession(Object? json) {
  final data = _map(json)?['data'];
  if (data is! List || data.isEmpty) {
    return null;
  }
  final session = _map(data.first);
  if (session == null) {
    return null;
  }
  final id = session['id'];
  if (id is! String || id.isEmpty) {
    return null;
  }
  final tokens = _map(session['tokens']);
  final cache = _map(tokens?['cache']);
  final model = _map(session['model']);
  int count(Object? value) => value is num ? value.toInt() : 0;
  final title = session['title'];
  final cost = session['cost'];
  final time = _map(session['time']);
  return SessionUsage(
    id: id,
    title: title is String && title.isNotEmpty ? title : null,
    cost: cost is num ? cost.toDouble() : 0,
    input: count(tokens?['input']),
    output: count(tokens?['output']),
    reasoning: count(tokens?['reasoning']),
    cacheRead: count(cache?['read']),
    cacheWrite: count(cache?['write']),
    providerID: model?['providerID'] is String
        ? model!['providerID'] as String
        : null,
    modelID: model?['modelID'] is String ? model!['modelID'] as String : null,
    updatedAt: _time(time?['updated']),
  );
}

class _ServiceState {
  const _ServiceState({required this.url, required this.password});

  final Uri url;
  final String password;
}

/// Reads the signed-in workspace's allowance from the local OpenCode server.
class UsageRepository {
  UsageRepository({
    String? statePath,
    HttpClient Function()? clientFactory,
    this.timeout = const Duration(seconds: 6),
  }) : _statePath = statePath ?? opencodeServiceStatePath(),
       _clientFactory = clientFactory ?? HttpClient.new;

  final String _statePath;
  final HttpClient Function() _clientFactory;
  final Duration timeout;
  HttpClient? _client;

  Future<UsageSnapshot> fetch() async {
    if (!File(_statePath).existsSync()) {
      throw UsageException(
        'OpenCode is not running.\n'
        'Expected its service state at $_statePath.\n'
        'Start OpenCode, then refresh.',
      );
    }
    final state = _readState();
    if (state == null) {
      throw UsageException(
        'OpenCode’s service state could not be read at $_statePath.\n'
        'Restart OpenCode, then refresh.',
      );
    }
    final client = _client ??= _clientFactory()
      ..connectionTimeout = timeout
      ..idleTimeout = const Duration(seconds: 30);
    try {
      final limits = await _getJson(
        client,
        state.url.replace(path: '/api/experimental/usage/limits'),
        state.password,
      );
      final snapshot = parseUsageLimits(limits);
      if (snapshot == null) {
        throw const UsageException(
          'No OpenCode Go workspace is signed in.\n'
          'Sign in to OpenCode Go and refresh.',
        );
      }
      SessionUsage? session;
      try {
        final sessions = await _getJson(
          client,
          state.url.replace(
            path: '/api/session',
            queryParameters: const {'limit': '1', 'order': 'desc'},
          ),
          state.password,
        );
        session = parseSession(sessions);
      } on Object {
        // Session totals are secondary; the allowance still renders.
      }
      return snapshot.withSession(session);
    } on UsageException {
      rethrow;
    } on Object catch (error) {
      throw UsageException(
        'Could not reach the OpenCode server at ${state.url}.\n$error',
      );
    }
  }

  void dispose() {
    _client?.close(force: true);
    _client = null;
  }

  _ServiceState? _readState() {
    try {
      final decoded = jsonDecode(File(_statePath).readAsStringSync());
      if (decoded is! Map) {
        return null;
      }
      final url = decoded['url'];
      final password = decoded['password'];
      if (url is! String || password is! String || password.isEmpty) {
        return null;
      }
      final parsed = Uri.tryParse(url);
      if (parsed == null || !parsed.hasScheme || parsed.host.isEmpty) {
        return null;
      }
      final local = parsed.host == '0.0.0.0' || parsed.host == '::'
          ? parsed.replace(host: '127.0.0.1')
          : parsed;
      return _ServiceState(url: local, password: password);
    } on Object {
      return null;
    }
  }

  Future<Object?> _getJson(HttpClient client, Uri uri, String password) async {
    final request = await client.getUrl(uri).timeout(timeout);
    request.headers.set(
      HttpHeaders.authorizationHeader,
      'Basic ${base64.encode(utf8.encode('opencode:$password'))}',
    );
    request.headers.set(HttpHeaders.acceptHeader, 'application/json');
    final response = await request.close().timeout(timeout);
    if (response.statusCode != HttpStatus.ok) {
      await response.drain<void>().timeout(timeout);
      throw UsageException('OpenCode answered HTTP ${response.statusCode}.');
    }
    final body = BytesBuilder(copy: false);
    await for (final chunk in response.timeout(timeout)) {
      if (body.length + chunk.length > 1 << 20) {
        throw const UsageException('OpenCode returned an oversized response.');
      }
      body.add(chunk);
    }
    return jsonDecode(utf8.decode(body.takeBytes(), allowMalformed: true));
  }
}

/// Compact token counts: `999`, `1.2k`, `3.4M`.
String formatTokens(int tokens) {
  if (tokens < 1000) {
    return '$tokens';
  }
  if (tokens < 1000000) {
    final thousands = tokens / 1000;
    return '${thousands >= 100 ? thousands.round() : thousands.toStringAsFixed(1)}k';
  }
  return '${(tokens / 1000000).toStringAsFixed(1)}M';
}

/// USD costs keep enough decimals to show sub-cent turns.
String formatCost(double cost) {
  if (cost == 0) {
    return '\$0.00';
  }
  if (cost >= 0.1) {
    return '\$${cost.toStringAsFixed(2)}';
  }
  if (cost >= 0.01) {
    return '\$${cost.toStringAsFixed(3)}';
  }
  return '\$${cost.toStringAsFixed(4)}';
}

/// Local reset time: `today 21:46`, `tomorrow 00:00`, or `Nov 12 00:00`.
String formatReset(DateTime? reset, {DateTime? now}) {
  if (reset == null) {
    return 'no reset time';
  }
  final local = reset.toLocal();
  final current = (now ?? DateTime.now()).toLocal();
  final time =
      '${local.hour.toString().padLeft(2, '0')}:'
      '${local.minute.toString().padLeft(2, '0')}';
  final today = DateTime(current.year, current.month, current.day);
  final day = DateTime(local.year, local.month, local.day);
  final difference = day.difference(today).inDays;
  if (difference == 0) {
    return 'today $time';
  }
  if (difference == 1) {
    return 'tomorrow $time';
  }
  const months = [
    'Jan',
    'Feb',
    'Mar',
    'Apr',
    'May',
    'Jun',
    'Jul',
    'Aug',
    'Sep',
    'Oct',
    'Nov',
    'Dec',
  ];
  final month = months[local.month - 1];
  return '$month ${local.day} $time';
}

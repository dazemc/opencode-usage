import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';

import 'api.dart';
import 'dashboard.dart';
import 'theme.dart';

class OpenCodeUsageApp extends StatelessWidget {
  const OpenCodeUsageApp({this.accent = WallpaperAccent.fallback, super.key});

  final WallpaperAccent accent;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'OpenCode Usage',
      debugShowCheckedModeBanner: false,
      theme: tricksterTheme(accent),
      home: OpenCodeUsagePage(accent: accent),
    );
  }
}

/// Polls the local OpenCode server and renders the allowance dashboard.
class OpenCodeUsagePage extends StatefulWidget {
  const OpenCodeUsagePage({
    this.accent = WallpaperAccent.fallback,
    this.fetch,
    this.autoRefresh = true,
    this.refreshInterval = const Duration(seconds: 30),
    super.key,
  });

  final WallpaperAccent accent;

  /// Test seam: overrides the repository read.
  final Future<UsageSnapshot> Function()? fetch;
  final bool autoRefresh;
  final Duration refreshInterval;

  @override
  State<OpenCodeUsagePage> createState() => _OpenCodeUsagePageState();
}

class _OpenCodeUsagePageState extends State<OpenCodeUsagePage> {
  final _repository = UsageRepository();
  Timer? _timer;
  UsageSnapshot? _snapshot;
  String? _error;
  var _loading = true;
  var _reading = false;

  @override
  void initState() {
    super.initState();
    unawaited(_load());
    if (widget.autoRefresh) {
      _timer = Timer.periodic(
        widget.refreshInterval,
        (_) => unawaited(_load(background: true)),
      );
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    _repository.dispose();
    super.dispose();
  }

  Future<void> _load({bool background = false}) async {
    if (_reading) {
      return;
    }
    _reading = true;
    if (!background && mounted) {
      setState(() => _loading = true);
    }
    try {
      final snapshot = await (widget.fetch ?? _repository.fetch)();
      if (!mounted) {
        return;
      }
      setState(() {
        _snapshot = snapshot;
        _error = null;
      });
    } on UsageException catch (error) {
      if (!mounted) {
        return;
      }
      setState(() => _error = error.message);
    } on Object catch (error) {
      if (!mounted) {
        return;
      }
      setState(() => _error = 'Could not read OpenCode usage: $error');
    } finally {
      _reading = false;
      if (mounted) {
        setState(() => _loading = false);
      }
    }
  }

  Future<void> _openConsole() async {
    final url = _snapshot?.usageUrl;
    if (url == null || url.isEmpty) {
      return;
    }
    try {
      await Process.start('xdg-open', [url], mode: ProcessStartMode.detached);
    } on Object {
      // No browser handler: the dashboard itself is still usable.
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: UsageDashboard(
        accent: widget.accent,
        snapshot: _snapshot,
        error: _error,
        loading: _loading,
        onRefresh: () => unawaited(_load()),
        onOpenConsole: _snapshot?.usageUrl == null
            ? null
            : () => unawaited(_openConsole()),
      ),
    );
  }
}

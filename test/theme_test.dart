import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:opencode_usage/src/theme.dart';

void main() {
  test('the accent follows Trickster settings.json', () {
    final directory = Directory.systemTemp.createTempSync('oc-usage-theme-');
    addTearDown(() => directory.delete(recursive: true));
    File('${directory.path}/trickster/settings.json')
      ..createSync(recursive: true)
      ..writeAsStringSync('{"revision": 1, "accent": "#ff876f"}');
    final accent = loadTricksterAccent(
      environment: {'XDG_CONFIG_HOME': directory.path},
    );
    expect(accent.color.toARGB32(), 0xffff876f);
    expect(accent.isResolved, isTrue);
  });

  test('a missing or malformed document falls back to the brand accent', () {
    final directory = Directory.systemTemp.createTempSync('oc-usage-theme-');
    addTearDown(() => directory.delete(recursive: true));
    expect(
      loadTricksterAccent(environment: {'XDG_CONFIG_HOME': directory.path}),
      WallpaperAccent.fallback,
    );
    File('${directory.path}/trickster/settings.json')
      ..createSync(recursive: true)
      ..writeAsStringSync('{"accent": "red"}');
    expect(
      loadTricksterAccent(environment: {'XDG_CONFIG_HOME': directory.path}),
      WallpaperAccent.fallback,
    );
  });
}

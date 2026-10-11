import 'dart:io';

import 'package:fixpk/app/fixpk_app.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

/// Developer rendering utility; does not run in the ordinary test suite.
/// FIXPK_FLUTTER_SDK must point to the pinned SDK containing material_fonts.
void main() {
  testWidgets('render foundation phone previews', (tester) async {
    final sdk = Platform.environment['FIXPK_FLUTTER_SDK'];
    if (sdk == null) {
      throw StateError('Set FIXPK_FLUTTER_SDK to your Flutter SDK.');
    }
    final bytes = File(
      '$sdk/bin/cache/artifacts/material_fonts/Roboto-Regular.ttf',
    ).readAsBytesSync();
    final font = FontLoader('Roboto')
      ..addFont(Future.value(ByteData.sublistView(bytes)));
    await font.load();
    final iconBytes = File(
      '$sdk/bin/cache/artifacts/material_fonts/MaterialIcons-Regular.otf',
    ).readAsBytesSync();
    final icons = FontLoader('MaterialIcons')
      ..addFont(Future.value(ByteData.sublistView(iconBytes)));
    await icons.load();
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(
      const ProviderScope(
        child: RepaintBoundary(key: ValueKey('preview'), child: FixPkApp()),
      ),
    );
    await tester.pumpAndSettle();
    await expectLater(
      find.byKey(const ValueKey('preview')),
      matchesGoldenFile('../docs/previews/home.png'),
    );
    await tester.tap(find.byType(NavigationDestination).at(1));
    await tester.pumpAndSettle();
    await expectLater(
      find.byKey(const ValueKey('preview')),
      matchesGoldenFile('../docs/previews/services.png'),
    );
    expect(tester.takeException(), isNull);
  });
}

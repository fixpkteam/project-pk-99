import 'dart:io';

import 'package:fixpk/app/fixpk_app.dart';
import 'package:fixpk/app/providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../test/helpers/memory_preferences.dart';

/// Optional visual inspection utility. Outputs are ignored build artifacts.
void main() {
  testWidgets('render first-launch screens', (tester) async {
    final sdk = Platform.environment['FIXPK_FLUTTER_SDK'];
    if (sdk == null) throw StateError('Set FIXPK_FLUTTER_SDK.');
    for (final (family, filename) in [
      ('Roboto', 'Roboto-Regular.ttf'),
      ('MaterialIcons', 'MaterialIcons-Regular.otf'),
    ]) {
      final bytes = File(
        '$sdk/bin/cache/artifacts/material_fonts/$filename',
      ).readAsBytesSync();
      await (FontLoader(
        family,
      )..addFont(Future.value(ByteData.sublistView(bytes)))).load();
    }
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(
      ProviderScope(
        overrides: [preferencesProvider.overrideWithValue(MemoryPreferences())],
        child: const RepaintBoundary(
          key: ValueKey('onboarding-preview'),
          child: FixPkApp(),
        ),
      ),
    );
    await tester.pumpAndSettle();
    for (final name in [
      'welcome',
      'introduction-services',
      'introduction-projects',
      'signup',
    ]) {
      // Image decoding uses real asynchronous work. Waiting only for frames
      // in the widget-test clock can capture an empty asset placeholder.
      final imageProviders = tester
          .widgetList<Image>(find.byType(Image))
          .map((widget) => widget.image)
          .toList();
      final context = tester.element(find.byType(FixPkApp));
      await tester.runAsync(
        () => Future.wait(
          imageProviders.map((provider) => precacheImage(provider, context)),
        ),
      );
      await tester.pump();
      await expectLater(
        find.byKey(const ValueKey('onboarding-preview')),
        matchesGoldenFile('../build/verification/$name.png'),
      );
      if (name != 'signup') {
        await tester.tap(find.byKey(const ValueKey('onboarding-next')));
        await tester.pumpAndSettle();
      }
    }
    expect(tester.takeException(), isNull);
  });
}

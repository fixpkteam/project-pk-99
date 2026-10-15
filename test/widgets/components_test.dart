import 'package:fixpk/core/theme/app_theme.dart';
import 'package:fixpk/core/widgets/components.dart';
import 'package:fixpk/features/foundation/presentation/component_gallery.dart';
import 'package:fixpk/features/services/presentation/services_pages.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('busy button suppresses duplicate actions', (tester) async {
    var taps = 0;
    await tester.pumpWidget(
      MaterialApp(
        theme: FixPkTheme.light,
        home: Scaffold(
          body: AppButton(label: 'Submit', busy: true, onPressed: () => taps++),
        ),
      ),
    );
    await tester.tap(find.byType(FilledButton));
    expect(taps, 0);
  });
  testWidgets('service card handles long text at 200 percent scaling', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(320, 640);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(
      MaterialApp(
        theme: FixPkTheme.light,
        home: MediaQuery(
          data: const MediaQueryData(textScaler: TextScaler.linear(2)),
          child: Scaffold(
            body: SingleChildScrollView(
              child: ServiceCard(
                title: 'Construction & Renovation',
                subtitle: 'Residential, commercial and industrial project requirements',
                icon: Icons.construction,
                onTap: () {},
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pump();
    expect(tester.takeException(), isNull);
  });
  testWidgets('gallery validates required input without submission', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(theme: FixPkTheme.light, home: const ComponentGallery()),
    );
    final validateButton = find
        .widgetWithText(FilledButton, 'Validate example')
        .hitTestable();
    await tester.scrollUntilVisible(
      validateButton,
      400,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.tap(validateButton);
    await tester.pump();
    expect(find.text('Enter your name.'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
  testWidgets('empty service search can be cleared', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        child: MaterialApp(
          theme: FixPkTheme.light,
          home: const Scaffold(body: ServicesPage()),
        ),
      ),
    );
    await tester.enterText(find.byType(TextField), 'not-a-service');
    await tester.pump();
    expect(find.text('No matching services'), findsOneWidget);
    await tester.tap(find.widgetWithText(FilledButton, 'Clear filters'));
    await tester.pump();
    expect(find.text('Solar Solutions'), findsOneWidget);
  });
}

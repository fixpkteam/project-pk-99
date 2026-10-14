import 'package:fixpk/app/app_router.dart';
import 'package:fixpk/app/providers.dart';
import 'package:fixpk/core/theme/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets(
    'Digital shortcut clears a retained service filter and opens all five services',
    (tester) async {
      final router = createRouter(initialLocation: '/services');
      addTearDown(router.dispose);
      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp.router(
            theme: FixPkTheme.light,
            routerConfig: router,
          ),
        ),
      );
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(TextField), 'Solar');
      await tester.tap(find.text('Residential'));
      await tester.pumpAndSettle();
      router.go('/home');
      await tester.pumpAndSettle();
      await tester.scrollUntilVisible(
        find.text('Digital Services'),
        300,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.tap(find.text('Digital Services'));
      await tester.pumpAndSettle();
      expect(find.text('Website Design & Development'), findsOneWidget);
      expect(find.text('App Development'), findsOneWidget);
      await tester.scrollUntilVisible(
        find.text('Influencer Marketing'),
        200,
        scrollable: find
            .byWidgetPredicate(
              (w) => w is Scrollable && w.axisDirection == AxisDirection.down,
            )
            .last,
      );
      expect(find.text('Influencer Marketing'), findsOneWidget);
      expect(tester.takeException(), isNull);
      await tester.tap(find.byTooltip('Back'));
      await tester.pumpAndSettle();
      expect(router.routeInformationProvider.value.uri.toString(), '/services');
      expect(find.text('Solar Solutions'), findsOneWidget);
    },
  );
  for (final route in ['/home', '/services', '/sign-in', '/sign-up']) {
    testWidgets('$route fits a 320px phone at 200% text scale', (tester) async {
      tester.view.physicalSize = const Size(320, 640);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final router = createRouter(initialLocation: route);
      addTearDown(router.dispose);
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            authUserProvider.overrideWith((ref) => Stream.value(null)),
          ],
          child: MaterialApp.router(
            theme: FixPkTheme.light,
            routerConfig: router,
            builder: (context, child) => MediaQuery(
              data: MediaQuery.of(
                context,
              ).copyWith(textScaler: const TextScaler.linear(2)),
              child: child!,
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      final scrollable = find.byWidgetPredicate(
        (w) => w is Scrollable && w.axisDirection == AxisDirection.down,
      );
      await tester.drag(scrollable.last, const Offset(0, -500));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
    });
  }
}

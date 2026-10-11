import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/theme/app_theme.dart';
import '../core/widgets/components.dart';
import 'app_router.dart';
import 'providers.dart';

class FixPkApp extends ConsumerWidget {
  const FixPkApp({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final startup = ref.watch(bootstrapProvider);
    return startup.when(
      data: (_) => MaterialApp.router(
        title: 'FixPK',
        debugShowCheckedModeBanner: false,
        theme: FixPkTheme.light,
        routerConfig: ref.watch(routerProvider),
      ),
      loading: () => MaterialApp(
        debugShowCheckedModeBanner: false,
        theme: FixPkTheme.light,
        home: const Scaffold(
          body: SafeArea(
            child: Center(
              child: CircularProgressIndicator(
                semanticsLabel: 'Starting FixPK',
              ),
            ),
          ),
        ),
      ),
      error: (error, stack) => MaterialApp(
        debugShowCheckedModeBanner: false,
        theme: FixPkTheme.light,
        home: Scaffold(
          body: SafeArea(
            child: SingleChildScrollView(
              child: AppStatePanel(
                title: 'FixPK could not start',
                message: 'This build is not ready to connect. Try again or use the development preview configuration.',
                icon: Icons.cloud_off_outlined,
                isError: true,
                actionLabel: 'Retry',
                onAction: () {
                  ref.invalidate(configProvider);
                  ref.invalidate(bootstrapProvider);
                },
              ),
            ),
          ),
        ),
      ),
    );
  }
}

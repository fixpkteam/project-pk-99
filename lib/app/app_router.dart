import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../core/widgets/components.dart';
import '../features/foundation/presentation/component_gallery.dart';
import '../features/foundation/presentation/foundation_pages.dart';

final routerProvider = Provider<GoRouter>((ref) {
  final router = createRouter();
  ref.onDispose(router.dispose);
  return router;
});

GoRouter createRouter({String initialLocation = '/home'}) => GoRouter(
  initialLocation: initialLocation,
  routes: [
    GoRoute(path: '/', redirect: (context, state) => '/home'),
    StatefulShellRoute.indexedStack(
      builder: (context, state, shell) => AppShell(shell: shell),
      branches: [
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: '/home',
              builder: (context, state) => const HomePage(),
            ),
          ],
        ),
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: '/services',
              builder: (context, state) => const ServicesPage(),
            ),
          ],
        ),
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: '/requests',
              builder: (context, state) => const PlannedPage(
                title: 'Your service journey',
                message: 'Requests, quotations and work updates will appear here when those features are connected.',
                icon: Icons.assignment_outlined,
              ),
            ),
          ],
        ),
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: '/projects',
              builder: (context, state) => const PlannedPage(
                title: 'Projects by FixPK',
                message: 'The project portfolio will be added with verified details and approved photography.',
                icon: Icons.apartment_outlined,
              ),
            ),
          ],
        ),
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: '/account',
              builder: (context, state) => const AccountPage(),
            ),
          ],
        ),
      ],
    ),
    GoRoute(
      path: '/components',
      builder: (context, state) => const ComponentGallery(),
    ),
  ],
  errorBuilder: (context, state) => Scaffold(
    appBar: AppBar(title: const Text('Page unavailable')),
    body: SafeArea(
      child: SingleChildScrollView(
        child: AppStatePanel(
          title: 'This page is unavailable',
          message: 'Return home to continue exploring FixPK.',
          actionLabel: 'Go home',
          onAction: () => context.go('/home'),
        ),
      ),
    ),
  ),
);

class AppShell extends StatelessWidget {
  const AppShell({super.key, required this.shell});
  final StatefulNavigationShell shell;
  static const titles = [
    'FixPK',
    'Services',
    'My Requests',
    'Projects',
    'Account',
  ];

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      // Plain app title until the approved logo master is supplied.
      title: Text(titles[shell.currentIndex]),
      actions: [
        IconButton(
          tooltip: 'Open design components',
          icon: const Icon(Icons.palette_outlined),
          onPressed: () => context.push('/components'),
        ),
      ],
    ),
    body: SafeArea(top: false, child: shell),
    bottomNavigationBar: NavigationBar(
      selectedIndex: shell.currentIndex,
      onDestinationSelected: (index) =>
          shell.goBranch(index, initialLocation: index == shell.currentIndex),
      destinations: const [
        NavigationDestination(
          icon: Icon(Icons.home_outlined),
          selectedIcon: Icon(Icons.home),
          label: 'Home',
        ),
        NavigationDestination(
          icon: Icon(Icons.grid_view_outlined),
          selectedIcon: Icon(Icons.grid_view_rounded),
          label: 'Services',
        ),
        NavigationDestination(
          icon: Icon(Icons.assignment_outlined),
          selectedIcon: Icon(Icons.assignment),
          label: 'Requests',
        ),
        NavigationDestination(
          icon: Icon(Icons.apartment_outlined),
          selectedIcon: Icon(Icons.apartment),
          label: 'Projects',
        ),
        NavigationDestination(
          icon: Icon(Icons.person_outline),
          selectedIcon: Icon(Icons.person),
          label: 'Account',
        ),
      ],
    ),
  );
}

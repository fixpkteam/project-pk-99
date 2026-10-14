import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'providers.dart';
import '../features/auth/presentation/reset_password_page.dart';
import '../features/onboarding/presentation/onboarding_page.dart';

import '../core/widgets/components.dart';
import '../features/admin/presentation/request_management_pages.dart';
import '../features/foundation/presentation/component_gallery.dart';
import '../features/foundation/presentation/home_page.dart' show HomePage;
import '../features/auth/presentation/auth_page.dart'
    show AccountPage, AuthPage;
import '../features/admin/presentation/admin_pages.dart'
    show AdminConsolePage, AdminContentPage, AdminUsersPage;
import '../features/services/presentation/services_pages.dart'
    show ServiceDetailPage, ServicesPage;
import '../features/catalogue/presentation/catalogue_pages.dart'
    show ProductDetailPage, ProductsPage, ProjectDetailPage, ProjectsPage;
import '../features/care/presentation/care_pages.dart'
    show
        FaqPage,
        LegalPage,
        NotificationsPage,
        PreferencesPage,
        ReviewComposerPage,
        ReviewsPage,
        StaffOperationsPage,
        SupportPage;
import '../features/requests/data/request_repository.dart';
import '../features/requests/presentation/addresses_page.dart';
import '../features/requests/presentation/request_pages.dart';
import '../features/requests/presentation/request_wizard_page.dart';
import '../features/requests/presentation/pending_requests_page.dart';

final routerProvider = Provider<GoRouter>((ref) {
  final router = createRouter(
    initialLocation: ref.read(startupRouteProvider).requireValue,
  );
  ref.listen(authEventsProvider, (before, after) {
    if (after.value?.event == AuthChangeEvent.passwordRecovery) {
      router.go('/reset-password');
    }
  });
  ref.onDispose(router.dispose);
  return router;
});

GoRouter createRouter({String initialLocation = '/home'}) => GoRouter(
  initialLocation: initialLocation,
  routes: [
    GoRoute(path: '/', redirect: (context, state) => '/home'),
    GoRoute(
      path: '/welcome',
      builder: (context, state) => const OnboardingPage(),
    ),
    GoRoute(
      path: '/reset-password',
      builder: (context, state) => const ResetPasswordPage(),
    ),
    GoRoute(
      path: '/sign-in',
      builder: (context, state) =>
          AuthPage(redirectTo: state.uri.queryParameters['redirect']),
    ),
    GoRoute(
      path: '/sign-up',
      builder: (context, state) => AuthPage(
        createAccount: true,
        redirectTo: state.uri.queryParameters['redirect'],
      ),
    ),
    GoRoute(
      path: '/requests/new',
      builder: (context, state) => RequestWizardPage(
        serviceId: state.uri.queryParameters['serviceId'] ?? '',
        enquiryContext: state.uri.queryParameters['context'],
      ),
    ),
    GoRoute(
      path: '/requests/pending',
      builder: (context, state) => const PendingRequestsPage(),
    ),
    GoRoute(
      path: '/requests/:requestId',
      builder: (context, state) =>
          RequestDetailPage(requestId: state.pathParameters['requestId']!),
    ),
    GoRoute(
      path: '/products',
      builder: (context, state) =>
          ProductsPage(enquiryContext: state.uri.queryParameters['enquiry']),
    ),
    GoRoute(
      path: '/products/:productId',
      builder: (context, state) => ProductDetailPage(
        productId: state.pathParameters['productId']!,
        enquiryContext: state.extra is String ? state.extra! as String : null,
      ),
    ),
    GoRoute(
      path: '/projects/:projectId',
      builder: (context, state) =>
          ProjectDetailPage(projectId: state.pathParameters['projectId']!),
    ),
    GoRoute(
      path: '/account/addresses',
      builder: (context, state) => const AddressesPage(),
    ),
    GoRoute(
      path: '/account/addresses/edit',
      builder: (context, state) => AddressEditorPage(
        address: state.extra is CustomerAddress
            ? state.extra! as CustomerAddress
            : null,
      ),
    ),
    GoRoute(
      path: '/account/notifications',
      builder: (context, state) => const NotificationsPage(),
    ),
    GoRoute(
      path: '/account/support',
      builder: (context, state) => const SupportPage(),
    ),
    GoRoute(path: '/account/faq', builder: (context, state) => const FaqPage()),
    GoRoute(
      path: '/account/preferences',
      builder: (context, state) => const PreferencesPage(),
    ),
    GoRoute(
      path: '/account/reviews',
      builder: (context, state) => const ReviewsPage(),
    ),
    GoRoute(
      path: '/account/reviews/new/:jobId',
      builder: (context, state) =>
          ReviewComposerPage(jobId: state.pathParameters['jobId']!),
    ),
    GoRoute(
      path: '/account/legal',
      builder: (context, state) => const LegalPage(),
    ),
    GoRoute(
      path: '/admin',
      builder: (context, state) => const AdminConsolePage(),
    ),
    GoRoute(
      path: '/admin/users',
      builder: (context, state) => const AdminUsersPage(),
    ),
    GoRoute(
      path: '/admin/table/:tableKey',
      builder: (context, state) =>
          AdminContentPage(tableKey: state.pathParameters['tableKey']!),
    ),
    GoRoute(
      path: '/staff/requests',
      builder: (context, state) => const StaffRequestsPage(),
    ),
    GoRoute(
      path: '/staff/requests/:requestId',
      builder: (context, state) =>
          StaffRequestDetailPage(requestId: state.pathParameters['requestId']!),
    ),
    GoRoute(
      path: '/staff',
      builder: (context, state) => const StaffOperationsPage(),
    ),
    GoRoute(
      path: '/services/:serviceId',
      builder: (context, state) => ServiceDetailPage(
        serviceId: state.pathParameters['serviceId']!,
        enquiryContext: state.uri.queryParameters['enquiry'],
      ),
    ),
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
              builder: (context, state) => ServicesPage(
                enquiryContext: state.uri.queryParameters['enquiry'],
                initialCategory: state.uri.queryParameters['category'],
                focusSearch: state.uri.queryParameters['search'] == '1',
              ),
            ),
          ],
        ),
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: '/requests',
              builder: (context, state) => const RequestsPage(),
            ),
          ],
        ),
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: '/projects',
              builder: (context, state) => const ProjectsPage(),
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
    appBar: shell.currentIndex == 0
        ? null
        : AppBar(
            title: Text(titles[shell.currentIndex]),
            centerTitle: true,
            leading: shell.currentIndex == 1
                ? IconButton(
                    tooltip: 'Back',
                    onPressed: () {
                      if (GoRouterState.of(
                        context,
                      ).uri.queryParameters.containsKey('category')) {
                        context.go('/services');
                      } else {
                        shell.goBranch(0);
                      }
                    },
                    icon: const Icon(Icons.arrow_back_ios_new_rounded),
                  )
                : null,
          ),
    body: SafeArea(top: shell.currentIndex == 0, child: shell),
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

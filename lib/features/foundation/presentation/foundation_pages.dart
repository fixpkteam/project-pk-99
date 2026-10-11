import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/components.dart';

const foundationServices = <({String title, String subtitle, IconData icon})>[
  (
    title: 'Solar Solutions',
    subtitle: 'Residential, commercial and industrial',
    icon: Icons.solar_power_outlined,
  ),
  (
    title: 'Solar Geysers',
    subtitle: 'Hot-water products and installation',
    icon: Icons.water_drop_outlined,
  ),
  (
    title: 'CCTV & Security',
    subtitle: 'Surveillance and access control',
    icon: Icons.videocam_outlined,
  ),
  (
    title: 'HVAC',
    subtitle: 'Cooling, heating and maintenance',
    icon: Icons.ac_unit,
  ),
  (
    title: 'Electrical',
    subtitle: 'Wiring, installation and repairs',
    icon: Icons.bolt_outlined,
  ),
  (
    title: 'Facility Maintenance',
    subtitle: 'Care for homes and business sites',
    icon: Icons.handyman_outlined,
  ),
  (
    title: 'Printing Solutions',
    subtitle: 'Signage, branding and print',
    icon: Icons.print_outlined,
  ),
  (
    title: 'Aluminium & Glass',
    subtitle: 'Installation, repair and replacement',
    icon: Icons.window_outlined,
  ),
  (
    title: 'UPVC',
    subtitle: 'Windows, doors and maintenance',
    icon: Icons.door_front_door_outlined,
  ),
  (
    title: 'Construction & Renovation',
    subtitle: 'Property improvement and projects',
    icon: Icons.construction,
  ),
];

class PageBody extends StatelessWidget {
  const PageBody({super.key, required this.children, this.storageKey});
  final List<Widget> children;
  final String? storageKey;
  @override
  Widget build(BuildContext context) => Align(
    alignment: Alignment.topCenter,
    child: ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 720),
      child: ListView(
        key: storageKey == null ? null : PageStorageKey<String>(storageKey!),
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
        children: children,
      ),
    ),
  );
}

class HomePage extends StatelessWidget {
  const HomePage({super.key});
  @override
  Widget build(BuildContext context) => PageBody(
    storageKey: 'home',
    children: [
      const StatusChip(label: 'Foundation preview', tone: StatusTone.neutral),
      const SizedBox(height: 24),
      Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: FixPkColors.navy,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Engineering Solutions.\nBuilt to Last.',
              style: Theme.of(context).textTheme.displaySmall
                  ?.copyWith(color: Colors.white),
            ),
            const SizedBox(height: 12),
            const Text(
              'Your home. Your business. Our expertise.',
              style: TextStyle(color: Colors.white, height: 1.5),
            ),
            const SizedBox(height: 24),
            AppButton(
              label: 'Explore services',
              onPressed: () => context.go('/services'),
            ),
          ],
        ),
      ),
      const SizedBox(height: 24),
      Text(
        'One place for your next project',
        style: Theme.of(context).textTheme.titleLarge,
      ),
      const SizedBox(height: 8),
      const Text(
        'Explore the FixPK navigation and design foundation. Service requests and account features arrive in the following phases.',
      ),
      const SizedBox(height: 20),
      for (final service in foundationServices.take(3)) ...[
        ServiceCard(
          title: service.title,
          subtitle: service.subtitle,
          icon: service.icon,
          onTap: () => context.go('/services'),
        ),
        const SizedBox(height: 12),
      ],
      const SizedBox(height: 12),
      ContentCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Design system',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 8),
            const Text('Try the buttons, forms, cards and feedback states.'),
            const SizedBox(height: 16),
            AppButton(
              label: 'Open component gallery',
              kind: ActionKind.outline,
              onPressed: () => context.push('/components'),
            ),
          ],
        ),
      ),
    ],
  );
}

class ServicesPage extends StatefulWidget {
  const ServicesPage({super.key});
  @override
  State<ServicesPage> createState() => _ServicesPageState();
}

class _ServicesPageState extends State<ServicesPage> {
  final _search = TextEditingController();
  String _query = '';
  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final matches = foundationServices
        .where(
          (service) => '${service.title} ${service.subtitle}'
              .toLowerCase()
              .contains(_query.toLowerCase()),
        )
        .toList();
    return PageBody(
      storageKey: 'services',
      children: [
        const Text(
          'Service categories',
          style: TextStyle(fontSize: 22, fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 8),
        const Text(
          'Navigation preview · catalogue connection is planned for Phase 3.',
        ),
        const SizedBox(height: 20),
        AppSearchField(
          controller: _search,
          onChanged: (value) => setState(() => _query = value),
        ),
        const SizedBox(height: 20),
        if (matches.isEmpty)
          AppStatePanel(
            title: 'No matching services',
            message: 'Try another name or clear your search.',
            actionLabel: 'Clear search',
            onAction: () => setState(() {
              _query = '';
              _search.clear();
            }),
          ),
        for (final service in matches) ...[
          ServiceCard(
            title: service.title,
            subtitle: service.subtitle,
            icon: service.icon,
            onTap: () => showModalBottomSheet<void>(
              context: context,
              isScrollControlled: true,
              useSafeArea: true,
              builder: (context) => SingleChildScrollView(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: AppStatePanel(
                    title: service.title,
                    message: 'Detailed service information and requests will be available in a later phase.',
                    actionLabel: 'Close',
                    onAction: () => Navigator.pop(context),
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 12),
        ],
      ],
    );
  }
}

class PlannedPage extends StatelessWidget {
  const PlannedPage({
    super.key,
    required this.title,
    required this.message,
    required this.icon,
  });
  final String title;
  final String message;
  final IconData icon;
  @override
  Widget build(BuildContext context) => PageBody(
    children: [
      AppStatePanel(
        title: title,
        message: message,
        icon: icon,
        actionLabel: 'Explore services',
        onAction: () => context.go('/services'),
      ),
    ],
  );
}

class AccountPage extends StatelessWidget {
  const AccountPage({super.key});
  @override
  Widget build(BuildContext context) => PageBody(
    children: [
      Text(
        'Welcome to FixPK',
        style: Theme.of(context).textTheme.headlineSmall,
      ),
      const SizedBox(height: 8),
      const Text(
        'You are exploring the Phase 1 foundation. Sign-in and profile management are planned for Phase 2.',
      ),
      const SizedBox(height: 24),
      ServiceCard(
        title: 'Component gallery',
        subtitle: 'Explore the reusable design system',
        icon: Icons.palette_outlined,
        onTap: () => context.push('/components'),
      ),
      const SizedBox(height: 12),
      const ContentCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('FixPK', style: TextStyle(fontWeight: FontWeight.w700)),
            SizedBox(height: 8),
            Text(
              'Engineering, maintenance, installation, product and project solutions.',
            ),
          ],
        ),
      ),
    ],
  );
}

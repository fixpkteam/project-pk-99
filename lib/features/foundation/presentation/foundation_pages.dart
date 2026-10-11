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
      const StatusChip(label: 'Engineering and technical solutions'),
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
        'Browse services for homes, businesses and industrial properties. Sign in to manage your FixPK account.',
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
      const SizedBox(height: 8),
      ContentCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Products and projects',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 8),
            const Text('Explore FixPK solutions and selected completed work.'),
            const SizedBox(height: 16),
            Wrap(
              spacing: 12,
              runSpacing: 8,
              children: [
                OutlinedButton.icon(
                  onPressed: () => context.push('/products'),
                  icon: const Icon(Icons.inventory_2_outlined),
                  label: const Text('Browse products'),
                ),
                OutlinedButton.icon(
                  onPressed: () => context.go('/projects'),
                  icon: const Icon(Icons.apartment_outlined),
                  label: const Text('View projects'),
                ),
              ],
            ),
          ],
        ),
      ),
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

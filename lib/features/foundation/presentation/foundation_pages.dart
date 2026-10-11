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

  static const _iconColors = [
    Color(0xFFE8F3FF),
    Color(0xFFFFF4E5),
    Color(0xFFEAF8F1),
    Color(0xFFF1EDFF),
    Color(0xFFFFF0F0),
    Color(0xFFE9F8FA),
    Color(0xFFFFF6E8),
    Color(0xFFEEF1F5),
  ];

  @override
  Widget build(BuildContext context) => SafeArea(
    child: Align(
      alignment: Alignment.topCenter,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 720),
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 28),
          children: [
            Row(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Image.asset(
                    'assets/brand/fixpk-app-icon.png',
                    width: 42,
                    height: 42,
                    fit: BoxFit.cover,
                    semanticLabel: 'FixPK',
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'FixPK',
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          color: FixPkColors.navy,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      InkWell(
                        onTap: () {},
                        child: const Row(
                          children: [
                            Icon(
                              Icons.location_on_outlined,
                              size: 14,
                              color: FixPkColors.action,
                            ),
                            SizedBox(width: 3),
                            Text(
                              'Islamabad, Pakistan',
                              style: TextStyle(
                                fontSize: 12,
                                color: FixPkColors.body,
                              ),
                            ),
                            Icon(
                              Icons.keyboard_arrow_down,
                              size: 16,
                              color: FixPkColors.body,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  tooltip: 'Notifications',
                  onPressed: () => context.push('/account/notifications'),
                  icon: const Icon(
                    Icons.notifications_none_rounded,
                    color: FixPkColors.navy,
                  ),
                ),
                InkWell(
                  onTap: () => context.go('/account'),
                  borderRadius: BorderRadius.circular(24),
                  child: const CircleAvatar(
                    radius: 19,
                    backgroundColor: FixPkColors.informationSurface,
                    child: Icon(
                      Icons.person_outline,
                      color: FixPkColors.action,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Container(
              height: 205,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(20),
                image: const DecorationImage(
                  image: AssetImage('assets/images/home-hero.jpg'),
                  fit: BoxFit.cover,
                ),
              ),
              clipBehavior: Clip.antiAlias,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  const DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.centerLeft,
                        end: Alignment.centerRight,
                        colors: [
                          Color(0xE600263E),
                          Color(0x7700263E),
                          Color(0x1200263E),
                        ],
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Text(
                          'ENGINEERING • INSTALLATION • CARE',
                          style: TextStyle(
                            color: Colors.white70,
                            fontSize: 10,
                            letterSpacing: 1,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 10),
                        Text(
                          'Powering better\nliving, every day.',
                          style: Theme.of(context).textTheme.headlineSmall
                              ?.copyWith(
                                color: Colors.white,
                                fontWeight: FontWeight.w800,
                                height: 1.12,
                              ),
                        ),
                        const SizedBox(height: 8),
                        const Text(
                          'Reliable solutions for your home and business.',
                          style: TextStyle(color: Colors.white, fontSize: 12),
                        ),
                        const SizedBox(height: 14),
                        SizedBox(
                          height: 38,
                          child: FilledButton(
                            onPressed: () => context.go('/services'),
                            style: FilledButton.styleFrom(
                              backgroundColor: FixPkColors.blue,
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                              ),
                            ),
                            child: const Text('Explore services'),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 18),
            TextField(
              readOnly: true,
              onTap: () => context.go('/services'),
              decoration: InputDecoration(
                hintText: 'What do you need help with?',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: const Icon(Icons.tune_rounded),
                filled: true,
                fillColor: const Color(0xFFF6F8FA),
                contentPadding: const EdgeInsets.symmetric(vertical: 12),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  child: Text(
                    'Our services',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                ),
                TextButton(
                  onPressed: () => context.go('/services'),
                  child: const Text('See all'),
                ),
              ],
            ),
            const SizedBox(height: 8),
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: 8,
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 4,
                childAspectRatio: .82,
                crossAxisSpacing: 8,
                mainAxisSpacing: 8,
              ),
              itemBuilder: (context, index) {
                final item = foundationServices[index];
                return InkWell(
                  onTap: () => context.go('/services'),
                  borderRadius: BorderRadius.circular(14),
                  child: Column(
                    children: [
                      Container(
                        width: 54,
                        height: 54,
                        decoration: BoxDecoration(
                          color: _iconColors[index],
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Icon(
                          item.icon,
                          color: FixPkColors.navy,
                          size: 25,
                        ),
                      ),
                      const SizedBox(height: 7),
                      Text(
                        item.title,
                        textAlign: TextAlign.center,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 10.5,
                          height: 1.2,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
            const SizedBox(height: 20),
            Container(
              height: 142,
              clipBehavior: Clip.antiAlias,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(18),
                color: FixPkColors.navy,
              ),
              child: Stack(
                fit: StackFit.expand,
                children: [
                  Image.asset(
                    'assets/images/solar-panels.jpg',
                    fit: BoxFit.cover,
                    alignment: Alignment.centerRight,
                  ),
                  const DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.centerLeft,
                        end: Alignment.centerRight,
                        colors: [
                          FixPkColors.navy,
                          Color(0xE600263E),
                          Color(0x1100263E),
                        ],
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(18),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Text(
                          'SOLAR SURVEY',
                          style: TextStyle(
                            color: Colors.white70,
                            fontSize: 10,
                            letterSpacing: 1,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 5),
                        const Text(
                          'Make the switch to solar',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 17,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 10),
                        SizedBox(
                          height: 34,
                          child: OutlinedButton(
                            onPressed: () => context.go(
                              '/services?enquiry=Free%20solar%20site%20survey',
                            ),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: Colors.white,
                              side: const BorderSide(color: Colors.white),
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                              ),
                            ),
                            child: const Text('Book a free survey'),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  child: Text(
                    'Explore FixPK',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: _ExploreTile(
                    icon: Icons.inventory_2_outlined,
                    label: 'Products',
                    onTap: () => context.push('/products'),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _ExploreTile(
                    icon: Icons.apartment_outlined,
                    label: 'Our projects',
                    onTap: () => context.go('/projects'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    ),
  );
}

class _ExploreTile extends StatelessWidget {
  const _ExploreTile({
    required this.icon,
    required this.label,
    required this.onTap,
  });
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  @override
  Widget build(BuildContext context) => InkWell(
    onTap: onTap,
    borderRadius: BorderRadius.circular(14),
    child: Container(
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: const Color(0xFFF5F8FB),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          Icon(icon, color: FixPkColors.action),
          const SizedBox(width: 9),
          Expanded(
            child: Text(
              label,
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
          ),
          const Icon(Icons.chevron_right, size: 18),
        ],
      ),
    ),
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

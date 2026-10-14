import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/providers.dart';
import '../../../core/theme/app_theme.dart';
import '../../services/presentation/service_visuals.dart';
import 'home_campaigns.dart';

class HomePage extends ConsumerWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(authUserProvider).value;
    final city = '${user?.userMetadata?['city'] ?? ''}'.trim();
    final preview = ref.watch(configProvider).preview;
    final shortcuts = serviceVisuals
        .where((item) => item.key != 'printing')
        .toList();
    return SafeArea(
      child: Align(
        alignment: Alignment.topCenter,
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 720),
          child: CustomScrollView(
            key: const PageStorageKey('home'),
            slivers: [
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(16, 4, 16, 0),
                sliver: SliverToBoxAdapter(
                  child: Column(
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: InkWell(
                              onTap: () => context.push('/account/addresses'),
                              borderRadius: BorderRadius.circular(12),
                              child: Padding(
                                padding: const EdgeInsets.symmetric(
                                  vertical: 14,
                                ),
                                child: Row(
                                  children: [
                                    const Icon(
                                      Icons.location_on_outlined,
                                      size: 27,
                                      color: FixPkColors.navy,
                                    ),
                                    const SizedBox(width: 7),
                                    Flexible(
                                      child: Text(
                                        city.isNotEmpty
                                            ? city
                                            : preview
                                            ? 'Islamabad'
                                            : 'Your location',
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: Theme.of(context)
                                            .textTheme
                                            .titleMedium
                                            ?.copyWith(color: FixPkColors.navy),
                                      ),
                                    ),
                                    const SizedBox(width: 4),
                                    const Icon(
                                      Icons.keyboard_arrow_down_rounded,
                                      color: FixPkColors.navy,
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                          IconButton(
                            tooltip: 'Notifications',
                            onPressed: () =>
                                context.push('/account/notifications'),
                            icon: const Icon(
                              Icons.notifications_none_rounded,
                              size: 27,
                              color: FixPkColors.navy,
                            ),
                          ),
                          IconButton(
                            tooltip: 'Your account',
                            onPressed: () => context.go('/account'),
                            icon: const CircleAvatar(
                              radius: 19,
                              backgroundColor: FixPkColors.informationSurface,
                              child: Icon(
                                Icons.person_outline_rounded,
                                color: FixPkColors.navy,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      const _HouseBanner(),
                      const SizedBox(height: 16),
                      TextField(
                        readOnly: true,
                        onTap: () => context.go('/services?search=1'),
                        decoration: InputDecoration(
                          hintText: 'Search services…',
                          prefixIcon: const Icon(
                            Icons.search_rounded,
                            color: FixPkColors.muted,
                          ),
                          filled: true,
                          fillColor: FixPkColors.surface,
                          contentPadding: const EdgeInsets.symmetric(
                            vertical: 14,
                          ),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(30),
                            borderSide: BorderSide.none,
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(30),
                            borderSide: BorderSide.none,
                          ),
                        ),
                      ),
                      const SizedBox(height: 18),
                    ],
                  ),
                ),
              ),
              SliverLayoutBuilder(
                builder: (context, constraints) {
                  final scale = MediaQuery.textScalerOf(context).scale(13) / 13;
                  final columns =
                      constraints.crossAxisExtent < 350 || scale > 1.4 ? 3 : 4;
                  return SliverPadding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    sliver: SliverGrid.builder(
                      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: columns,
                        mainAxisExtent: 70 + 36 * scale,
                        crossAxisSpacing: 10,
                        mainAxisSpacing: 8,
                      ),
                      itemCount: shortcuts.length + 1,
                      itemBuilder: (context, index) {
                        final item = index < shortcuts.length
                            ? shortcuts[index]
                            : null;
                        return InkWell(
                          key: ValueKey('home-service-${item?.key ?? 'all'}'),
                          onTap: () => context.go(
                            item == null
                                ? '/services'
                                : '/services?category=${item.key}',
                          ),
                          borderRadius: BorderRadius.circular(16),
                          child: Column(
                            children: [
                              if (item != null)
                                ServiceArtwork(name: item.key, size: 66)
                              else
                                Container(
                                  width: 66,
                                  height: 66,
                                  decoration: BoxDecoration(
                                    color: FixPkColors.surface,
                                    borderRadius: BorderRadius.circular(16),
                                  ),
                                  child: const Icon(
                                    Icons.more_horiz_rounded,
                                    color: FixPkColors.blue,
                                    size: 38,
                                  ),
                                ),
                              const SizedBox(height: 7),
                              Text(
                                item?.shortTitle ?? 'View All',
                                textAlign: TextAlign.center,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  fontSize: 12,
                                  height: 1.2,
                                  fontWeight: FontWeight.w600,
                                  color: FixPkColors.navy,
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                  );
                },
              ),
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(16, 14, 16, 28),
                sliver: SliverToBoxAdapter(
                  child: Column(
                    children: [
                      const _HouseBanner(survey: true),
                      const SizedBox(height: 12),
                      const HomeCampaigns(),
                      Wrap(
                        spacing: 8,
                        runSpacing: 4,
                        children: [
                          TextButton.icon(
                            onPressed: () => context.push('/products'),
                            icon: const Icon(
                              Icons.shopping_bag_outlined,
                              size: 19,
                            ),
                            label: const Text('Products'),
                          ),
                          TextButton.icon(
                            onPressed: () => context.go('/projects'),
                            icon: const Icon(
                              Icons.business_center_outlined,
                              size: 19,
                            ),
                            label: const Text('Our projects'),
                          ),
                          TextButton.icon(
                            onPressed: () => context.push('/account/support'),
                            icon: const Icon(Icons.support_agent, size: 19),
                            label: const Text('Support'),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _HouseBanner extends StatelessWidget {
  const _HouseBanner({this.survey = false});
  final bool survey;
  @override
  Widget build(BuildContext context) => ClipRRect(
    borderRadius: BorderRadius.circular(20),
    child: Stack(
      children: [
        Positioned.fill(
          child: Image.asset(
            'assets/images/engineering-home.webp',
            fit: BoxFit.cover,
            alignment: Alignment.centerRight,
            cacheWidth:
                (MediaQuery.sizeOf(context).width *
                        MediaQuery.devicePixelRatioOf(context))
                    .ceil()
                    .clamp(1, 1400),
          ),
        ),
        const Positioned.fill(
          child: DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Color(0xB8001E37),
                  Color(0x33001E37),
                  Color(0x00001E37),
                ],
                stops: [0, .65, 1],
              ),
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.all(18),
          child: SizedBox(
            width: double.infinity,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (!survey) ...[
                  const Text(
                    'Engineering\nSolutions.',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 27,
                      fontWeight: FontWeight.w800,
                      height: 1.05,
                    ),
                  ),
                  const SizedBox(height: 3),
                  const Text(
                    'Built to Last.',
                    style: TextStyle(
                      color: Color(0xFF36BEF4),
                      fontSize: 27,
                      fontWeight: FontWeight.w800,
                      height: 1.05,
                    ),
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    'Residential  |  Commercial  |  Industrial',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 11.5,
                      height: 1.4,
                    ),
                  ),
                ] else ...[
                  const Text(
                    'Plan your project\nwith Solar Solutions',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 21,
                      height: 1.13,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 10),
                  FilledButton.icon(
                    onPressed: () => context.go(
                      '/services?category=solar&enquiry=Solar%20site%20survey',
                    ),
                    style: FilledButton.styleFrom(
                      backgroundColor: Colors.white,
                      foregroundColor: FixPkColors.action,
                      shape: const StadiumBorder(),
                      minimumSize: const Size(48, 44),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 18,
                        vertical: 8,
                      ),
                    ),
                    label: const Text('Book a survey'),
                    icon: const Icon(Icons.arrow_forward_rounded, size: 20),
                  ),
                ],
              ],
            ),
          ),
        ),
      ],
    ),
  );
}

import 'package:flutter/material.dart';

import '../../../core/theme/app_theme.dart';

class ServiceVisual {
  const ServiceVisual(
    this.key,
    this.title,
    this.shortTitle,
    this.subtitle, {
    this.audiences = const ['residential', 'commercial', 'industrial'],
  });
  final String key;
  final String title;
  final String shortTitle;
  final String subtitle;
  final List<String> audiences;
}

const serviceVisuals = [
  ServiceVisual(
    'solar',
    'Solar Solutions',
    'Solar',
    'Residential, commercial & industrial',
  ),
  ServiceVisual(
    'solar-geyser',
    'Solar Geysers',
    'Solar Geysers',
    'Solar hot water & installation',
    audiences: ['residential', 'commercial'],
  ),
  ServiceVisual(
    'security',
    'CCTV & Security',
    'CCTV & Security',
    'Surveillance & access control',
  ),
  ServiceVisual('hvac', 'HVAC', 'HVAC', 'AC installation & maintenance'),
  ServiceVisual(
    'electrical',
    'Electrical Services',
    'Electrical',
    'Wiring, repairs & installations',
  ),
  ServiceVisual(
    'maintenance',
    'Facility Maintenance',
    'Maintenance',
    'Preventive & corrective care',
  ),
  ServiceVisual(
    'plumbing',
    'Plumbing',
    'Plumbing',
    'Water systems, leaks & repairs',
    audiences: ['residential', 'commercial'],
  ),
  ServiceVisual(
    'aluminium',
    'Aluminium & Glass',
    'Aluminium',
    'Doors, windows & glass solutions',
    audiences: ['residential', 'commercial'],
  ),
  ServiceVisual(
    'upvc',
    'UPVC',
    'UPVC',
    'Windows, doors & installation',
    audiences: ['residential', 'commercial'],
  ),
  ServiceVisual(
    'construction',
    'Construction & Renovation',
    'Construction',
    'Build, renovate & remodel',
  ),
  ServiceVisual(
    'printing',
    'Printing Solutions',
    'Printing',
    'Signage, branding & design',
    audiences: ['commercial', 'industrial'],
  ),
  ServiceVisual(
    'digital',
    'Digital Services',
    'Digital Services',
    'Websites, apps & digital marketing',
    audiences: ['commercial', 'industrial'],
  ),
];

String serviceVisualKey(String value) {
  final text = value.toLowerCase();
  if (text.contains('geyser')) return 'solar-geyser';
  if (text.contains('solar')) return 'solar';
  if (text.contains('security') || text.contains('cctv')) return 'security';
  if (text.contains('hvac') || text.contains('air condition')) return 'hvac';
  if (text.contains('electr')) return 'electrical';
  if (text.contains('plumb')) return 'plumbing';
  if (text.contains('aluminium') || text.contains('glass')) return 'aluminium';
  if (text.contains('upvc')) return 'upvc';
  if (text.contains('construction') || text.contains('renovation')) {
    return 'construction';
  }
  if (text.contains('print')) return 'printing';
  if ([
    'digital',
    'website',
    'app development',
    'social media',
    'promotion',
    'influencer',
  ].any(text.contains)) {
    return 'digital';
  }
  return 'maintenance';
}

class ServiceArtwork extends StatelessWidget {
  const ServiceArtwork({super.key, required this.name, this.size = 64});
  final String name;
  final double size;
  @override
  Widget build(BuildContext context) => ExcludeSemantics(
    child: ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: Image.asset(
        'assets/service-icons/${serviceVisualKey(name)}.webp',
        width: size,
        height: size,
        fit: BoxFit.cover,
        cacheWidth: (size * MediaQuery.devicePixelRatioOf(context))
            .ceil()
            .clamp(1, 256),
        filterQuality: FilterQuality.medium,
      ),
    ),
  );
}

class ServiceRow extends StatelessWidget {
  const ServiceRow({
    super.key,
    required this.title,
    required this.subtitle,
    required this.artwork,
    required this.onTap,
  });
  final String title;
  final String subtitle;
  final String artwork;
  final VoidCallback onTap;
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 10),
    child: DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        boxShadow: const [
          BoxShadow(
            color: Color(0x070D3761),
            blurRadius: 16,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                ServiceArtwork(name: artwork),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: Theme.of(context).textTheme.titleMedium
                            ?.copyWith(fontWeight: FontWeight.w700),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        subtitle,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.bodyMedium
                            ?.copyWith(color: FixPkColors.muted, height: 1.3),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 4),
                const Icon(
                  Icons.chevron_right_rounded,
                  color: FixPkColors.muted,
                ),
              ],
            ),
          ),
        ),
      ),
    ),
  );
}

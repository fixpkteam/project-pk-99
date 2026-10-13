import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/providers.dart';
import '../../../core/widgets/components.dart';

class HomeCampaign {
  const HomeCampaign(this.row);
  final Map<String, dynamic> row;
  String get title => '${row['title'] ?? ''}';
  String get body => '${row['body'] ?? ''}';
  String? get imageUrl {
    final uri = Uri.tryParse('${row['image_path'] ?? ''}');
    return uri?.scheme == 'https' && uri!.host.isNotEmpty
        ? uri.toString()
        : null;
  }

  String? get destination {
    final path = '${row['target_path'] ?? ''}';
    return path.startsWith('/') &&
            !path.startsWith('//') &&
            !path.contains('\\')
        ? path
        : null;
  }

  bool isActive(DateTime now) {
    final start = DateTime.tryParse('${row['starts_at'] ?? ''}');
    final end = DateTime.tryParse('${row['ends_at'] ?? ''}');
    return (start == null || !start.isAfter(now)) &&
        (end == null || end.isAfter(now));
  }
}

final homeCampaignsProvider = StreamProvider.autoDispose<List<HomeCampaign>>((
  ref,
) {
  if (ref.watch(configProvider).preview) return Stream.value([]);
  final client = ref.watch(supabaseClientProvider);
  return ref
      .watch(readCacheProvider)
      .watch(
        'public.banners',
        () => client
            .from('banners')
            .select('title,body,image_path,target_path,starts_at,ends_at')
            .eq('is_published', true)
            .order('sort_order')
            .order('id')
            .limit(100),
        (data) => (data as List)
            .cast<Map<String, dynamic>>()
            .map(HomeCampaign.new)
            .toList(),
      );
});

class HomeCampaigns extends ConsumerWidget {
  const HomeCampaigns({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final campaigns = ref.watch(homeCampaignsProvider).value ?? [];
    final active = campaigns
        .where((item) => item.isActive(DateTime.now()))
        .take(5);
    // Optional campaigns never block the main service navigation.
    return Column(
      children: [
        for (final item in active)
          Padding(
            padding: const EdgeInsets.only(top: 16),
            child: ContentCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  if (item.imageUrl != null) ...[
                    ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: Image.network(
                        item.imageUrl!,
                        height: 150,
                        fit: BoxFit.cover,
                        cacheWidth: 900,
                        errorBuilder: (_, _, _) => const SizedBox.shrink(),
                      ),
                    ),
                    const SizedBox(height: 12),
                  ],
                  if (item.title.isNotEmpty)
                    Text(
                      item.title,
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                  if (item.body.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(top: 6),
                      child: Text(item.body),
                    ),
                  if (item.destination != null)
                    Align(
                      alignment: Alignment.centerLeft,
                      child: TextButton(
                        onPressed: () => context.push(item.destination!),
                        child: const Text('Learn more'),
                      ),
                    ),
                ],
              ),
            ),
          ),
      ],
    );
  }
}

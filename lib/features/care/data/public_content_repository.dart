import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/providers.dart';

class LegalContent {
  const LegalContent({
    required this.key,
    required this.title,
    required this.text,
  });
  final String key, title, text;
  factory LegalContent.fromRow(Map<String, dynamic> row) {
    final body = row['body'];
    return LegalContent(
      key: '${row['content_key'] ?? ''}',
      title: '${row['title'] ?? 'FixPK policy'}',
      text: body is Map ? '${body['text'] ?? ''}' : '',
    );
  }
}

final legalContentProvider = StreamProvider.autoDispose<List<LegalContent>>((
  ref,
) {
  if (ref.watch(configProvider).preview) return Stream.value([]);
  final client = ref.watch(supabaseClientProvider);
  return ref
      .watch(readCacheProvider)
      .watch(
        'public.legal',
        () => client
            .from('app_content')
            .select('content_key,title,body')
            .eq('is_published', true)
            .inFilter('content_key', ['privacy_policy', 'service_terms'])
            .order('content_key'),
        (data) => (data as List)
            .cast<Map<String, dynamic>>()
            .map(LegalContent.fromRow)
            .where((item) => item.text.trim().isNotEmpty)
            .toList(),
      );
});

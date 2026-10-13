import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/providers.dart';
import 'request_outbox.dart';
import 'request_repository.dart';

final requestOutboxProvider = Provider<RequestOutbox>((ref) {
  final client = ref.watch(supabaseClientProvider);
  final repository = ref.watch(requestRepositoryProvider);
  final outbox = RequestOutbox(
    store: ref.watch(durableStoreProvider),
    currentUserId: () => client.auth.currentUser?.id,
    send: repository.sendQueuedRequest,
    onSent: (owner) => ref.invalidate(customerRequestsProvider(owner)),
  );
  ref.onDispose(outbox.dispose);
  return outbox;
});

final pendingRequestsProvider = StreamProvider.autoDispose
    .family<List<QueuedRequest>, String>(
      (ref, owner) => ref.watch(requestOutboxProvider).watch(owner),
    );

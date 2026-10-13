import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/providers.dart';
import '../../../core/widgets/components.dart';
import '../data/outbox_providers.dart';
import '../data/request_outbox.dart';

class PendingRequestsPage extends ConsumerStatefulWidget {
  const PendingRequestsPage({super.key});
  @override
  ConsumerState<PendingRequestsPage> createState() =>
      _PendingRequestsPageState();
}

class _PendingRequestsPageState extends ConsumerState<PendingRequestsPage> {
  bool _busy = false;
  Future<void> _retry() async {
    setState(() => _busy = true);
    try {
      await ref.read(requestOutboxProvider).sync(force: true);
    } on Object {
      if (mounted) {
        _message(
          'Could not read saved requests. Check device storage and try again.',
        );
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  void _message(String message) =>
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(message)));

  Future<void> _remove(QueuedRequest row) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Remove saved copy?'),
        content: const Text(
          'This stops retries and removes the saved files from this device. If sending already started, the team may have received the request. Check My Requests or contact support to cancel it.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Keep'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Remove copy'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    setState(() => _busy = true);
    try {
      await ref.read(requestOutboxProvider).removeLocal(row.ownerId, row.id);
    } on Object {
      if (mounted) _message('Could not remove the saved copy. Try again.');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final owner = ref.watch(authUserProvider).value?.id;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Saved quote requests'),
        leading: IconButton(
          tooltip: 'My requests',
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.go('/requests'),
        ),
      ),
      body: owner == null
          ? AppStatePanel(
              title: 'Sign in to view saved requests',
              message:
                  'Saved requests belong to the account that created them.',
              actionLabel: 'Sign in',
              onAction: () =>
                  context.go('/sign-in?redirect=%2Frequests%2Fpending'),
            )
          : ref
                .watch(pendingRequestsProvider(owner))
                .when(
                  loading: () =>
                      const Center(child: CircularProgressIndicator()),
                  error: (_, _) => AppStatePanel(
                    title: 'Saved requests could not load',
                    message: 'Check device storage and try again. Your saved data has not been replaced.',
                    actionLabel: 'Retry',
                    onAction: () =>
                        ref.invalidate(pendingRequestsProvider(owner)),
                  ),
                  data: (rows) => ListView(
                    padding: const EdgeInsets.all(16),
                    children: [
                      if (rows.isEmpty)
                        AppStatePanel(
                          title: 'No requests waiting to send',
                          message: 'Delivered requests appear in My Requests.',
                          actionLabel: 'My requests',
                          onAction: () => context.go('/requests'),
                        ),
                      if (rows.isNotEmpty) ...[
                        const Text(offlineRequestMessage),
                        const SizedBox(height: 8),
                        const Text(
                          'Keep this app installed and sign in to this account. Do not clear app data before your requests are sent.',
                        ),
                        const SizedBox(height: 16),
                        AppButton(
                          label: 'Send now',
                          busy: _busy,
                          onPressed: _busy ? null : _retry,
                        ),
                        const SizedBox(height: 16),
                      ],
                      for (final row in rows)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: ContentCard(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  row.serviceName,
                                  style: Theme.of(context)
                                      .textTheme
                                      .titleMedium,
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  row.needsAttention
                                      ? 'Needs attention — the request or its files could not be accepted. Contact support with this reference.'
                                      : row.problem == 'sign_in'
                                      ? 'Sign in again to send this request.'
                                      : 'Saved on device · waiting to send',
                                ),
                                SelectableText('Reference ${row.id}'),
                                if (row.notes.isNotEmpty) Text(row.notes),
                                Text('${row.files.length} saved attachments'),
                                Wrap(
                                  spacing: 8,
                                  children: [
                                    TextButton(
                                      onPressed: () =>
                                          context.push('/account/support'),
                                      child: const Text('Support'),
                                    ),
                                    TextButton(
                                      onPressed: _busy
                                          ? null
                                          : () => _remove(row),
                                      child: const Text('Remove saved copy'),
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
    );
  }
}

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/providers.dart';
import '../../../core/widgets/components.dart';
import '../../care/data/care_repository.dart';

class RequestStaffGate extends ConsumerWidget {
  const RequestStaffGate({super.key, required this.child});
  final Widget child;
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(authUserProvider);
    Widget loading() => const Center(child: CircularProgressIndicator());
    Widget denied() => AppStatePanel(
      title: 'Staff access required',
      message: 'Sign in with an authorized FixPK operations account.',
      icon: Icons.lock_outline,
      actionLabel: user.value == null ? 'Sign in' : null,
      onAction: user.value == null
          ? () => context.go('/sign-in?redirect=%2Fstaff%2Frequests')
          : null,
    );
    Widget error() => AppStatePanel(
      title: 'Access could not be checked',
      message: 'Check your connection and try again.',
      isError: true,
      actionLabel: 'Retry',
      onAction: () {
        ref.invalidate(authUserProvider);
        if (user.value != null) {
          ref.invalidate(staffRoleListProvider(user.value!.id));
        }
      },
    );
    return user.when(
      loading: loading,
      error: (_, _) => error(),
      data: (account) {
        if (account == null) return denied();
        return ref
            .watch(staffRoleListProvider(account.id))
            .when(
              loading: loading,
              error: (_, _) => error(),
              data: (roles) =>
                  roles.any(
                    (r) => const {
                      'admin',
                      'operations',
                      'estimator',
                      'support',
                    }.contains(r.role),
                  )
                  ? child
                  : denied(),
            );
      },
    );
  }
}

class StaffRequestsPage extends ConsumerStatefulWidget {
  const StaffRequestsPage({super.key});
  @override
  ConsumerState<StaffRequestsPage> createState() => _StaffRequestsPageState();
}

class _StaffRequestsPageState extends ConsumerState<StaffRequestsPage> {
  int _page = 0;
  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Quote requests')),
    body: RequestStaffGate(
      child: _RequestQueue(
        page: _page,
        changePage: (value) => setState(() => _page = value),
      ),
    ),
  );
}

class _RequestQueue extends ConsumerWidget {
  const _RequestQueue({required this.page, required this.changePage});
  final int page;
  final ValueChanged<int> changePage;
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final provider = staffRequestPageProvider(page);
    return ref
        .watch(provider)
        .when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (_, _) => AppStatePanel(
            title: 'Requests could not load',
            message: 'Check your connection and try again.',
            isError: true,
            actionLabel: 'Retry',
            onAction: () => ref.invalidate(provider),
          ),
          data: (items) => RefreshIndicator(
            onRefresh: () async {
              ref.invalidate(provider);
              await ref.read(provider.future);
            },
            child: ListView.builder(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.all(16),
              itemCount: items.length + 2,
              itemBuilder: (context, index) {
                if (index == 0)
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 16),
                    child: Text(
                      items.isEmpty
                          ? 'No requests on this page.'
                          : 'Customer enquiries · pull down to refresh',
                    ),
                  );
                if (index == items.length + 1)
                  return Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      TextButton(
                        onPressed: page > 0 ? () => changePage(page - 1) : null,
                        child: const Text('Previous'),
                      ),
                      Text('Page ${page + 1}'),
                      TextButton(
                        onPressed: items.length == 50
                            ? () => changePage(page + 1)
                            : null,
                        child: const Text('Next'),
                      ),
                    ],
                  );
                final item = items[index - 1];
                return Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: ContentCard(
                    onTap: () => context.push('/staff/requests/${item.id}'),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          item.serviceName.isEmpty
                              ? 'Service enquiry'
                              : item.serviceName,
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          item.customerName.isEmpty
                              ? item.reference
                              : '${item.customerName} · ${item.reference}',
                        ),
                        const SizedBox(height: 8),
                        StatusChip(label: item.status.replaceAll('_', ' ')),
                        if (item.createdAt != null)
                          Text(
                            MaterialLocalizations.of(context)
                                .formatMediumDate(item.createdAt!.toLocal()),
                          ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        );
  }
}

class StaffRequestDetailPage extends StatelessWidget {
  const StaffRequestDetailPage({super.key, required this.requestId});
  final String requestId;
  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Request details')),
    body: RequestStaffGate(child: _RequestDetail(requestId: requestId)),
  );
}

class _RequestDetail extends ConsumerWidget {
  const _RequestDetail({required this.requestId});
  final String requestId;
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final provider = staffRequestDetailProvider(requestId);
    return ref
        .watch(provider)
        .when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (_, _) => AppStatePanel(
            title: 'Request could not load',
            message: 'Check your connection and try again.',
            isError: true,
            actionLabel: 'Retry',
            onAction: () => ref.invalidate(provider),
          ),
          data: (row) {
            if (row == null)
              return const AppStatePanel(
                title: 'Request unavailable',
                message: 'It may have been removed or your account may not have access.',
              );
            final profile = row['profiles'] as Map<String, dynamic>? ?? {};
            final address = row['addresses'] as Map<String, dynamic>? ?? {};
            final answers = row['service_request_answers'] as List? ?? [];
            final files = row['request_attachments'] as List? ?? [];
            return RefreshIndicator(
              onRefresh: () async {
                ref.invalidate(provider);
                await ref.read(provider.future);
              },
              child: ListView(
                padding: const EdgeInsets.all(20),
                physics: const AlwaysScrollableScrollPhysics(),
                children: [
                  Text(
                    '${(row['services'] as Map<String, dynamic>?)?['name'] ?? 'Service enquiry'}',
                    style: Theme.of(context).textTheme.headlineSmall,
                  ),
                  SelectableText('${row['public_reference'] ?? row['id']}'),
                  const SizedBox(height: 8),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: StatusChip(
                      label: '${row['status']}'.replaceAll('_', ' '),
                    ),
                  ),
                  _section(
                    context,
                    'Customer',
                    [
                          profile['full_name'],
                          address['recipient_name'],
                          profile['phone'],
                          address['phone'],
                        ]
                        .where((v) => v != null && '$v'.isNotEmpty)
                        .toSet()
                        .join('\n'),
                  ),
                  _section(
                    context,
                    'Contact / service address',
                    [
                      address['address_line'],
                      address['area'],
                      address['city'],
                      address['province'],
                    ].where((v) => v != null && '$v'.isNotEmpty).join(', '),
                  ),
                  _section(
                    context,
                    'Preferred schedule',
                    [
                      row['preferred_date'],
                      row['preferred_time'],
                    ].where((v) => v != null && '$v'.isNotEmpty).join(' · '),
                  ),
                  _section(
                    context,
                    'Additional notes',
                    '${row['customer_notes'] ?? ''}',
                  ),
                  for (final answer in answers.whereType<Map<String, dynamic>>())
                    _section(
                      context,
                      '${(answer['service_questions'] as Map<String, dynamic>?)?['label'] ?? 'Requirement'}',
                      answer['answer_value'] is List
                          ? (answer['answer_value'] as List).join(', ')
                          : '${answer['answer_value'] ?? ''}',
                    ),
                  const SizedBox(height: 20),
                  Text(
                    'Attachments',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  if (files.isEmpty) const Text('No attachments supplied.'),
                  for (final file in files.whereType<Map<String, dynamic>>())
                    ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: const Icon(Icons.attach_file),
                      title: Text('${file['file_name'] ?? 'Attachment'}'),
                      subtitle: const Text(
                        'Copy a download link valid for 10 minutes',
                      ),
                      onTap: () => _copyAttachment(context, ref, file),
                    ),
                ],
              ),
            );
          },
        );
  }

  Widget _section(BuildContext context, String title, String body) => Padding(
    padding: const EdgeInsets.only(top: 20),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 4),
        SelectableText(body.isEmpty ? 'Not supplied' : body),
      ],
    ),
  );
  Future<void> _copyAttachment(
    BuildContext context,
    WidgetRef ref,
    Map file,
  ) async {
    try {
      if (file['bucket_id'] != 'request-attachments' ||
          file['object_path'] is! String)
        throw const FormatException('Invalid attachment');
      final url = await ref
          .read(careRepositoryProvider)
          .staffAttachmentUrl(file['object_path'] as String);
      await Clipboard.setData(ClipboardData(text: url));
      if (context.mounted)
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Download link copied. It expires in 10 minutes.'),
          ),
        );
    } on Object {
      if (context.mounted)
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Could not open this attachment. Check your connection and try again.',
            ),
          ),
        );
    }
  }
}

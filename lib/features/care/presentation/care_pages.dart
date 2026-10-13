import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/providers.dart';
import '../../../core/widgets/components.dart';
import '../../jobs/data/jobs_repository.dart';
import '../data/care_repository.dart';
import '../data/public_content_repository.dart';

class NotificationsPage extends ConsumerWidget {
  const NotificationsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(authUserProvider).value;
    if (user == null) return _signInPanel(context, 'notifications');
    final notifications = ref.watch(notificationListProvider(user.id));
    return Scaffold(
      appBar: AppBar(title: const Text('Notifications')),
      body: SafeArea(
        child: notifications.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (_, _) => AppStatePanel(
            title: 'Notifications could not load',
            message: 'Check your connection and try again.',
            isError: true,
            actionLabel: 'Retry',
            onAction: () => ref.invalidate(notificationListProvider(user.id)),
          ),
          data: (items) => items.isEmpty
              ? const AppStatePanel(
                  title: 'You are all caught up',
                  message: 'FixPK updates about your service requests will appear here.',
                  icon: Icons.notifications_none_outlined,
                )
              : RefreshIndicator(
                  onRefresh: () async =>
                      ref.invalidate(notificationListProvider(user.id)),
                  child: ListView.separated(
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
                    itemCount: items.length,
                    separatorBuilder: (_, _) => const SizedBox(height: 10),
                    itemBuilder: (context, index) {
                      final item = items[index];
                      return ContentCard(
                        onTap: () async {
                          if (!item.isRead) {
                            try {
                              await ref
                                  .read(careRepositoryProvider)
                                  .markNotificationRead(user.id, item.id);
                              ref.invalidate(notificationListProvider(user.id));
                            } on Object {
                              if (context.mounted) {
                                _message(
                                  context,
                                  'Could not update this notification.',
                                );
                              }
                            }
                          }
                          final target = _safeInternalPath(item.deepLink);
                          if (target != null && context.mounted) {
                            context.go(target);
                          }
                        },
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Icon(
                              item.isRead
                                  ? Icons.notifications_none_outlined
                                  : Icons.notifications_active_outlined,
                              color: item.isRead
                                  ? Theme.of(context).colorScheme.outline
                                  : Theme.of(context).colorScheme.primary,
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    item.title,
                                    style: Theme.of(context)
                                        .textTheme
                                        .titleMedium,
                                  ),
                                  const SizedBox(height: 4),
                                  Text(item.body),
                                  if (item.createdAt != null) ...[
                                    const SizedBox(height: 8),
                                    Text(
                                      MaterialLocalizations.of(context)
                                          .formatMediumDate(
                                            item.createdAt!.toLocal(),
                                          ),
                                      style: Theme.of(context)
                                          .textTheme
                                          .bodySmall,
                                    ),
                                  ],
                                ],
                              ),
                            ),
                            if (!item.isRead)
                              const Padding(
                                padding: EdgeInsets.only(left: 8, top: 4),
                                child: StatusChip(label: 'New'),
                              ),
                          ],
                        ),
                      );
                    },
                  ),
                ),
        ),
      ),
    );
  }
}

class SupportPage extends ConsumerStatefulWidget {
  const SupportPage({super.key});
  @override
  ConsumerState<SupportPage> createState() => _SupportPageState();
}

class _SupportPageState extends ConsumerState<SupportPage> {
  bool _opening = false;

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(authUserProvider).value;
    if (user == null) return _signInPanel(context, 'support');
    final tickets = ref.watch(supportTicketListProvider(user.id));
    return Scaffold(
      appBar: AppBar(title: const Text('Support')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _opening ? null : () => _openTicket(context, user.id),
        icon: _opening
            ? const SizedBox.square(
                dimension: 20,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
            : const Icon(Icons.add),
        label: const Text('New ticket'),
      ),
      body: SafeArea(
        child: tickets.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (_, _) => AppStatePanel(
            title: 'Support history could not load',
            message: 'Check your connection and try again.',
            isError: true,
            actionLabel: 'Retry',
            onAction: () => ref.invalidate(supportTicketListProvider(user.id)),
          ),
          data: (items) => items.isEmpty
              ? AppStatePanel(
                  title: 'How can we help?',
                  message: 'Create a support ticket and the FixPK team will review it.',
                  icon: Icons.support_agent_outlined,
                  actionLabel: 'Create ticket',
                  onAction: () => _openTicket(context, user.id),
                )
              : ListView.separated(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 96),
                  itemCount: items.length,
                  separatorBuilder: (_, _) => const SizedBox(height: 10),
                  itemBuilder: (context, index) {
                    final ticket = items[index];
                    return ContentCard(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: Text(
                                  ticket.subject,
                                  style: Theme.of(context)
                                      .textTheme
                                      .titleMedium,
                                ),
                              ),
                              StatusChip(
                                label: _statusName(ticket.status),
                                tone: _ticketTone(ticket.status),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Text(ticket.message),
                          if (ticket.createdAt != null) ...[
                            const SizedBox(height: 8),
                            Text(
                              'Submitted ${MaterialLocalizations.of(context).formatMediumDate(ticket.createdAt!.toLocal())}',
                              style: Theme.of(context).textTheme.bodySmall,
                            ),
                          ],
                          const SizedBox(height: 8),
                          const Text(
                            'Replies will appear in FixPK support when customer messaging is enabled.',
                            style: TextStyle(fontStyle: FontStyle.italic),
                          ),
                        ],
                      ),
                    );
                  },
                ),
        ),
      ),
    );
  }

  Future<void> _openTicket(BuildContext context, String profileId) async {
    final draft = await showDialog<({String subject, String message})>(
      context: context,
      builder: (context) => const _NewTicketDialog(),
    );
    if (draft == null || !context.mounted || !mounted) return;
    setState(() => _opening = true);
    try {
      await ref
          .read(careRepositoryProvider)
          .createTicket(subject: draft.subject, message: draft.message);
      ref.invalidate(supportTicketListProvider(profileId));
      if (context.mounted) {
        _message(context, 'Support ticket sent.');
      }
    } on Object {
      if (context.mounted) {
        _message(
          context,
          'Could not send your ticket. Check your connection and try again.',
        );
      }
    } finally {
      if (mounted) setState(() => _opening = false);
    }
  }
}

class _NewTicketDialog extends StatefulWidget {
  const _NewTicketDialog();
  @override
  State<_NewTicketDialog> createState() => _NewTicketDialogState();
}

class _NewTicketDialogState extends State<_NewTicketDialog> {
  final _form = GlobalKey<FormState>();
  final _subject = TextEditingController();
  final _message = TextEditingController();
  @override
  void dispose() {
    _subject.dispose();
    _message.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AlertDialog(
    title: const Text('Contact FixPK support'),
    content: Form(
      key: _form,
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextFormField(
              controller: _subject,
              maxLength: 120,
              decoration: const InputDecoration(labelText: 'Subject'),
              validator: (value) => value == null || value.trim().isEmpty
                  ? 'Enter a subject.'
                  : null,
            ),
            TextFormField(
              controller: _message,
              minLines: 3,
              maxLines: 6,
              maxLength: 2000,
              decoration: const InputDecoration(labelText: 'How can we help?'),
              validator: (value) => value == null || value.trim().isEmpty
                  ? 'Describe what you need help with.'
                  : null,
            ),
          ],
        ),
      ),
    ),
    actions: [
      TextButton(
        onPressed: () => Navigator.pop(context),
        child: const Text('Cancel'),
      ),
      FilledButton(
        onPressed: () {
          if (_form.currentState!.validate()) {
            Navigator.pop(context, (
              subject: _subject.text.trim(),
              message: _message.text.trim(),
            ));
          }
        },
        child: const Text('Send ticket'),
      ),
    ],
  );
}

class FaqPage extends ConsumerWidget {
  const FaqPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (ref.watch(configProvider).preview) {
      return Scaffold(
        appBar: AppBar(title: const Text('FAQs')),
        body: const AppStatePanel(
          title: 'Frequently asked questions',
          message:
              'Connect to FixPK to load approved answers from the help centre.',
          icon: Icons.help_outline,
        ),
      );
    }
    const language = 'en';
    final faqs = ref.watch(faqListProvider(language));
    return Scaffold(
      appBar: AppBar(title: const Text('FAQs')),
      body: SafeArea(
        child: faqs.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (_, _) => AppStatePanel(
            title: 'FAQs could not load',
            message: 'Check your connection and try again.',
            isError: true,
            actionLabel: 'Retry',
            onAction: () => ref.invalidate(faqListProvider(language)),
          ),
          data: (items) => items.isEmpty
              ? const AppStatePanel(
                  title: 'Help articles are being prepared',
                  message: 'Contact FixPK support if you need assistance now.',
                  icon: Icons.help_outline,
                )
              : ListView.separated(
                  padding: const EdgeInsets.all(16),
                  itemCount: items.length,
                  separatorBuilder: (_, _) => const SizedBox(height: 8),
                  itemBuilder: (context, index) => ContentCard(
                    child: ExpansionTile(
                      tilePadding: EdgeInsets.zero,
                      childrenPadding: const EdgeInsets.only(bottom: 12),
                      title: Text(items[index].question),
                      children: [
                        Align(
                          alignment: Alignment.centerLeft,
                          child: Text(items[index].answer),
                        ),
                      ],
                    ),
                  ),
                ),
        ),
      ),
    );
  }
}

class PreferencesPage extends ConsumerStatefulWidget {
  const PreferencesPage({super.key});
  @override
  ConsumerState<PreferencesPage> createState() => _PreferencesPageState();
}

class _PreferencesPageState extends ConsumerState<PreferencesPage> {
  UserPreferencesRecord? _draft;
  bool _saving = false;

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(authUserProvider).value;
    if (user == null) return _signInPanel(context, 'preferences');
    final preferences = ref.watch(userPreferencesProvider(user.id));
    return Scaffold(
      appBar: AppBar(title: const Text('Preferences')),
      body: SafeArea(
        child: preferences.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (_, _) => AppStatePanel(
            title: 'Preferences could not load',
            message: 'Check your connection and try again.',
            isError: true,
            actionLabel: 'Retry',
            onAction: () => ref.invalidate(userPreferencesProvider(user.id)),
          ),
          data: (saved) {
            _draft ??= saved;
            final draft = _draft!;
            return ListView(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
              children: [
                const Text(
                  'Choose which channels FixPK may use for service updates.',
                ),
                const SizedBox(height: 16),
                SwitchListTile.adaptive(
                  value: draft.pushEnabled,
                  title: const Text('Push notifications'),
                  subtitle: const Text(
                    'Delivery requires notifications to be configured on this device.',
                  ),
                  onChanged: (value) => setState(
                    () => _draft = UserPreferencesRecord(
                      profileId: draft.profileId,
                      pushEnabled: value,
                      emailEnabled: draft.emailEnabled,
                      smsEnabled: draft.smsEnabled,
                      languageCode: draft.languageCode,
                    ),
                  ),
                ),
                SwitchListTile.adaptive(
                  value: draft.emailEnabled,
                  title: const Text('Email updates'),
                  onChanged: (value) => setState(
                    () => _draft = UserPreferencesRecord(
                      profileId: draft.profileId,
                      pushEnabled: draft.pushEnabled,
                      emailEnabled: value,
                      smsEnabled: draft.smsEnabled,
                      languageCode: draft.languageCode,
                    ),
                  ),
                ),
                SwitchListTile.adaptive(
                  value: draft.smsEnabled,
                  title: const Text('SMS updates'),
                  onChanged: (value) => setState(
                    () => _draft = UserPreferencesRecord(
                      profileId: draft.profileId,
                      pushEnabled: draft.pushEnabled,
                      emailEnabled: draft.emailEnabled,
                      smsEnabled: value,
                      languageCode: draft.languageCode,
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<String>(
                  initialValue: draft.languageCode,
                  decoration: const InputDecoration(labelText: 'Language'),
                  items: const [
                    DropdownMenuItem(value: 'en', child: Text('English')),
                    DropdownMenuItem(value: 'ur', child: Text('اردو')),
                  ],
                  onChanged: (value) {
                    if (value == null) return;
                    setState(
                      () => _draft = UserPreferencesRecord(
                        profileId: draft.profileId,
                        pushEnabled: draft.pushEnabled,
                        emailEnabled: draft.emailEnabled,
                        smsEnabled: draft.smsEnabled,
                        languageCode: value,
                      ),
                    );
                  },
                ),
                const SizedBox(height: 24),
                AppButton(
                  label: 'Save preferences',
                  busy: _saving,
                  onPressed: _saving ? null : () => _save(user.id),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  Future<void> _save(String userId) async {
    final draft = _draft;
    if (draft == null) return;
    setState(() => _saving = true);
    try {
      await ref.read(careRepositoryProvider).savePreferences(draft);
      ref.invalidate(userPreferencesProvider(userId));
      if (mounted) {
        _message(context, 'Preferences saved.');
      }
    } on Object {
      if (mounted) {
        _message(context, 'Could not save your preferences. Try again.');
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }
}

class ReviewsPage extends ConsumerWidget {
  const ReviewsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(authUserProvider).value;
    if (user == null) return _signInPanel(context, 'reviews');
    final reviews = ref.watch(ownReviewListProvider(user.id));
    return Scaffold(
      appBar: AppBar(title: const Text('My reviews')),
      body: SafeArea(
        child: reviews.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (_, _) => AppStatePanel(
            title: 'Reviews could not load',
            message: 'Check your connection and try again.',
            isError: true,
            actionLabel: 'Retry',
            onAction: () => ref.invalidate(ownReviewListProvider(user.id)),
          ),
          data: (items) => items.isEmpty
              ? const AppStatePanel(
                  title: 'No reviews yet',
                  message: 'After a FixPK job is completed, you can share feedback from its request details.',
                  icon: Icons.star_outline,
                )
              : ListView.separated(
                  padding: const EdgeInsets.all(16),
                  itemCount: items.length,
                  separatorBuilder: (_, _) => const SizedBox(height: 10),
                  itemBuilder: (context, index) => ContentCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                'Your rating',
                                style: Theme.of(context).textTheme.titleMedium,
                              ),
                            ),
                            StatusChip(
                              label: _statusName(items[index].status),
                              tone: _reviewTone(items[index].status),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(
                          '${'★' * items[index].rating}${'☆' * (5 - items[index].rating)}',
                        ),
                        if (items[index].reviewText.isNotEmpty) ...[
                          const SizedBox(height: 8),
                          Text(items[index].reviewText),
                        ],
                      ],
                    ),
                  ),
                ),
        ),
      ),
    );
  }
}

class ReviewComposerPage extends ConsumerStatefulWidget {
  const ReviewComposerPage({super.key, required this.jobId});
  final String jobId;

  @override
  ConsumerState<ReviewComposerPage> createState() => _ReviewComposerPageState();
}

class _ReviewComposerPageState extends ConsumerState<ReviewComposerPage> {
  final _reviewText = TextEditingController();
  int _rating = 5;
  bool _saving = false;

  @override
  void dispose() {
    _reviewText.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(authUserProvider).value;
    if (user == null) return _signInPanel(context, 'reviews');
    final reviews = ref.watch(ownReviewListProvider(user.id));
    return Scaffold(
      appBar: AppBar(title: const Text('Review completed work')),
      body: SafeArea(
        child: reviews.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (_, _) => const AppStatePanel(
            title: 'Review eligibility could not load',
            message: 'Refresh the request and try again.',
            isError: true,
          ),
          data: (items) {
            if (items.any((item) => item.jobId == widget.jobId)) {
              return const AppStatePanel(
                title: 'Review already submitted',
                message: 'You can view its publication status in My reviews.',
                icon: Icons.star,
              );
            }
            return ListView(
              padding: const EdgeInsets.all(16),
              children: [
                const Text('How was your FixPK service?'),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 8,
                  children: [
                    for (var value = 1; value <= 5; value++)
                      ChoiceChip(
                        label: Text('$value ${value == 1 ? 'star' : 'stars'}'),
                        selected: _rating == value,
                        onSelected: (_) => setState(() => _rating = value),
                      ),
                  ],
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: _reviewText,
                  minLines: 4,
                  maxLines: 8,
                  maxLength: 2000,
                  textCapitalization: TextCapitalization.sentences,
                  decoration: const InputDecoration(
                    labelText: 'Your comments (optional)',
                    alignLabelWithHint: true,
                  ),
                ),
                const SizedBox(height: 16),
                const Text(
                  'Your review is submitted for moderation before it appears publicly.',
                ),
                const SizedBox(height: 16),
                AppButton(
                  label: 'Submit review',
                  busy: _saving,
                  onPressed: _saving ? null : () => _submit(user.id),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  Future<void> _submit(String profileId) async {
    setState(() => _saving = true);
    try {
      await ref
          .read(careRepositoryProvider)
          .submitReview(
            jobId: widget.jobId,
            rating: _rating,
            reviewText: _reviewText.text,
          );
      ref.invalidate(ownReviewListProvider(profileId));
      if (mounted) {
        _message(context, 'Review submitted for moderation.');
        context.pop();
      }
    } on Object {
      if (mounted) {
        _message(
          context,
          'Could not submit the review. It may already exist or the job may not be eligible.',
        );
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }
}

class LegalPage extends ConsumerWidget {
  const LegalPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) => Scaffold(
    appBar: AppBar(
      title: const Text('Legal and privacy'),
      actions: [
        IconButton(
          tooltip: 'Refresh policies',
          icon: const Icon(Icons.refresh),
          onPressed: () => ref.invalidate(legalContentProvider),
        ),
      ],
    ),
    body: SafeArea(
      child: ref
          .watch(legalContentProvider)
          .when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (_, _) => AppStatePanel(
              title: 'Policies could not load',
              message: 'Check your connection and try again.',
              actionLabel: 'Retry',
              onAction: () => ref.invalidate(legalContentProvider),
            ),
            data: (items) => items.isEmpty
                ? AppStatePanel(
                    title: 'Policies are not available yet',
                    message:
                        'Contact FixPK for privacy and service information.',
                    actionLabel: 'Contact support',
                    onAction: () => context.push('/account/support'),
                  )
                : ListView.separated(
                    padding: const EdgeInsets.all(16),
                    itemCount: items.length,
                    separatorBuilder: (_, _) => const SizedBox(height: 16),
                    itemBuilder: (context, index) => ContentCard(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            items[index].title,
                            style: Theme.of(context).textTheme.titleLarge,
                          ),
                          const SizedBox(height: 12),
                          SelectableText(items[index].text),
                        ],
                      ),
                    ),
                  ),
          ),
    ),
  );
}

class StaffOperationsPage extends ConsumerWidget {
  const StaffOperationsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(authUserProvider).value;
    if (user == null) return _signInPanel(context, 'staff');
    final roles = ref.watch(staffRoleListProvider(user.id));
    return Scaffold(
      appBar: AppBar(title: const Text('Staff operations')),
      body: SafeArea(
        child: roles.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (_, _) => const AppStatePanel(
            title: 'Staff access could not be verified',
            message:
                'Try again. The database remains the access-control boundary.',
            isError: true,
          ),
          data: (items) => items.isEmpty
              ? const AppStatePanel(
                  title: 'Staff access required',
                  message: 'This account does not have a FixPK staff role.',
                  icon: Icons.lock_outline,
                )
              : _StaffQueues(roles: items.map((item) => item.role).toSet()),
        ),
      ),
    );
  }
}

class _StaffQueues extends ConsumerWidget {
  const _StaffQueues({required this.roles});
  final Set<String> roles;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final requests = ref.watch(staffRequestListProvider);
    final jobs = ref.watch(staffJobListProvider);
    final tickets = ref.watch(staffTicketListProvider);
    final reviews = ref.watch(pendingReviewListProvider);
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
      children: [
        Text(
          'Operations overview',
          style: Theme.of(context).textTheme.headlineSmall,
        ),
        const SizedBox(height: 8),
        Text(
          'Signed in with role${roles.length == 1 ? '' : 's'}: ${roles.join(', ')}',
        ),
        const SizedBox(height: 16),
        const ContentCard(
          child: Text(
            'This staff view follows the roles assigned to this account. RLS in Supabase remains responsible for authorizing every read and update.',
          ),
        ),
        const SizedBox(height: 16),
        Text(
          'Service request queue',
          style: Theme.of(context).textTheme.titleLarge,
        ),
        const SizedBox(height: 8),
        requests.when(
          loading: () => const LinearProgressIndicator(),
          error: (_, _) =>
              const ContentCard(child: Text('Request queue is unavailable.')),
          data: (items) => items.isEmpty
              ? const ContentCard(child: Text('No service requests.'))
              : Column(
                  children: [
                    for (final request in items.take(10))
                      ContentCard(
                        child: ListTile(
                          contentPadding: EdgeInsets.zero,
                          title: Text(request.reference),
                          subtitle: Text('Service ${request.serviceId}'),
                          trailing: StatusChip(
                            label: _statusName(request.status),
                          ),
                        ),
                      ),
                  ],
                ),
        ),
        const SizedBox(height: 20),
        Text('Job queue', style: Theme.of(context).textTheme.titleLarge),
        const SizedBox(height: 8),
        jobs.when(
          loading: () => const LinearProgressIndicator(),
          error: (_, _) =>
              const ContentCard(child: Text('Job queue is unavailable.')),
          data: (items) => items.isEmpty
              ? const ContentCard(child: Text('No jobs are scheduled.'))
              : Column(
                  children: [
                    for (final job in items)
                      _StaffJobCard(
                        job: job,
                        canManage:
                            roles.contains('admin') ||
                            roles.contains('operations'),
                      ),
                  ],
                ),
        ),
        const SizedBox(height: 20),
        Text('Support queue', style: Theme.of(context).textTheme.titleLarge),
        const SizedBox(height: 8),
        tickets.when(
          loading: () => const LinearProgressIndicator(),
          error: (_, _) =>
              const ContentCard(child: Text('Support queue is unavailable.')),
          data: (items) => items.isEmpty
              ? const ContentCard(child: Text('No support tickets.'))
              : Column(
                  children: [
                    for (final ticket in items)
                      _StaffTicketCard(
                        ticket: ticket,
                        canManage:
                            roles.contains('admin') ||
                            roles.contains('support'),
                      ),
                  ],
                ),
        ),
        const SizedBox(height: 20),
        Text(
          'Reviews awaiting moderation',
          style: Theme.of(context).textTheme.titleLarge,
        ),
        const SizedBox(height: 8),
        reviews.when(
          loading: () => const LinearProgressIndicator(),
          error: (_, _) =>
              const ContentCard(child: Text('Review queue is unavailable.')),
          data: (items) => items.isEmpty
              ? const ContentCard(
                  child: Text('No reviews awaiting moderation.'),
                )
              : Column(
                  children: [
                    for (final review in items)
                      _StaffReviewCard(
                        review: review,
                        canManage:
                            roles.contains('admin') ||
                            roles.contains('content_manager'),
                      ),
                  ],
                ),
        ),
      ],
    );
  }
}

class _StaffJobCard extends ConsumerWidget {
  const _StaffJobCard({required this.job, required this.canManage});
  final JobRecord job;
  final bool canManage;

  @override
  Widget build(BuildContext context, WidgetRef ref) => ContentCard(
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Job ${job.id}', style: Theme.of(context).textTheme.titleSmall),
        Text('Request ${job.requestId}'),
        if (job.scheduledStart != null) ...[
          const SizedBox(height: 4),
          Text(
            'Scheduled ${MaterialLocalizations.of(context).formatMediumDate(job.scheduledStart!.toLocal())}',
          ),
        ],
        const SizedBox(height: 8),
        if (canManage)
          DropdownButtonFormField<String>(
            initialValue: job.status,
            decoration: const InputDecoration(labelText: 'Job status'),
            items: const [
              DropdownMenuItem(value: 'scheduled', child: Text('Scheduled')),
              DropdownMenuItem(
                value: 'in_progress',
                child: Text('In progress'),
              ),
              DropdownMenuItem(value: 'completed', child: Text('Completed')),
              DropdownMenuItem(value: 'cancelled', child: Text('Cancelled')),
            ],
            onChanged: (status) async {
              if (status == null || status == job.status) return;
              try {
                await ref
                    .read(jobsRepositoryProvider)
                    .updateJobStatus(job.id, status);
                ref.invalidate(staffJobListProvider);
                if (context.mounted) _message(context, 'Job status updated.');
              } on Object {
                if (context.mounted) {
                  _message(context, 'Could not update job status.');
                }
              }
            },
          )
        else
          StatusChip(label: _statusName(job.status)),
      ],
    ),
  );
}

class _StaffTicketCard extends ConsumerWidget {
  const _StaffTicketCard({required this.ticket, required this.canManage});
  final SupportTicketRecord ticket;
  final bool canManage;

  @override
  Widget build(BuildContext context, WidgetRef ref) => ContentCard(
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                ticket.subject,
                style: Theme.of(context).textTheme.titleMedium,
              ),
            ),
            StatusChip(
              label: _statusName(ticket.status),
              tone: _ticketTone(ticket.status),
            ),
          ],
        ),
        const SizedBox(height: 6),
        Text(ticket.message),
        const SizedBox(height: 8),
        if (canManage)
          DropdownButtonFormField<String>(
            initialValue: ticket.status,
            decoration: const InputDecoration(
              labelText: 'Update ticket status',
            ),
            items: const [
              DropdownMenuItem(value: 'open', child: Text('Open')),
              DropdownMenuItem(
                value: 'in_progress',
                child: Text('In progress'),
              ),
              DropdownMenuItem(
                value: 'waiting_for_customer',
                child: Text('Waiting for customer'),
              ),
              DropdownMenuItem(value: 'resolved', child: Text('Resolved')),
              DropdownMenuItem(value: 'closed', child: Text('Closed')),
            ],
            onChanged: (status) async {
              if (status == null || status == ticket.status) return;
              try {
                await ref
                    .read(careRepositoryProvider)
                    .updateTicketStatus(ticket.id, status);
                ref.invalidate(staffTicketListProvider);
                if (context.mounted) {
                  _message(context, 'Ticket status updated.');
                }
              } on Object {
                if (context.mounted) {
                  _message(context, 'Could not update ticket status.');
                }
              }
            },
          )
        else
          StatusChip(label: _statusName(ticket.status)),
      ],
    ),
  );
}

class _StaffReviewCard extends ConsumerWidget {
  const _StaffReviewCard({required this.review, required this.canManage});
  final ReviewRecord review;
  final bool canManage;

  @override
  Widget build(BuildContext context, WidgetRef ref) => ContentCard(
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Expanded(child: Text('Customer review')),
            Text('${'★' * review.rating}${'☆' * (5 - review.rating)}'),
          ],
        ),
        if (review.reviewText.isNotEmpty) ...[
          const SizedBox(height: 8),
          Text(review.reviewText),
        ],
        const SizedBox(height: 12),
        if (canManage)
          Wrap(
            spacing: 8,
            children: [
              OutlinedButton(
                onPressed: () => _moderate(context, ref, 'rejected'),
                child: const Text('Reject'),
              ),
              FilledButton(
                onPressed: () => _moderate(context, ref, 'published'),
                child: const Text('Publish'),
              ),
            ],
          )
        else
          const Text('Moderation access is limited to content managers.'),
      ],
    ),
  );

  Future<void> _moderate(
    BuildContext context,
    WidgetRef ref,
    String status,
  ) async {
    try {
      await ref.read(careRepositoryProvider).moderateReview(review.id, status);
      ref.invalidate(pendingReviewListProvider);
      if (context.mounted) {
        _message(
          context,
          'Review ${status == 'published' ? 'published' : 'rejected'}.',
        );
      }
    } on Object {
      if (context.mounted) _message(context, 'Could not update this review.');
    }
  }
}

Widget _signInPanel(BuildContext context, String destination) => AppStatePanel(
  title: 'Sign in to continue',
  message: 'This FixPK account information is private.',
  icon: Icons.lock_outline,
  actionLabel: 'Sign in',
  onAction: () => context.go(
    '/sign-in?redirect=${Uri.encodeComponent('/account/$destination')}',
  ),
);

String? _safeInternalPath(String? path) =>
    path != null && path.startsWith('/') && !path.startsWith('//')
    ? path
    : null;

String _statusName(String status) => status
    .split('_')
    .map(
      (word) =>
          word.isEmpty ? word : '${word[0].toUpperCase()}${word.substring(1)}',
    )
    .join(' ');

StatusTone _ticketTone(String status) => switch (status) {
  'resolved' || 'closed' => StatusTone.success,
  'waiting_for_customer' => StatusTone.warning,
  _ => StatusTone.information,
};

StatusTone _reviewTone(String status) => switch (status) {
  'published' => StatusTone.success,
  'rejected' => StatusTone.error,
  _ => StatusTone.warning,
};

void _message(BuildContext context, String text) {
  ScaffoldMessenger.of(context)
    ..hideCurrentSnackBar()
    ..showSnackBar(SnackBar(content: Text(text)));
}

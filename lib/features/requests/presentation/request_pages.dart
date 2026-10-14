import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/providers.dart';
import '../../../core/widgets/components.dart';
import '../../../core/theme/app_theme.dart';
import '../../services/data/services_repository.dart';
import '../../jobs/data/jobs_repository.dart';
import '../data/request_repository.dart';

class _PreviewRequests extends StatelessWidget {
  const _PreviewRequests();
  @override
  Widget build(BuildContext context) => DefaultTabController(
    length: 3,
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
          child: Text(
            'My requests',
            style: Theme.of(context).textTheme.headlineSmall,
          ),
        ),
        const TabBar(
          tabs: [
            Tab(text: 'All'),
            Tab(text: 'Active'),
            Tab(text: 'Completed'),
          ],
        ),
        Expanded(
          child: TabBarView(
            children: [
              for (var tab = 0; tab < 3; tab++)
                ListView(
                  padding: const EdgeInsets.all(16),
                  children: [
                    if (tab != 2)
                      _PreviewRequestCard(
                        id: 'solar-request',
                        title: 'Solar Panel Installation',
                        reference: 'FPK-2026-0142',
                        status: 'Site survey scheduled',
                        image: 'assets/images/solar-panels.jpg',
                        tone: StatusTone.information,
                      ),
                    if (tab != 2) const SizedBox(height: 12),
                    if (tab != 1)
                      _PreviewRequestCard(
                        id: 'geyser-request',
                        title: 'Solar Water Heater',
                        reference: 'FPK-2026-0098',
                        status: 'Completed',
                        image: 'assets/images/solar-geyser.jpg',
                        tone: StatusTone.success,
                      ),
                    if (tab == 2) const SizedBox(height: 12),
                    if (tab == 2)
                      _PreviewRequestCard(
                        id: 'cctv-request',
                        title: 'CCTV Installation',
                        reference: 'FPK-2026-0085',
                        status: 'Completed',
                        image: 'assets/images/cctv-installation.jpg',
                        tone: StatusTone.success,
                      ),
                  ],
                ),
            ],
          ),
        ),
      ],
    ),
  );
}

class _PreviewRequestCard extends StatelessWidget {
  const _PreviewRequestCard({
    required this.id,
    required this.title,
    required this.reference,
    required this.status,
    required this.image,
    required this.tone,
  });
  final String id, title, reference, status, image;
  final StatusTone tone;
  @override
  Widget build(BuildContext context) => ContentCard(
    onTap: () => context.push('/requests/$id'),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(10),
          child: Image.asset(image, width: 82, height: 88, fit: BoxFit.cover),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 6),
              Text(reference, style: Theme.of(context).textTheme.bodySmall),
              const SizedBox(height: 8),
              StatusChip(label: status, tone: tone),
              const SizedBox(height: 6),
              const Row(
                children: [
                  Text(
                    'Track request',
                    style: TextStyle(
                      color: FixPkColors.action,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  SizedBox(width: 4),
                  Icon(
                    Icons.arrow_forward,
                    color: FixPkColors.action,
                    size: 16,
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    ),
  );
}

class _PreviewRequestDetail extends StatelessWidget {
  const _PreviewRequestDetail({required this.requestId});
  final String requestId;
  @override
  Widget build(BuildContext context) {
    final completed =
        requestId.contains('geyser') || requestId.contains('cctv');
    final title = requestId.contains('geyser')
        ? 'Solar Water Heater'
        : requestId.contains('cctv')
        ? 'CCTV Installation'
        : 'Solar Panel Installation';
    final image = requestId.contains('geyser')
        ? 'assets/images/solar-geyser.jpg'
        : requestId.contains('cctv')
        ? 'assets/images/cctv-installation.jpg'
        : 'assets/images/solar-panels.jpg';
    final stages = [
      'Request submitted',
      'FixPK review',
      'Site survey',
      'Quote prepared',
      'Technician assigned',
      'Work completed',
    ];
    final last = completed ? stages.length - 1 : 2;
    return Scaffold(
      appBar: AppBar(title: const Text('Request tracking')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(14),
            child: Image.asset(image, height: 165, fit: BoxFit.cover),
          ),
          const SizedBox(height: 16),
          Text(title, style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 4),
          const Text('Reference FPK-2026-0142'),
          const SizedBox(height: 12),
          StatusChip(
            label: completed ? 'Completed' : 'Site survey scheduled',
            tone: completed ? StatusTone.success : StatusTone.information,
          ),
          const SizedBox(height: 24),
          Text(
            'Request progress',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 12),
          for (var i = 0; i < stages.length; i++)
            _TimelineRow(
              title: stages[i],
              active: i <= last,
              last: i == stages.length - 1,
              subtitle: i == last
                  ? (completed
                        ? 'Job completed successfully'
                        : 'Your visit is being arranged')
                  : null,
            ),
          if (!completed) ...[
            const SizedBox(height: 16),
            AppButton(
              label: 'View quotation',
              icon: Icons.request_quote_outlined,
              onPressed: () => ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Your quote is being prepared by FixPK.'),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _TimelineRow extends StatelessWidget {
  const _TimelineRow({
    required this.title,
    required this.active,
    required this.last,
    this.subtitle,
  });
  final String title;
  final bool active, last;
  final String? subtitle;
  @override
  Widget build(BuildContext context) => IntrinsicHeight(
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SizedBox(
          width: 28,
          child: Column(
            children: [
              Container(
                width: 20,
                height: 20,
                decoration: BoxDecoration(
                  color: active ? FixPkColors.action : Colors.white,
                  border: Border.all(
                    color: active ? FixPkColors.action : FixPkColors.border,
                    width: 2,
                  ),
                  shape: BoxShape.circle,
                ),
              ),
              if (!last)
                Expanded(
                  child: Container(
                    width: 2,
                    color: active ? FixPkColors.action : FixPkColors.border,
                  ),
                ),
            ],
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.only(bottom: 19),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontWeight: active ? FontWeight.w600 : FontWeight.normal,
                    color: active ? FixPkColors.ink : FixPkColors.muted,
                  ),
                ),
                if (subtitle != null)
                  Text(subtitle!, style: Theme.of(context).textTheme.bodySmall),
              ],
            ),
          ),
        ),
      ],
    ),
  );
}

class RequestsPage extends ConsumerWidget {
  const RequestsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (ref.watch(configProvider).preview) return const _PreviewRequests();
    final userState = ref.watch(authUserProvider);
    return userState.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (_, _) =>
          const Center(child: Text('Account status could not be loaded.')),
      data: (user) {
        if (user == null) {
          const target = '/requests';
          return AppStatePanel(
            title: 'Sign in to view your requests',
            message:
                'Your quotes, surveys and work updates are kept private to your account.',
            icon: Icons.lock_outline,
            actionLabel: 'Sign in',
            onAction: () =>
                context.go('/sign-in?redirect=${Uri.encodeComponent(target)}'),
          );
        }
        final requests = ref.watch(customerRequestsProvider(user.id));
        final catalogue = ref.watch(serviceCatalogueProvider);
        return Column(
          children: [
            ListTile(
              leading: const Icon(Icons.cloud_upload_outlined),
              title: const Text('Saved quote requests'),
              subtitle: const Text(
                'Check requests waiting to send. Saved details may be out of date while offline.',
              ),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => context.push('/requests/pending'),
            ),
            Expanded(
              child: requests.when(
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (_, _) => AppStatePanel(
                  title: 'Requests could not load',
                  message: 'Check your connection and try again.',
                  isError: true,
                  actionLabel: 'Retry',
                  onAction: () =>
                      ref.invalidate(customerRequestsProvider(user.id)),
                ),
                data: (items) => catalogue.when(
                  loading: () => _requestList(context, ref, items, const {}),
                  error: (_, _) => _requestList(context, ref, items, const {}),
                  data: (services) => _requestList(context, ref, items, {
                    for (final service in services.services)
                      service.id: service.name,
                  }),
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _requestList(
    BuildContext context,
    WidgetRef ref,
    List<RequestRecord> requests,
    Map<String, String> serviceNames,
  ) {
    if (requests.isEmpty) {
      return AppStatePanel(
        title: 'No requests yet',
        message:
            'Explore FixPK services and send us your requirements to get started.',
        icon: Icons.assignment_outlined,
        actionLabel: 'Explore services',
        onAction: () => context.go('/services'),
      );
    }
    return RefreshIndicator(
      onRefresh: () async {
        final user = ref.read(authUserProvider).value;
        if (user != null) ref.invalidate(customerRequestsProvider(user.id));
      },
      child: ListView.separated(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
        itemCount: requests.length,
        separatorBuilder: (_, _) => const SizedBox(height: 12),
        itemBuilder: (context, index) {
          final request = requests[index];
          return ContentCard(
            onTap: () => context.push('/requests/${request.id}'),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        serviceNames[request.serviceId] ?? 'Service request',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                    ),
                    StatusChip(
                      label: _statusLabel(request.status),
                      tone: _statusTone(request.status),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text('Reference ${request.reference}'),
                if (request.createdAt != null)
                  Text(
                    'Submitted ${MaterialLocalizations.of(context).formatMediumDate(request.createdAt!.toLocal())}',
                  ),
                const SizedBox(height: 8),
                const Row(
                  children: [
                    Text('View details'),
                    SizedBox(width: 6),
                    Icon(Icons.arrow_forward, size: 16),
                  ],
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class RequestDetailPage extends ConsumerWidget {
  const RequestDetailPage({super.key, required this.requestId});
  final String requestId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (ref.watch(configProvider).preview) {
      return _PreviewRequestDetail(requestId: requestId);
    }
    final user = ref.watch(authUserProvider).value;
    if (user == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Request details')),
        body: AppStatePanel(
          title: 'Sign in to view this request',
          message: 'Request details are private to your FixPK account.',
          actionLabel: 'Sign in',
          onAction: () => context.go(
            '/sign-in?redirect=${Uri.encodeComponent('/requests/$requestId')}',
          ),
        ),
      );
    }
    final requestState = ref.watch(
      requestDetailProvider((profileId: user.id, requestId: requestId)),
    );
    final services = ref.watch(serviceCatalogueProvider);
    final surveys = ref.watch(surveyListProvider(requestId));
    final appointments = ref.watch(appointmentListProvider(requestId));
    final quotes = ref.watch(requestQuotesProvider(requestId));
    final jobs = ref.watch(requestJobsProvider(requestId));
    return Scaffold(
      appBar: AppBar(title: const Text('Request details')),
      body: SafeArea(
        child: requestState.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (_, _) => AppStatePanel(
            title: 'Request could not load',
            message: 'Check your connection and try again.',
            isError: true,
            actionLabel: 'Retry',
            onAction: () => ref.invalidate(
              requestDetailProvider((profileId: user.id, requestId: requestId)),
            ),
          ),
          data: (request) {
            if (request == null) {
              return const AppStatePanel(
                title: 'Request not found',
                message: 'It may have been removed or is no longer available.',
              );
            }
            return services.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (_, _) => _detail(
                context,
                ref,
                user.id,
                request,
                'Service request',
                surveys,
                appointments,
                quotes,
                jobs,
              ),
              data: (catalogue) {
                final matching = catalogue.services.where(
                  (item) => item.id == request.serviceId,
                );
                final serviceName = matching.isEmpty
                    ? 'Service request'
                    : matching.first.name;
                return _detail(
                  context,
                  ref,
                  user.id,
                  request,
                  serviceName,
                  surveys,
                  appointments,
                  quotes,
                  jobs,
                );
              },
            );
          },
        ),
      ),
    );
  }

  Widget _detail(
    BuildContext context,
    WidgetRef ref,
    String profileId,
    RequestRecord request,
    String serviceName,
    AsyncValue<List<SurveyRecord>> surveys,
    AsyncValue<List<AppointmentRecord>> appointments,
    AsyncValue<List<QuoteRecord>> quotes,
    AsyncValue<List<JobRecord>> jobs,
  ) => RefreshIndicator(
    onRefresh: () async {
      ref.invalidate(
        requestDetailProvider((profileId: profileId, requestId: request.id)),
      );
      ref.invalidate(surveyListProvider(request.id));
      ref.invalidate(appointmentListProvider(request.id));
      ref.invalidate(requestQuotesProvider(request.id));
      ref.invalidate(requestJobsProvider(request.id));
    },
    child: ListView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
      children: [
        ContentCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(serviceName, style: Theme.of(context).textTheme.titleLarge),
              const SizedBox(height: 8),
              StatusChip(
                label: _statusLabel(request.status),
                tone: _statusTone(request.status),
              ),
              const SizedBox(height: 12),
              Text('Reference ${request.reference}'),
              Text(
                'Submitted ${request.createdAt == null ? 'recently' : MaterialLocalizations.of(context).formatMediumDate(request.createdAt!.toLocal())}',
              ),
              if (request.notes.isNotEmpty) ...[
                const SizedBox(height: 12),
                const Text(
                  'Your notes',
                  style: TextStyle(fontWeight: FontWeight.w600),
                ),
                Text(request.notes),
              ],
              if (request.preferredDate != null) ...[
                const SizedBox(height: 8),
                Text(
                  'Preferred time: ${request.preferredDate} ${request.preferredTime ?? ''}',
                ),
              ],
            ],
          ),
        ),
        const SizedBox(height: 16),
        _jobSection(context, jobs),
        const SizedBox(height: 16),
        _surveySection(context, ref, request, surveys, appointments),
        const SizedBox(height: 16),
        Text('Quotations', style: Theme.of(context).textTheme.titleLarge),
        const SizedBox(height: 8),
        _quoteSection(context, ref, request.id, quotes),
      ],
    ),
  );

  Widget _jobSection(
    BuildContext context,
    AsyncValue<List<JobRecord>> jobs,
  ) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      Text('Work tracking', style: Theme.of(context).textTheme.titleLarge),
      const SizedBox(height: 8),
      jobs.when(
        loading: () => const LinearProgressIndicator(),
        error: (_, _) => const ContentCard(
          child: Text('Work progress is temporarily unavailable.'),
        ),
        data: (items) => items.isEmpty
            ? const ContentCard(
                child: Text(
                  'Job tracking will appear here after your request is approved and scheduled.',
                ),
              )
            : Column(
                children: [
                  for (final job in items) ...[
                    _JobProgressCard(job: job),
                    const SizedBox(height: 8),
                  ],
                ],
              ),
      ),
    ],
  );

  Widget _surveySection(
    BuildContext context,
    WidgetRef ref,
    RequestRecord request,
    AsyncValue<List<SurveyRecord>> surveys,
    AsyncValue<List<AppointmentRecord>> appointments,
  ) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      Row(
        children: [
          Expanded(
            child: Text(
              'Site surveys',
              style: Theme.of(context).textTheme.titleLarge,
            ),
          ),
          TextButton.icon(
            onPressed: () => _requestSurvey(context, ref, request.id),
            icon: const Icon(Icons.calendar_month_outlined),
            label: const Text('Request survey'),
          ),
        ],
      ),
      surveys.when(
        loading: () => const LinearProgressIndicator(),
        error: (_, _) => const Text('Survey status is unavailable.'),
        data: (items) => items.isEmpty
            ? const ContentCard(child: Text('No site survey requested.'))
            : Column(
                children: [
                  for (final survey in items)
                    ContentCard(
                      child: ListTile(
                        contentPadding: EdgeInsets.zero,
                        leading: const Icon(Icons.home_repair_service_outlined),
                        title: Text('Survey ${_statusLabel(survey.status)}'),
                        subtitle: Text(
                          survey.requestedAt == null
                              ? 'Waiting for FixPK to confirm a time.'
                              : 'Preferred ${MaterialLocalizations.of(context).formatMediumDate(survey.requestedAt!.toLocal())}',
                        ),
                      ),
                    ),
                ],
              ),
      ),
      const SizedBox(height: 8),
      appointments.when(
        loading: () => const SizedBox.shrink(),
        error: (_, _) => const Text('Appointment details are unavailable.'),
        data: (items) => Column(
          children: [
            for (final appointment in items)
              ContentCard(
                child: ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const Icon(Icons.event_available_outlined),
                  title: Text(
                    'Appointment ${_statusLabel(appointment.status)}',
                  ),
                  subtitle: Text(
                    appointment.startsAt == null
                        ? 'Time to be confirmed'
                        : '${MaterialLocalizations.of(context).formatFullDate(appointment.startsAt!.toLocal())} · ${TimeOfDay.fromDateTime(appointment.startsAt!.toLocal()).format(context)}',
                  ),
                ),
              ),
          ],
        ),
      ),
    ],
  );

  Widget _quoteSection(
    BuildContext context,
    WidgetRef ref,
    String requestId,
    AsyncValue<List<QuoteRecord>> quotes,
  ) => quotes.when(
    loading: () => const LinearProgressIndicator(),
    error: (_, _) => const AppStatePanel(
      title: 'Quotes could not load',
      message: 'Try refreshing the request details.',
      isError: true,
    ),
    data: (items) => items.isEmpty
        ? const ContentCard(
            child: Text('A FixPK quotation will appear here when it is ready.'),
          )
        : Column(
            children: [
              for (final quote in items) ...[
                _QuoteCard(
                  quote: quote,
                  onDecision: (decision) =>
                      _decideQuote(context, ref, requestId, quote, decision),
                ),
                const SizedBox(height: 12),
              ],
            ],
          ),
  );

  Future<void> _requestSurvey(
    BuildContext context,
    WidgetRef ref,
    String id,
  ) async {
    final chosenAt = await showDialog<DateTime>(
      context: context,
      builder: (dialogContext) => const _SurveyRequestDialog(),
    );
    if (chosenAt == null) return;
    final user = ref.read(authUserProvider).value;
    if (user == null) return;
    try {
      await ref
          .read(requestRepositoryProvider)
          .requestSurvey(requestId: id, preferredAt: chosenAt);
      ref.invalidate(surveyListProvider(id));
      ref.invalidate(customerRequestsProvider(user.id));
      ref.invalidate(
        requestDetailProvider((profileId: user.id, requestId: id)),
      );
      if (context.mounted) {
        _showMessage(
          context,
          'Survey request sent. FixPK will confirm the appointment.',
        );
      }
    } on Object {
      if (context.mounted) {
        _showMessage(
          context,
          'Could not request a site survey. Try again later.',
        );
      }
    }
  }

  Future<void> _decideQuote(
    BuildContext context,
    WidgetRef ref,
    String requestId,
    QuoteRecord quote,
    String decision,
  ) async {
    final note = await showDialog<String?>(
      context: context,
      builder: (dialogContext) => _QuoteDecisionDialog(decision: decision),
    );
    if (note == null) return;
    try {
      await ref
          .read(requestRepositoryProvider)
          .decideQuote(quoteId: quote.id, decision: decision, note: note);
      ref.invalidate(requestQuotesProvider(requestId));
      if (context.mounted) {
        _showMessage(context, switch (decision) {
          'accepted' => 'Quotation approved.',
          'rejected' => 'Quotation declined.',
          _ => 'Revision request sent to FixPK.',
        });
      }
    } on Object {
      if (context.mounted) {
        _showMessage(
          context,
          'Could not record your quotation decision. Refresh and try again.',
        );
      }
    }
  }
}

class _JobProgressCard extends StatelessWidget {
  const _JobProgressCard({required this.job});
  final JobRecord job;

  @override
  Widget build(BuildContext context) {
    final scheduled = job.scheduledStart?.toLocal();
    final isScheduled =
        job.status == 'scheduled' ||
        job.status == 'in_progress' ||
        job.status == 'completed';
    final isInProgress =
        job.status == 'in_progress' || job.status == 'completed';
    final isCompleted = job.status == 'completed';
    return ContentCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              const Expanded(child: Text('FixPK job')),
              StatusChip(
                label: _statusLabel(job.status),
                tone: _statusTone(job.status),
              ),
            ],
          ),
          if (job.status == 'cancelled') ...[
            const SizedBox(height: 12),
            const Text(
              'This scheduled job was cancelled. Contact FixPK for next steps.',
            ),
          ] else ...[
            const SizedBox(height: 16),
            _JobStage(
              title: 'Scheduled',
              complete: isScheduled,
              detail: scheduled == null
                  ? 'Time to be confirmed'
                  : '${MaterialLocalizations.of(context).formatMediumDate(scheduled)} · ${TimeOfDay.fromDateTime(scheduled).format(context)}',
            ),
            _JobStage(
              title: 'Work in progress',
              complete: isInProgress,
              detail: isInProgress
                  ? 'FixPK has started the job'
                  : 'Waiting to start',
            ),
            _JobStage(
              title: 'Completed',
              complete: isCompleted,
              detail: job.completedAt == null
                  ? (isCompleted ? 'Job marked complete' : 'Not completed yet')
                  : MaterialLocalizations.of(
                      context,
                    ).formatMediumDate(job.completedAt!.toLocal()),
              isLast: true,
            ),
            if (isCompleted) ...[
              const SizedBox(height: 12),
              AppButton(
                label: 'Review this job',
                kind: ActionKind.outline,
                icon: Icons.star_outline,
                onPressed: () => context.push(
                  '/account/reviews/new/${Uri.encodeComponent(job.id)}',
                ),
              ),
            ],
          ],
        ],
      ),
    );
  }
}

class _JobStage extends StatelessWidget {
  const _JobStage({
    required this.title,
    required this.complete,
    required this.detail,
    this.isLast = false,
  });

  final String title;
  final bool complete;
  final String detail;
  final bool isLast;

  @override
  Widget build(BuildContext context) => Row(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      SizedBox(
        width: 28,
        child: Column(
          children: [
            Icon(
              complete ? Icons.check_circle : Icons.circle_outlined,
              size: 20,
              color: complete ? Theme.of(context).colorScheme.primary : null,
            ),
            if (!isLast)
              Container(
                width: 2,
                height: 28,
                color: complete
                    ? Theme.of(context).colorScheme.primary
                    : Theme.of(context).dividerColor,
              ),
          ],
        ),
      ),
      const SizedBox(width: 8),
      Expanded(
        child: Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: const TextStyle(fontWeight: FontWeight.w600)),
              Text(detail, style: Theme.of(context).textTheme.bodySmall),
            ],
          ),
        ),
      ),
    ],
  );
}

class _QuoteCard extends StatelessWidget {
  const _QuoteCard({required this.quote, required this.onDecision});
  final QuoteRecord quote;
  final ValueChanged<String> onDecision;

  @override
  Widget build(BuildContext context) => ContentCard(
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                'Quote · Revision ${quote.revision}',
                style: Theme.of(context).textTheme.titleMedium,
              ),
            ),
            StatusChip(
              label: _statusLabel(quote.status),
              tone: _statusTone(quote.status),
            ),
          ],
        ),
        if (quote.validUntil != null) ...[
          const SizedBox(height: 8),
          Text(
            'Valid until ${MaterialLocalizations.of(context).formatMediumDate(quote.validUntil!.toLocal())}',
          ),
        ],
        const Divider(height: 24),
        for (final item in quote.items)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 5),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    '${item.description}\n${item.quantity} × ${_money(item.unitPrice, quote.currency)}',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                ),
                Text(
                  _money(item.lineTotal, quote.currency),
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
              ],
            ),
          ),
        const Divider(height: 24),
        _amountRow('Subtotal', quote.subtotal, quote.currency),
        _amountRow('Tax', quote.tax, quote.currency),
        const SizedBox(height: 6),
        _amountRow('Total', quote.total, quote.currency, emphasize: true),
        if (quote.customerDecisionNote.isNotEmpty) ...[
          const SizedBox(height: 12),
          Text('Your note: ${quote.customerDecisionNote}'),
        ],
        if (quote.isActionable) ...[
          const SizedBox(height: 16),
          AppButton(
            label: 'Approve quote',
            onPressed: () => onDecision('accepted'),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () => onDecision('revision_requested'),
                  child: const Text('Request revision'),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: TextButton(
                  onPressed: () => onDecision('rejected'),
                  child: const Text('Decline'),
                ),
              ),
            ],
          ),
        ],
      ],
    ),
  );

  Widget _amountRow(
    String label,
    num amount,
    String currency, {
    bool emphasize = false,
  }) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 3),
    child: Row(
      children: [
        Expanded(
          child: Text(
            label,
            style: TextStyle(
              fontWeight: emphasize ? FontWeight.w700 : FontWeight.normal,
            ),
          ),
        ),
        Text(
          _money(amount, currency),
          style: TextStyle(
            fontWeight: emphasize ? FontWeight.w700 : FontWeight.normal,
          ),
        ),
      ],
    ),
  );
}

class _SurveyRequestDialog extends StatefulWidget {
  const _SurveyRequestDialog();
  @override
  State<_SurveyRequestDialog> createState() => _SurveyRequestDialogState();
}

class _SurveyRequestDialogState extends State<_SurveyRequestDialog> {
  DateTime? _date;
  TimeOfDay? _time;

  @override
  Widget build(BuildContext context) => AlertDialog(
    title: const Text('Request a site survey'),
    content: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const Text(
          'Choose a preferred date and time. FixPK will confirm availability.',
        ),
        const SizedBox(height: 12),
        OutlinedButton.icon(
          onPressed: () async {
            final today = DateUtils.dateOnly(DateTime.now());
            final date = await showDatePicker(
              context: context,
              initialDate: today,
              firstDate: today,
              lastDate: DateTime(today.year + 1),
            );
            if (date != null) setState(() => _date = date);
          },
          icon: const Icon(Icons.calendar_month_outlined),
          label: Text(
            _date == null
                ? 'Choose a date'
                : MaterialLocalizations.of(context).formatMediumDate(_date!),
          ),
        ),
        DropdownButtonFormField<TimeOfDay>(
          initialValue: _time,
          decoration: const InputDecoration(labelText: 'Preferred time'),
          items:
              [
                    for (var hour = 9; hour <= 17; hour++)
                      TimeOfDay(hour: hour, minute: 0),
                  ]
                  .map(
                    (time) => DropdownMenuItem(
                      value: time,
                      child: Text(time.format(context)),
                    ),
                  )
                  .toList(),
          onChanged: (time) => setState(() => _time = time),
        ),
      ],
    ),
    actions: [
      TextButton(
        onPressed: () => Navigator.pop(context),
        child: const Text('Cancel'),
      ),
      FilledButton(
        onPressed: _date == null || _time == null
            ? null
            : () => Navigator.pop(
                context,
                DateTime(
                  _date!.year,
                  _date!.month,
                  _date!.day,
                  _time!.hour,
                  _time!.minute,
                ),
              ),
        child: const Text('Send request'),
      ),
    ],
  );
}

class _QuoteDecisionDialog extends StatefulWidget {
  const _QuoteDecisionDialog({required this.decision});
  final String decision;
  @override
  State<_QuoteDecisionDialog> createState() => _QuoteDecisionDialogState();
}

class _QuoteDecisionDialogState extends State<_QuoteDecisionDialog> {
  final _note = TextEditingController();
  @override
  void dispose() {
    _note.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AlertDialog(
    title: Text(switch (widget.decision) {
      'accepted' => 'Approve this quote?',
      'rejected' => 'Decline this quote?',
      _ => 'Request a quote revision',
    }),
    content: TextField(
      controller: _note,
      minLines: widget.decision == 'revision_requested' ? 2 : 1,
      maxLines: 4,
      decoration: InputDecoration(
        labelText: widget.decision == 'revision_requested'
            ? 'What should FixPK review?'
            : 'Note (optional)',
      ),
      onChanged: (_) => setState(() {}),
    ),
    actions: [
      TextButton(
        onPressed: () => Navigator.pop(context),
        child: const Text('Cancel'),
      ),
      FilledButton(
        onPressed:
            widget.decision == 'revision_requested' && _note.text.trim().isEmpty
            ? null
            : () => Navigator.pop(context, _note.text.trim()),
        child: const Text('Confirm'),
      ),
    ],
  );
}

String _money(num amount, String currency) =>
    '$currency ${amount.toStringAsFixed(2)}';

String _statusLabel(String status) => status
    .replaceAll('_', ' ')
    .split(' ')
    .map(
      (word) =>
          word.isEmpty ? word : '${word[0].toUpperCase()}${word.substring(1)}',
    )
    .join(' ');

StatusTone _statusTone(String status) => switch (status) {
  'accepted' ||
  'approved' ||
  'completed' ||
  'confirmed' ||
  'in_progress' => StatusTone.success,
  'rejected' || 'cancelled' || 'expired' => StatusTone.error,
  'sent' || 'quote_ready' || 'scheduled' => StatusTone.information,
  'draft' ||
  'requested' ||
  'submitted' ||
  'under_review' ||
  'quote_preparing' => StatusTone.warning,
  _ => StatusTone.neutral,
};

void _showMessage(BuildContext context, String message) {
  ScaffoldMessenger.of(context)
    ..hideCurrentSnackBar()
    ..showSnackBar(SnackBar(content: Text(message)));
}

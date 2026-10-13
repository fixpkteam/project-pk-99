import 'dart:typed_data';
import 'dart:async';

import 'package:uuid/uuid.dart';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/providers.dart';
import '../../../core/widgets/components.dart';
import '../../services/data/services_repository.dart';
import '../data/request_repository.dart';
import '../data/request_outbox.dart';
import '../data/outbox_providers.dart';

class RequestWizardPage extends ConsumerStatefulWidget {
  const RequestWizardPage({
    super.key,
    required this.serviceId,
    this.enquiryContext,
  });
  final String serviceId;
  final String? enquiryContext;

  @override
  ConsumerState<RequestWizardPage> createState() => _RequestWizardPageState();
}

class _RequestWizardPageState extends ConsumerState<RequestWizardPage> {
  final _notes = TextEditingController();
  final Map<String, dynamic> _answers = {};
  List<_SelectedAttachment> _files = [];
  String? _addressId;
  DateTime? _preferredDate;
  TimeOfDay? _preferredTime;
  int _step = 0;
  bool _submitting = false;
  final _submissionId = const Uuid().v4();
  bool _questionsLoaded = false;

  @override
  void initState() {
    super.initState();
    final contextNote = widget.enquiryContext?.trim();
    if (contextNote != null && contextNote.isNotEmpty) {
      _notes.text = contextNote;
    }
  }

  @override
  void dispose() {
    _notes.dispose();
    super.dispose();
  }

  void _initializeAnswers(List<ServiceQuestion> questions) {
    if (_questionsLoaded) return;
    _questionsLoaded = true;
    for (final question in questions) {
      if (question.inputType == 'multi_select') {
        _answers[question.id] = <String>[];
      }
    }
  }

  void _continue(
    List<ServiceQuestion> questions,
    List<CustomerAddress> addresses,
  ) {
    if (_submitting) return;
    if (_step == 0) {
      final invalidNumber = questions.where(
        (q) =>
            q.inputType == 'number' &&
            !_missingAnswer(_answers[q.id]) &&
            num.tryParse('${_answers[q.id]}') == null,
      );
      if (invalidNumber.isNotEmpty) {
        _showMessage('Enter a valid number for ${invalidNumber.first.label}.');
        return;
      }
      final missing = questions.where(
        (question) =>
            question.required && _missingAnswer(_answers[question.id]),
      );
      if (missing.isNotEmpty) {
        _showMessage(
          'Please answer: ${missing.map((item) => item.label).join(', ')}',
        );
        return;
      }
    }
    if (_step == 2) {
      if (addresses.isEmpty) {
        _showMessage('Add an address to continue.');
        return;
      }
      _addressId ??= addresses
          .firstWhere((item) => item.isDefault, orElse: () => addresses.first)
          .id;
    }
    if (_step < 4) {
      setState(() => _step++);
    } else {
      _submit(questions);
    }
  }

  bool _missingAnswer(dynamic value) {
    if (value == null) return true;
    if (value is String) return value.trim().isEmpty;
    if (value is List) return value.isEmpty;
    return false;
  }

  Future<void> _pickFiles() async {
    try {
      final result = await FilePicker.pickFiles(
        type: FileType.custom,
        allowedExtensions: const [
          'jpg',
          'jpeg',
          'png',
          'webp',
          'pdf',
          'doc',
          'docx',
          'xls',
          'xlsx',
        ],
        compressionQuality: 85,
      );
      if (result.isEmpty) return;
      if (_files.length + result.length > 5) {
        _showMessage('You can attach up to five files.');
        return;
      }
      final additions = <_SelectedAttachment>[];
      for (final file in result) {
        final size = await file.length();
        if (size == null) {
          _showMessage(
            '${file.name} could not be read. Try choosing it again.',
          );
          return;
        }
        if (size > 5 * 1024 * 1024) {
          _showMessage('${file.name} is larger than the 5 MB limit.');
          return;
        }
        additions.add(
          _SelectedAttachment(
            name: file.name,
            bytes: await file.readAsBytes(),
            byteSize: size,
          ),
        );
      }
      if (!mounted) return;
      final total = [
        ..._files,
        ...additions,
      ].fold<int>(0, (sum, f) => sum + f.byteSize);
      if (total > 20 * 1024 * 1024) {
        _showMessage('Keep attachments under 20 MB in total.');
        return;
      }
      setState(() => _files = [..._files, ...additions]);
    } on Object {
      _showMessage('Could not open the file picker. Try again.');
    }
  }

  String _contentType(String name) {
    final ext = name.split('.').last.toLowerCase();
    return switch (ext) {
      'jpg' || 'jpeg' => 'image/jpeg',
      'png' => 'image/png',
      'webp' => 'image/webp',
      'pdf' => 'application/pdf',
      'doc' => 'application/msword',
      'docx' => 'application/vnd.openxmlformats-officedocument.wordprocessingml.document',
      'xls' => 'application/vnd.ms-excel',
      'xlsx' =>
        'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet',
      _ => 'application/octet-stream',
    };
  }

  Future<void> _submit(List<ServiceQuestion> questions) async {
    if (_submitting) return;
    final user = ref.read(authUserProvider).value;
    if (user == null || _addressId == null) return;
    setState(() => _submitting = true);
    try {
      final files = <OutboxFile>[];
      final bytes = <String, Uint8List>{};
      for (final file in _files) {
        final id = const Uuid().v4();
        files.add(
          OutboxFile(
            id: id,
            name: file.name,
            contentType: _contentType(file.name),
            size: file.bytes.length,
          ),
        );
        bytes[id] = file.bytes;
      }
      final date = _preferredDate;
      final time = _preferredTime;
      final catalogue = ref.read(serviceCatalogueProvider).value;
      final names = catalogue?.services.where((s) => s.id == widget.serviceId);
      final request = QueuedRequest(
        id: _submissionId,
        ownerId: user.id,
        serviceId: widget.serviceId,
        serviceName: names?.isNotEmpty == true
            ? names!.first.name
            : 'Quote request',
        addressId: _addressId!,
        notes: _notes.text.trim(),
        answers: {
          for (final question in questions)
            if (!_missingAnswer(_answers[question.id]))
              question.id: _answers[question.id],
        },
        createdAt: DateTime.now().toUtc(),
        files: files,
        preferredDate: date == null
            ? null
            : '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}',
        preferredTime: date == null
            ? null
            : '${(time?.hour ?? 9).toString().padLeft(2, '0')}:${(time?.minute ?? 0).toString().padLeft(2, '0')}:00',
      );
      final outbox = ref.read(requestOutboxProvider);
      await outbox.enqueue(request, bytes);
      // Acknowledgement depends only on durable device storage, not the network.
      unawaited(outbox.sync(force: true).catchError((Object _) {}));
      if (mounted) {
        context.go('/requests/pending');
        _showMessage(offlineRequestMessage);
      }
    } on Object {
      _showMessage(
        'Your request could not be saved on this device. Check free storage and pending requests, then try again. Your form is still here.',
      );
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  Future<void> _chooseDate() async {
    final today = DateUtils.dateOnly(DateTime.now());
    final value = await showDatePicker(
      context: context,
      initialDate: _preferredDate ?? today,
      firstDate: today,
      lastDate: DateTime(today.year + 1, today.month, today.day),
    );
    if (value != null && mounted) setState(() => _preferredDate = value);
  }

  void _showMessage(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    final userState = ref.watch(authUserProvider);
    return Scaffold(
      appBar: AppBar(title: const Text('Request a service')),
      body: userState.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (_, _) =>
            const Center(child: Text('Account status could not be loaded.')),
        data: (user) {
          if (user == null) {
            final redirect = Uri.encodeComponent(
              '/requests/new?serviceId=${Uri.encodeComponent(widget.serviceId)}${widget.enquiryContext == null ? '' : '&context=${Uri.encodeQueryComponent(widget.enquiryContext!)}'}',
            );
            return AppStatePanel(
              title: 'Sign in to request a service',
              message: 'Your service details will be here when you return.',
              icon: Icons.lock_outline,
              actionLabel: 'Sign in',
              onAction: () => context.go('/sign-in?redirect=$redirect'),
            );
          }
          final catalogue = ref.watch(serviceCatalogueProvider);
          final questionsState = ref.watch(
            serviceQuestionsProvider(widget.serviceId),
          );
          final addressesState = ref.watch(customerAddressesProvider(user.id));
          return catalogue.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (_, _) =>
                const Center(child: Text('Service details could not load.')),
            data: (catalogueData) {
              final matchingServices = catalogueData.services.where(
                (item) => item.id == widget.serviceId,
              );
              if (matchingServices.isEmpty) {
                return const Center(
                  child: Text('This service is not available.'),
                );
              }
              final service = matchingServices.first;
              return questionsState.when(
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (_, _) => AppStatePanel(
                  title: 'Requirements could not load',
                  message: 'Try again to load this service request form.',
                  isError: true,
                  actionLabel: 'Retry',
                  onAction: () => ref.invalidate(
                    serviceQuestionsProvider(widget.serviceId),
                  ),
                ),
                data: (questions) {
                  _initializeAnswers(questions);
                  return addressesState.when(
                    loading: () =>
                        const Center(child: CircularProgressIndicator()),
                    error: (_, _) => AppStatePanel(
                      title: 'Addresses could not load',
                      message: 'Check your connection and try again.',
                      isError: true,
                      actionLabel: 'Retry',
                      onAction: () =>
                          ref.invalidate(customerAddressesProvider(user.id)),
                    ),
                    data: (addresses) =>
                        _buildStepper(service, questions, addresses),
                  );
                },
              );
            },
          );
        },
      ),
    );
  }

  Widget _buildStepper(
    ServiceItem service,
    List<ServiceQuestion> questions,
    List<CustomerAddress> addresses,
  ) => Stepper(
    currentStep: _step,
    onStepTapped: (step) {
      if (!_submitting && step <= _step) setState(() => _step = step);
    },
    onStepContinue: () => _continue(questions, addresses),
    onStepCancel: _step == 0 ? null : () => setState(() => _step--),
    controlsBuilder: (context, details) => Padding(
      padding: const EdgeInsets.only(top: 16),
      child: Row(
        children: [
          Expanded(
            child: AppButton(
              key: ValueKey('request-continue-${details.stepIndex}'),
              label: details.stepIndex == 4 ? 'Submit request' : 'Continue',
              busy: details.isActive && _submitting,
              onPressed: _submitting || !details.isActive
                  ? null
                  : details.onStepContinue,
            ),
          ),
          if (details.stepIndex > 0) ...[
            const SizedBox(width: 12),
            TextButton(
              onPressed: _submitting || !details.isActive
                  ? null
                  : details.onStepCancel,
              child: const Text('Back'),
            ),
          ],
        ],
      ),
    ),
    steps: [
      Step(
        title: const Text('Requirements'),
        isActive: _step >= 0,
        content: _requirements(questions),
      ),
      Step(
        title: const Text('Attachments'),
        isActive: _step >= 1,
        content: _attachments(),
      ),
      Step(
        title: const Text('Address'),
        isActive: _step >= 2,
        content: _addressStep(addresses),
      ),
      Step(
        title: const Text('Schedule'),
        isActive: _step >= 3,
        content: _schedule(),
      ),
      Step(
        title: const Text('Review'),
        isActive: _step >= 4,
        content: _review(service, questions, addresses),
      ),
    ],
  );

  Widget _requirements(List<ServiceQuestion> questions) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      for (final question in questions) ...[
        _questionInput(question),
        if (question.helpText.isNotEmpty) ...[
          const SizedBox(height: 4),
          Align(
            alignment: Alignment.centerLeft,
            child: Text(
              question.helpText,
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ),
        ],
        const SizedBox(height: 16),
      ],
      if (questions.isEmpty)
        const Text('No extra details are required for this service.'),
      TextField(
        controller: _notes,
        minLines: 3,
        maxLines: 5,
        maxLength: 5000,
        textCapitalization: TextCapitalization.sentences,
        decoration: const InputDecoration(
          labelText: 'Additional notes (optional)',
          alignLabelWithHint: true,
        ),
      ),
    ],
  );

  Widget _questionInput(ServiceQuestion question) {
    final value = _answers[question.id];
    final label = question.required ? '${question.label} *' : question.label;
    switch (question.inputType) {
      case 'textarea':
        return TextFormField(
          initialValue: value as String?,
          minLines: 3,
          maxLines: 5,
          textCapitalization: TextCapitalization.sentences,
          decoration: InputDecoration(labelText: label),
          onChanged: (answer) => _answers[question.id] = answer,
        );
      case 'number':
        return TextFormField(
          initialValue: value?.toString(),
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          decoration: InputDecoration(labelText: label),
          onChanged: (answer) => _answers[question.id] = answer,
        );
      case 'single_select':
        return DropdownButtonFormField<String>(
          initialValue: value as String?,
          decoration: InputDecoration(labelText: label),
          items: question.options
              .map(
                (option) => DropdownMenuItem(
                  value: option.value,
                  child: Text(option.label),
                ),
              )
              .toList(),
          onChanged: (answer) => setState(() => _answers[question.id] = answer),
        );
      case 'multi_select':
        final selected = (value as List<String>? ?? const <String>[]).toSet();
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: Theme.of(context).textTheme.titleSmall),
            for (final option in question.options)
              CheckboxListTile(
                value: selected.contains(option.value),
                title: Text(option.label),
                contentPadding: EdgeInsets.zero,
                controlAffinity: ListTileControlAffinity.leading,
                onChanged: (checked) => setState(() {
                  final next = selected.toSet();
                  if (checked == true) {
                    next.add(option.value);
                  } else {
                    next.remove(option.value);
                  }
                  _answers[question.id] = next.toList();
                }),
              ),
          ],
        );
      case 'boolean':
        return DropdownButtonFormField<bool>(
          initialValue: value as bool?,
          decoration: InputDecoration(labelText: label),
          items: const [
            DropdownMenuItem(value: true, child: Text('Yes')),
            DropdownMenuItem(value: false, child: Text('No')),
          ],
          onChanged: (answer) => setState(() => _answers[question.id] = answer),
        );
      case 'date':
        return ListTile(
          contentPadding: EdgeInsets.zero,
          title: Text(label),
          subtitle: Text(value?.toString() ?? 'Choose a date'),
          trailing: const Icon(Icons.calendar_month_outlined),
          onTap: () async {
            final today = DateUtils.dateOnly(DateTime.now());
            final picked = await showDatePicker(
              context: context,
              initialDate: today,
              firstDate: DateTime(today.year - 10),
              lastDate: DateTime(today.year + 10),
            );
            if (picked != null && mounted) {
              setState(
                () => _answers[question.id] =
                    '${picked.year.toString().padLeft(4, '0')}-${picked.month.toString().padLeft(2, '0')}-${picked.day.toString().padLeft(2, '0')}',
              );
            }
          },
        );
      default:
        return TextFormField(
          initialValue: value as String?,
          textCapitalization: TextCapitalization.sentences,
          decoration: InputDecoration(labelText: label),
          onChanged: (answer) => _answers[question.id] = answer,
        );
    }
  }

  Widget _attachments() => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      const Text(
        'Attach up to 5 photos or documents, up to 5 MB each and 20 MB in total.',
      ),
      const SizedBox(height: 12),
      OutlinedButton.icon(
        onPressed: _pickFiles,
        icon: const Icon(Icons.attach_file),
        label: const Text('Choose files'),
      ),
      for (final file in _files)
        ListTile(
          contentPadding: EdgeInsets.zero,
          leading: const Icon(Icons.insert_drive_file_outlined),
          title: Text(file.name, maxLines: 1, overflow: TextOverflow.ellipsis),
          subtitle: Text(
            '${(file.byteSize / (1024 * 1024)).toStringAsFixed(1)} MB',
          ),
          trailing: IconButton(
            tooltip: 'Remove attachment',
            icon: const Icon(Icons.close),
            onPressed: () => setState(() => _files.remove(file)),
          ),
        ),
      if (_files.isEmpty) const Text('No attachments selected.'),
    ],
  );

  Widget _addressStep(List<CustomerAddress> addresses) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      if (addresses.isEmpty)
        AppStatePanel(
          title: 'Add a service address',
          message: 'We need the property location to coordinate your request.',
          icon: Icons.location_on_outlined,
          actionLabel: 'Add address',
          onAction: () async {
            await context.push<void>('/account/addresses');
            final user = ref.read(authUserProvider).value;
            if (user != null) {
              ref.invalidate(customerAddressesProvider(user.id));
            }
          },
        )
      else ...[
        DropdownButtonFormField<String>(
          initialValue:
              _addressId ??
              addresses
                  .firstWhere(
                    (item) => item.isDefault,
                    orElse: () => addresses.first,
                  )
                  .id,
          decoration: const InputDecoration(labelText: 'Service address'),
          items: [
            for (final address in addresses)
              DropdownMenuItem(
                value: address.id,
                child: Text(
                  '${address.label}${address.isDefault ? ' · Default' : ''}',
                ),
              ),
          ],
          onChanged: (value) => setState(() => _addressId = value),
        ),
        const SizedBox(height: 8),
        Builder(
          builder: (context) {
            final selectedId =
                _addressId ??
                addresses
                    .firstWhere(
                      (item) => item.isDefault,
                      orElse: () => addresses.first,
                    )
                    .id;
            final selected = addresses.firstWhere(
              (item) => item.id == selectedId,
              orElse: () => addresses.first,
            );
            return ContentCard(
              child: ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const Icon(Icons.location_on_outlined),
                title: Text(selected.displayAddress),
                subtitle: Text('${selected.recipientName} · ${selected.phone}'),
              ),
            );
          },
        ),
        Align(
          alignment: Alignment.centerLeft,
          child: TextButton.icon(
            onPressed: () async {
              await context.push<void>('/account/addresses');
              final user = ref.read(authUserProvider).value;
              if (user != null) {
                ref.invalidate(customerAddressesProvider(user.id));
              }
            },
            icon: const Icon(Icons.add),
            label: const Text('Manage addresses'),
          ),
        ),
      ],
    ],
  );

  Widget _schedule() => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      const Text(
        'Share a preferred time for FixPK to contact you. The team will confirm availability.',
      ),
      const SizedBox(height: 16),
      OutlinedButton.icon(
        onPressed: _chooseDate,
        icon: const Icon(Icons.calendar_month_outlined),
        label: Text(
          _preferredDate == null
              ? 'Choose preferred date (optional)'
              : MaterialLocalizations.of(context)
                    .formatMediumDate(_preferredDate!),
        ),
      ),
      const SizedBox(height: 12),
      DropdownButtonFormField<TimeOfDay>(
        initialValue: _preferredTime,
        decoration: const InputDecoration(
          labelText: 'Preferred time (optional)',
        ),
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
        onChanged: (value) => setState(() => _preferredTime = value),
      ),
      const SizedBox(height: 12),
      TextButton(
        onPressed: () => setState(() {
          _preferredDate = null;
          _preferredTime = null;
        }),
        child: const Text('Clear preferred time'),
      ),
    ],
  );

  Widget _review(
    ServiceItem service,
    List<ServiceQuestion> questions,
    List<CustomerAddress> addresses,
  ) {
    final addressId =
        _addressId ??
        (addresses.isEmpty
            ? null
            : addresses
                  .firstWhere(
                    (item) => item.isDefault,
                    orElse: () => addresses.first,
                  )
                  .id);
    CustomerAddress? address;
    for (final item in addresses) {
      if (item.id == addressId) {
        address = item;
        break;
      }
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(service.name, style: Theme.of(context).textTheme.titleLarge),
        const SizedBox(height: 12),
        for (final question in questions)
          if (!_missingAnswer(_answers[question.id]))
            ListTile(
              contentPadding: EdgeInsets.zero,
              title: Text(question.label),
              subtitle: Text(_answerLabel(_answers[question.id])),
            ),
        const Divider(),
        Text('Address', style: Theme.of(context).textTheme.titleMedium),
        Text(
          address?.displayAddress ?? 'Select an address in the previous step.',
        ),
        const SizedBox(height: 8),
        Text('Attachments: ${_files.length}'),
        const SizedBox(height: 8),
        Text(
          'Preferred date: ${_preferredDate == null ? 'Not specified' : MaterialLocalizations.of(context).formatMediumDate(_preferredDate!)}',
        ),
        Text(
          'Preferred time: ${_preferredTime?.format(context) ?? 'Not specified'}',
        ),
        if (_notes.text.trim().isNotEmpty) ...[
          const SizedBox(height: 8),
          Text('Notes: ${_notes.text.trim()}'),
        ],
        const SizedBox(height: 12),
        const Text(
          'FixPK will review your requirements and contact you about next steps.',
        ),
      ],
    );
  }

  String _answerLabel(dynamic value) {
    if (value is List) return value.join(', ');
    return '$value';
  }
}

class _SelectedAttachment {
  const _SelectedAttachment({
    required this.name,
    required this.bytes,
    required this.byteSize,
  });

  final String name;
  final Uint8List bytes;
  final int byteSize;
}

import 'package:flutter/material.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/components.dart';
import 'foundation_pages.dart';

class ComponentGallery extends StatefulWidget {
  const ComponentGallery({super.key});
  @override
  State<ComponentGallery> createState() => _ComponentGalleryState();
}

class _ComponentGalleryState extends State<ComponentGallery> {
  final _form = GlobalKey<FormState>();
  String _property = 'Residential';
  DateTime? _date;
  String? _file;

  Widget _heading(String text) => Padding(
    padding: const EdgeInsets.only(top: 24, bottom: 12),
    child: Text(text, style: Theme.of(context).textTheme.titleLarge),
  );

  Future<void> _selectDate() async {
    final now = DateUtils.dateOnly(DateTime.now());
    final date = await showDatePicker(
      context: context,
      initialDate: _date ?? now,
      firstDate: now,
      lastDate: now.add(const Duration(days: 90)),
    );
    if (mounted && date != null) setState(() => _date = date);
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Component gallery')),
    body: SafeArea(
      child: PageBody(
        children: [
          const StatusChip(
            label: 'Interactive examples',
            tone: StatusTone.neutral,
          ),
          const SizedBox(height: 12),
          const Text(
            'Sample content below demonstrates components. No request, quote or file is sent.',
          ),
          _heading('Brand and typography'),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final (name, color) in [
                ('Navy', FixPkColors.navy),
                ('Action blue', FixPkColors.action),
                ('Accent blue', FixPkColors.blue),
              ])
                Column(
                  children: [
                    Container(
                      width: 72,
                      height: 40,
                      decoration: BoxDecoration(
                        color: color,
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(name),
                  ],
                ),
            ],
          ),
          const SizedBox(height: 20),
          Text(
            'Built to Last.',
            style: Theme.of(context).textTheme.displaySmall,
          ),
          const SizedBox(height: 8),
          const Text(
            'Readable text, generous touch targets and a consistent spacing scale.',
          ),
          _heading('Actions'),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final kind in ActionKind.values)
                AppButton(
                  label: switch (kind) {
                    ActionKind.primary => 'Primary',
                    ActionKind.secondary => 'Secondary',
                    ActionKind.outline => 'Outline',
                    ActionKind.text => 'Text action',
                  },
                  kind: kind,
                  onPressed: () =>
                      showFeedback(context, 'Action preview selected.'),
                ),
              const AppButton(label: 'Unavailable', onPressed: null),
              const AppButton(label: 'Saving', onPressed: null, busy: true),
            ],
          ),
          _heading('Status'),
          const Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              StatusChip(label: 'Quote ready'),
              StatusChip(label: 'Completed', tone: StatusTone.success),
              StatusChip(label: 'Under review', tone: StatusTone.warning),
              StatusChip(label: 'Action needed', tone: StatusTone.error),
              StatusChip(label: 'On hold', tone: StatusTone.neutral),
            ],
          ),
          _heading('Forms'),
          Form(
            key: _form,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                TextFormField(
                  decoration: const InputDecoration(
                    labelText: 'Your name',
                    helperText: 'Required · example field only',
                  ),
                  textCapitalization: TextCapitalization.words,
                  autofillHints: const [AutofillHints.name],
                  validator: (value) => value == null || value.trim().isEmpty
                      ? 'Enter your name.'
                      : null,
                ),
                const SizedBox(height: 20),
                DropdownButtonFormField<String>(
                  initialValue: _property,
                  decoration: const InputDecoration(labelText: 'Property type'),
                  isExpanded: true,
                  items: [
                    for (final value in [
                      'Residential',
                      'Commercial',
                      'Industrial',
                    ])
                      DropdownMenuItem(value: value, child: Text(value)),
                  ],
                  onChanged: (value) {
                    if (value != null) setState(() => _property = value);
                  },
                ),
                const SizedBox(height: 16),
                AppButton(
                  label: _date == null
                      ? 'Choose preferred date'
                      : 'Preferred: ${MaterialLocalizations.of(context).formatMediumDate(_date!)}',
                  icon: Icons.calendar_month_outlined,
                  kind: ActionKind.outline,
                  onPressed: _selectDate,
                ),
                const SizedBox(height: 12),
                const Text(
                  'A date selection is a preference, not a confirmed appointment.',
                ),
                const SizedBox(height: 16),
                AppButton(
                  label: 'Validate example',
                  onPressed: () {
                    if (_form.currentState!.validate()) {
                      showFeedback(
                        context,
                        'Example valid. Nothing was submitted.',
                      );
                    }
                  },
                ),
              ],
            ),
          ),
          _heading('Upload control'),
          UploadControl(
            filename: _file,
            onSelect: () {
              setState(() => _file = 'example-site-photo.jpg (sample)');
              showFeedback(
                context,
                'Sample selection only. File access is added in Phase 4.',
              );
            },
            onRemove: () => setState(() => _file = null),
          ),
          _heading('Service card'),
          ServiceCard(
            title: 'Solar Solutions',
            subtitle: 'Residential and commercial',
            icon: Icons.solar_power_outlined,
            onTap: () => showFeedback(context, 'Service card preview.'),
          ),
          _heading('Request card'),
          SummaryCard(
            title: 'Solar assessment',
            subtitle: 'Sample request · Islamabad',
            status: const StatusChip(
              label: 'Under review',
              tone: StatusTone.warning,
            ),
            onTap: () => showFeedback(context, 'Sample request only.'),
          ),
          _heading('Quote card'),
          SummaryCard(
            title: 'Installation quotation',
            subtitle: 'Example layout · pricing will come from FixPK',
            status: const StatusChip(label: 'Quote ready'),
            onTap: () => showFeedback(context, 'Sample quote only.'),
          ),
          _heading('Product card'),
          MediaCard(
            title: 'Solar geyser',
            subtitle: 'Specifications and pricing pending verification.',
            action: 'View sample details',
            onTap: () => showFeedback(context, 'Product card preview.'),
          ),
          _heading('Project card'),
          MediaCard(
            title: 'Solar installation',
            subtitle: 'Approved project photography will appear here.',
            action: 'View sample project',
            onTap: () => showFeedback(context, 'Project card preview.'),
          ),
          _heading('Feedback and overlays'),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              AppButton(
                label: 'Open dialog',
                kind: ActionKind.outline,
                onPressed: () async {
                  final confirmed = await showConfirmation(
                    context,
                    title: 'Discard this example?',
                    message: 'This demonstrates a confirmation dialog. No customer data is affected.',
                    confirmLabel: 'Discard example',
                  );
                  if (context.mounted && confirmed) {
                    showFeedback(context, 'Example discarded.');
                  }
                },
              ),
              AppButton(
                label: 'Open sheet',
                kind: ActionKind.outline,
                onPressed: () => showModalBottomSheet<void>(
                  context: context,
                  useSafeArea: true,
                  isScrollControlled: true,
                  builder: (context) => SingleChildScrollView(
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Text(
                            'Select an option',
                            style: Theme.of(context).textTheme.titleLarge,
                          ),
                          const SizedBox(height: 16),
                          for (final option in ['Home', 'Office', 'Site'])
                            ListTile(
                              title: Text(option),
                              trailing: const Icon(Icons.chevron_right),
                              onTap: () {
                                Navigator.pop(context);
                                showFeedback(
                                  this.context,
                                  '$option selected in example.',
                                );
                              },
                            ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
              AppButton(
                label: 'Show snackbar',
                kind: ActionKind.text,
                onPressed: () =>
                    showFeedback(context, 'Your example action is complete.'),
              ),
            ],
          ),
          _heading('Loading'),
          const SkeletonCard(),
          _heading('Empty state'),
          const AppStatePanel(
            title: 'No requests yet',
            message: 'Your requests will appear here after submission.',
            icon: Icons.assignment_outlined,
          ),
          _heading('Error state'),
          AppStatePanel(
            title: 'Unable to load this example',
            message: 'Your information is safe. Try again.',
            icon: Icons.cloud_off_outlined,
            isError: true,
            actionLabel: 'Retry example',
            onAction: () => showFeedback(context, 'Retry action selected.'),
          ),
        ],
      ),
    ),
  );
}

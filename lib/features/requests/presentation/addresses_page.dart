import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/providers.dart';
import '../../../core/widgets/components.dart';
import '../data/request_repository.dart';

class AddressesPage extends ConsumerWidget {
  const AddressesPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(authUserProvider).value;
    if (user == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Saved addresses')),
        body: const Center(child: Text('Sign in to manage your addresses.')),
      );
    }
    final addresses = ref.watch(customerAddressesProvider(user.id));
    return Scaffold(
      appBar: AppBar(title: const Text('Saved addresses')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _openEditor(context, ref),
        icon: const Icon(Icons.add),
        label: const Text('Add address'),
      ),
      body: SafeArea(
        child: addresses.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (_, _) => AppStatePanel(
            title: 'Addresses could not load',
            message: 'Check your connection and try again.',
            isError: true,
            actionLabel: 'Retry',
            onAction: () => ref.invalidate(customerAddressesProvider(user.id)),
          ),
          data: (items) => items.isEmpty
              ? AppStatePanel(
                  title: 'No saved addresses yet',
                  message:
                      'Add an address so it is ready when you request a service.',
                  icon: Icons.location_on_outlined,
                  actionLabel: 'Add address',
                  onAction: () => _openEditor(context, ref),
                )
              : ListView.separated(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 96),
                  itemCount: items.length,
                  separatorBuilder: (_, _) => const SizedBox(height: 12),
                  itemBuilder: (context, index) {
                    final address = items[index];
                    return ContentCard(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: Text(
                                  address.label,
                                  style: Theme.of(
                                    context,
                                  ).textTheme.titleMedium,
                                ),
                              ),
                              if (address.isDefault)
                                const StatusChip(
                                  label: 'Default',
                                  tone: StatusTone.success,
                                ),
                              PopupMenuButton<String>(
                                tooltip: 'Address actions',
                                onSelected: (action) async {
                                  if (action == 'edit') {
                                    await _openEditor(
                                      context,
                                      ref,
                                      address: address,
                                    );
                                  } else if (action == 'delete') {
                                    final confirmed = await showDialog<bool>(
                                      context: context,
                                      builder: (dialogContext) => AlertDialog(
                                        title: const Text(
                                          'Delete this address?',
                                        ),
                                        content: const Text(
                                          'This address will no longer be available for new requests.',
                                        ),
                                        actions: [
                                          TextButton(
                                            onPressed: () => Navigator.pop(
                                              dialogContext,
                                              false,
                                            ),
                                            child: const Text('Cancel'),
                                          ),
                                          FilledButton(
                                            onPressed: () => Navigator.pop(
                                              dialogContext,
                                              true,
                                            ),
                                            child: const Text('Delete'),
                                          ),
                                        ],
                                      ),
                                    );
                                    if (confirmed == true) {
                                      try {
                                        await ref
                                            .read(requestRepositoryProvider)
                                            .deleteAddress(user.id, address.id);
                                        ref.invalidate(
                                          customerAddressesProvider(user.id),
                                        );
                                      } on Object {
                                        if (context.mounted) {
                                          _showMessage(
                                            context,
                                            'Could not delete this address.',
                                          );
                                        }
                                      }
                                    }
                                  }
                                },
                                itemBuilder: (context) => const [
                                  PopupMenuItem(
                                    value: 'edit',
                                    child: Text('Edit'),
                                  ),
                                  PopupMenuItem(
                                    value: 'delete',
                                    child: Text('Delete'),
                                  ),
                                ],
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Text(address.recipientName),
                          Text(address.displayAddress),
                          Text(address.phone),
                        ],
                      ),
                    );
                  },
                ),
        ),
      ),
    );
  }

  Future<void> _openEditor(
    BuildContext context,
    WidgetRef ref, {
    CustomerAddress? address,
  }) async {
    await context.push<void>('/account/addresses/edit', extra: address);
    // The editor owns persistence and invalidates after saving. The push is
    // kept as a separate route so Android back always cancels cleanly.
  }
}

class AddressEditorPage extends ConsumerStatefulWidget {
  const AddressEditorPage({super.key, this.address});
  final CustomerAddress? address;

  @override
  ConsumerState<AddressEditorPage> createState() => _AddressEditorPageState();
}

class _AddressEditorPageState extends ConsumerState<AddressEditorPage> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _label;
  late final TextEditingController _recipient;
  late final TextEditingController _phone;
  late final TextEditingController _line;
  late final TextEditingController _area;
  late final TextEditingController _city;
  late final TextEditingController _province;
  late final TextEditingController _postal;
  late bool _isDefault;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    final address = widget.address;
    _label = TextEditingController(text: address?.label ?? 'Home');
    _recipient = TextEditingController(text: address?.recipientName ?? '');
    _phone = TextEditingController(text: address?.phone ?? '');
    _line = TextEditingController(text: address?.addressLine ?? '');
    _area = TextEditingController(text: address?.area ?? '');
    _city = TextEditingController(text: address?.city ?? '');
    _province = TextEditingController(text: address?.province ?? '');
    _postal = TextEditingController(text: address?.postalCode ?? '');
    _isDefault = address?.isDefault ?? false;
  }

  @override
  void dispose() {
    _label.dispose();
    _recipient.dispose();
    _phone.dispose();
    _line.dispose();
    _area.dispose();
    _city.dispose();
    _province.dispose();
    _postal.dispose();
    super.dispose();
  }

  String? _required(String? value, String field) =>
      value == null || value.trim().isEmpty ? 'Enter $field.' : null;

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    final user = ref.read(authUserProvider).value;
    if (user == null) return;
    setState(() => _saving = true);
    try {
      await ref
          .read(requestRepositoryProvider)
          .saveAddress(
            profileId: user.id,
            label: _label.text,
            recipientName: _recipient.text,
            phone: _phone.text,
            addressLine: _line.text,
            area: _area.text,
            city: _city.text,
            province: _province.text,
            postalCode: _postal.text,
            makeDefault: _isDefault,
            addressId: widget.address?.id,
          );
      ref.invalidate(customerAddressesProvider(user.id));
      if (mounted) context.pop();
    } catch (_) {
      if (mounted) {
        _showMessage(
          context,
          'Could not save this address. Check your connection.',
        );
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      title: Text(widget.address == null ? 'Add address' : 'Edit address'),
    ),
    body: SafeArea(
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 640),
          child: Form(
            key: _formKey,
            child: ListView(
              padding: const EdgeInsets.all(20),
              children: [
                TextFormField(
                  controller: _label,
                  decoration: const InputDecoration(labelText: 'Address label'),
                  validator: (value) => _required(value, 'a label'),
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _recipient,
                  textCapitalization: TextCapitalization.words,
                  decoration: const InputDecoration(
                    labelText: 'Recipient name',
                  ),
                  validator: (value) => _required(value, 'a recipient name'),
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _phone,
                  keyboardType: TextInputType.phone,
                  decoration: const InputDecoration(labelText: 'Phone number'),
                  validator: (value) => _required(value, 'a phone number'),
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _line,
                  textCapitalization: TextCapitalization.sentences,
                  decoration: const InputDecoration(
                    labelText: 'House, street and building',
                  ),
                  validator: (value) => _required(value, 'an address'),
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _area,
                  textCapitalization: TextCapitalization.words,
                  decoration: const InputDecoration(labelText: 'Area / sector'),
                  validator: (value) => _required(value, 'an area'),
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _city,
                  textCapitalization: TextCapitalization.words,
                  decoration: const InputDecoration(labelText: 'City'),
                  validator: (value) => _required(value, 'a city'),
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _province,
                  textCapitalization: TextCapitalization.words,
                  decoration: const InputDecoration(
                    labelText: 'Province / territory',
                  ),
                  validator: (value) => _required(value, 'a province'),
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _postal,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: 'Postal code (optional)',
                  ),
                ),
                const SizedBox(height: 8),
                SwitchListTile.adaptive(
                  title: const Text('Make this my default address'),
                  value: _isDefault,
                  onChanged: _saving
                      ? null
                      : (value) => setState(() => _isDefault = value),
                  contentPadding: EdgeInsets.zero,
                ),
                const SizedBox(height: 16),
                AppButton(
                  label: 'Save address',
                  busy: _saving,
                  onPressed: _saving ? null : _save,
                ),
              ],
            ),
          ),
        ),
      ),
    ),
  );
}

void _showMessage(BuildContext context, String message) {
  ScaffoldMessenger.of(context)
    ..hideCurrentSnackBar()
    ..showSnackBar(SnackBar(content: Text(message)));
}

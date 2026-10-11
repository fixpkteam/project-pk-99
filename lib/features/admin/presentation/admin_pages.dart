import 'dart:convert';

import 'package:file_picker/file_picker.dart';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/providers.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/components.dart';
import '../../care/data/care_repository.dart';
import '../data/admin_repository.dart';

class AdminGate extends ConsumerWidget {
  const AdminGate({super.key, required this.child});
  final Widget child;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userState = ref.watch(authUserProvider);
    return userState.when(
      loading: () =>
          const Scaffold(body: Center(child: CircularProgressIndicator())),
      error: (_, _) => const Scaffold(
        body: AppStatePanel(
          title: 'Admin access could not be checked',
          message: 'Check your connection and try again.',
          isError: true,
        ),
      ),
      data: (user) {
        if (user == null) {
          return Scaffold(
            appBar: AppBar(title: const Text('FixPK admin')),
            body: AppStatePanel(
              title: 'Admin sign-in required',
              message: 'Sign in with an account that has the FixPK admin role.',
              icon: Icons.lock_outline,
              actionLabel: 'Sign in',
              onAction: () => context.go('/sign-in?redirect=%2Fadmin'),
            ),
          );
        }
        final roles = ref.watch(staffRoleListProvider(user.id));
        return roles.when(
          loading: () =>
              const Scaffold(body: Center(child: CircularProgressIndicator())),
          error: (_, _) => const Scaffold(
            body: AppStatePanel(
              title: 'Admin access could not be verified',
              message:
                  'Try again. Supabase policies remain the security boundary.',
              isError: true,
            ),
          ),
          data: (items) => items.any((item) => item.role == 'admin')
              ? child
              : Scaffold(
                  appBar: AppBar(title: Text('FixPK admin')),
                  body: AppStatePanel(
                    title: 'Admin access required',
                    message: 'This account does not have the FixPK admin role.',
                    icon: Icons.lock_outline,
                  ),
                ),
        );
      },
    );
  }
}

class AdminConsolePage extends StatelessWidget {
  const AdminConsolePage({super.key});

  @override
  Widget build(BuildContext context) => AdminGate(
    child: Scaffold(
      appBar: AppBar(title: const Text('Admin panel')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: FixPkColors.navy,
              borderRadius: BorderRadius.circular(18),
            ),
            child: const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(Icons.admin_panel_settings_outlined, color: Colors.white),
                SizedBox(height: 12),
                Text(
                  'FixPK control center',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                SizedBox(height: 6),
                Text(
                  'Manage customer accounts, service and product catalogues, projects, and app content.',
                  style: TextStyle(color: Colors.white70, height: 1.45),
                ),
              ],
            ),
          ),
          const SizedBox(height: 22),
          Text('Management', style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 10),
          _AdminLink(
            icon: Icons.people_alt_outlined,
            title: 'Users and staff access',
            subtitle: 'Review accounts, staff roles, and sign-in access.',
            onTap: () => context.push('/admin/users'),
          ),
          for (final table in adminContentTables)
            _AdminLink(
              icon: _tableIcon(table.key),
              title: table.label,
              subtitle:
                  table.description ?? 'Add, edit, publish, or remove records.',
              onTap: () => context.push('/admin/table/${table.key}'),
            ),
          const SizedBox(height: 14),
          Text('Operations', style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 10),
          _AdminLink(
            icon: Icons.support_agent_outlined,
            title: 'Requests and service operations',
            subtitle: 'Open job, support, and review queues.',
            onTap: () => context.push('/staff'),
          ),
        ],
      ),
    ),
  );
}

class _AdminLink extends StatelessWidget {
  const _AdminLink({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 8),
    child: ContentCard(
      onTap: onTap,
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: FixPkColors.informationSurface,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: FixPkColors.action),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: Theme.of(context).textTheme.titleMedium),
                const SizedBox(height: 3),
                Text(subtitle, style: Theme.of(context).textTheme.bodySmall),
              ],
            ),
          ),
          const Icon(Icons.chevron_right),
        ],
      ),
    ),
  );
}

IconData _tableIcon(String key) => switch (key) {
  'service-categories' ||
  'services' ||
  'service-questions' ||
  'service-question-options' => Icons.handyman_outlined,
  'product-categories' ||
  'products' ||
  'product-images' ||
  'product-specifications' => Icons.inventory_2_outlined,
  'projects' || 'project-images' => Icons.apartment_outlined,
  'faq' => Icons.quiz_outlined,
  _ => Icons.web_asset_outlined,
};

class AdminContentPage extends ConsumerWidget {
  const AdminContentPage({super.key, required this.tableKey});
  final String tableKey;

  @override
  Widget build(BuildContext context, WidgetRef ref) =>
      AdminGate(child: _AdminContentList(tableKey: tableKey));
}

class _AdminContentList extends ConsumerStatefulWidget {
  const _AdminContentList({required this.tableKey});
  final String tableKey;
  @override
  ConsumerState<_AdminContentList> createState() => _AdminContentListState();
}

class _AdminContentListState extends ConsumerState<_AdminContentList> {
  @override
  Widget build(BuildContext context) {
    final tableKey = widget.tableKey;
    final table = adminTableByKey(tableKey);
    if (table == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Content manager')),
        body: const AppStatePanel(
          title: 'Section not found',
          message: 'Return to the admin panel and select a supported section.',
        ),
      );
    }
    final rows = ref.watch(adminContentRowsProvider(table.key));
    return Scaffold(
      appBar: AppBar(
        title: Text(table.label),
        actions: [
          IconButton(
            tooltip: 'Refresh records',
            onPressed: () =>
                ref.invalidate(adminContentRowsProvider(table.key)),
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _editRow(context, ref, table, null),
        icon: const Icon(Icons.add),
        label: const Text('Add record'),
      ),
      body: rows.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (_, _) => AppStatePanel(
          title: 'Could not load ${table.label.toLowerCase()}',
          message:
              'Check that the admin SQL policies have been applied and retry.',
          isError: true,
          actionLabel: 'Retry',
          onAction: () => ref.invalidate(adminContentRowsProvider(table.key)),
        ),
        data: (items) => items.isEmpty
            ? AppStatePanel(
                title: 'No ${table.label.toLowerCase()} yet',
                message:
                    'Add the first record to publish content in this section.',
                icon: _tableIcon(table.key),
                actionLabel: 'Add record',
                onAction: () => _editRow(context, ref, table, null),
              )
            : RefreshIndicator(
                onRefresh: () async =>
                    ref.invalidate(adminContentRowsProvider(table.key)),
                child: ListView.separated(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 96),
                  itemCount: items.length,
                  separatorBuilder: (_, _) => const SizedBox(height: 8),
                  itemBuilder: (context, index) {
                    final row = items[index];
                    final id = '${row['id'] ?? ''}';
                    final title =
                        '${row[table.titleField] ?? row['name'] ?? row['title'] ?? id}';
                    final detail = _rowSubtitle(row, table.titleField);
                    return ContentCard(
                      child: Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  title.isEmpty ? 'Untitled record' : title,
                                  style: Theme.of(context)
                                      .textTheme
                                      .titleMedium,
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  detail,
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                  style: Theme.of(context).textTheme.bodySmall,
                                ),
                                const SizedBox(height: 8),
                                _PublicationStatus(row: row),
                              ],
                            ),
                          ),
                          PopupMenuButton<String>(
                            tooltip: 'Record actions',
                            onSelected: (action) {
                              if (action == 'edit') {
                                _editRow(context, ref, table, row);
                              }
                              if (action == 'delete') {
                                _deleteRow(context, ref, table, row);
                              }
                            },
                            itemBuilder: (_) => const [
                              PopupMenuItem(value: 'edit', child: Text('Edit')),
                              PopupMenuItem(
                                value: 'delete',
                                child: Text('Delete'),
                              ),
                            ],
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

  String _rowSubtitle(Map<String, dynamic> row, String titleField) {
    for (final key in const [
      'summary',
      'short_description',
      'description',
      'location',
      'object_path',
      'answer',
      'value',
    ]) {
      final value = row[key];
      if (value != null && '$value'.trim().isNotEmpty && key != titleField) {
        return '$value';
      }
    }
    final state = row['is_published'] ?? row['is_active'];
    if (state is bool) {
      return state ? 'Visible to customers' : 'Hidden from customers';
    }
    return 'ID ${row['id'] ?? '—'}';
  }

  Future<void> _editRow(
    BuildContext context,
    WidgetRef ref,
    AdminContentTable table,
    Map<String, dynamic>? row,
  ) async {
    final saved = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (_) => _AdminRecordEditor(
        table: table,
        row: row,
        onUpload: _uploadCatalogueImage,
        onDiscardUpload: (key, path) =>
            ref.read(adminRepositoryProvider).removeCatalogueImage(key, path),
      ),
    );
    if (saved == null || !context.mounted) return;
    final uploadedPaths =
        (saved.remove('_admin_uploaded_paths') as List?)
            ?.whereType<String>()
            .toList() ??
        <String>[];
    try {
      final repository = ref.read(adminRepositoryProvider);
      if (row == null) {
        await repository.createRow(table, saved);
      } else {
        final id = '${row['id'] ?? ''}';
        if (id.isEmpty) throw const FormatException('This record has no ID.');
        await repository.updateRow(
          table,
          id,
          saved,
          oldObjectPath: row['object_path']?.toString(),
        );
      }
      final committedPath = saved['object_path'];
      for (final path in uploadedPaths.where((path) => path != committedPath)) {
        try {
          await repository.removeCatalogueImage(table.key, path);
        } on Object {
          // Unreferenced media can be cleaned up later.
        }
      }
      ref.invalidate(adminContentRowsProvider(table.key));
      if (context.mounted)
        _showToast(context, row == null ? 'Record added.' : 'Changes saved.');
    } on Object {
      for (final path in uploadedPaths) {
        try {
          await ref
              .read(adminRepositoryProvider)
              .removeCatalogueImage(table.key, path);
        } on Object {
          // An unreferenced upload can be cleaned up later.
        }
      }
      if (context.mounted) {
        _showToast(
          context,
          'Could not save this record. Check its fields and admin table policies.',
        );
      }
    }
  }

  Future<String?> _uploadCatalogueImage(String tableKey, String ownerId) async {
    final selection = await FilePicker.pickFile(type: FileType.image);
    if (selection == null) {
      return null;
    }
    final bytes = await selection.readAsBytes();
    if (bytes.isEmpty) {
      throw const FormatException('The selected image could not be read.');
    }
    return ref
        .read(adminRepositoryProvider)
        .uploadCatalogueImage(
          tableKey: tableKey,
          ownerId: ownerId,
          fileName: selection.name,
          bytes: bytes,
        );
  }

  Future<void> _deleteRow(
    BuildContext context,
    WidgetRef ref,
    AdminContentTable table,
    Map<String, dynamic> row,
  ) async {
    final label = '${row[table.titleField] ?? row['id'] ?? 'this record'}';
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete this record?'),
        content: Text(
          '“$label” may be referenced elsewhere. The database will reject deletion when it would break a protected relationship.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (confirmed != true || !context.mounted) return;
    try {
      final id = '${row['id'] ?? ''}';
      if (id.isEmpty) {
        throw const FormatException('This record has no ID.');
      }
      await ref
          .read(adminRepositoryProvider)
          .deleteRow(table, id, objectPath: row['object_path']?.toString());
      ref.invalidate(adminContentRowsProvider(table.key));
      if (context.mounted) _showToast(context, 'Record deleted.');
    } on Object {
      if (context.mounted) {
        _showToast(
          context,
          'Could not delete this record. Check whether it is still in use.',
        );
      }
    }
  }
}

class _PublicationStatus extends StatelessWidget {
  const _PublicationStatus({required this.row});
  final Map<String, dynamic> row;
  @override
  Widget build(BuildContext context) {
    final value = row['is_published'] ?? row['is_active'];
    if (value is! bool) return const SizedBox.shrink();
    return StatusChip(
      label: value ? 'Published' : 'Draft / hidden',
      tone: value ? StatusTone.success : StatusTone.neutral,
    );
  }
}

class _AdminRecordEditor extends ConsumerStatefulWidget {
  const _AdminRecordEditor({
    required this.table,
    required this.row,
    required this.onUpload,
    required this.onDiscardUpload,
  });
  final AdminContentTable table;
  final Map<String, dynamic>? row;
  final Future<String?> Function(String tableKey, String ownerId) onUpload;
  final Future<void> Function(String tableKey, String path) onDiscardUpload;
  @override
  ConsumerState<_AdminRecordEditor> createState() => _AdminRecordEditorState();
}

class _AdminRecordEditorState extends ConsumerState<_AdminRecordEditor> {
  final _formKey = GlobalKey<FormState>();
  final Map<String, TextEditingController> _controllers = {};
  final Map<String, bool> _switches = {};
  final List<String> _uploadedPaths = [];
  bool _uploading = false;
  late final Map<String, dynamic> _source;

  @override
  void initState() {
    super.initState();
    final input = widget.row ?? const <String, dynamic>{};
    _source = <String, dynamic>{};
    // Only expose fields intentionally defined for this table. A generic
    // `select()` may return internal columns that should never be editable.
    for (final entry in widget.table.createValues.entries) {
      final value = input.containsKey(entry.key)
          ? input[entry.key]
          : entry.value;
      _source[entry.key] = value;
      if (!isAdminTableFieldEditable(widget.table, entry.key)) continue;
      if (value is bool) {
        _switches[entry.key] = value;
      } else {
        _controllers[entry.key] = TextEditingController(
          text: value == null
              ? ''
              : value is Map || value is List
              ? jsonEncode(value)
              : '$value',
        );
      }
    }
  }

  @override
  void dispose() {
    for (final controller in _controllers.values) {
      controller.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AlertDialog(
    title: Text(
      widget.row == null
          ? 'Add ${widget.table.label.toLowerCase()}'
          : 'Edit record',
    ),
    content: SizedBox(
      width: 520,
      child: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              for (final entry in _controllers.entries) ...[
                if (entry.key == 'object_path' &&
                    (widget.table.key == 'product-images' ||
                        widget.table.key == 'project-images'))
                  Row(
                    children: [
                      Expanded(child: _textField(entry.key, entry.value)),
                      const SizedBox(width: 8),
                      IconButton.filledTonal(
                        tooltip: 'Upload image',
                        onPressed: _uploading
                            ? null
                            : () => _uploadImage(entry.key),
                        icon: _uploading
                            ? const SizedBox(
                                width: 18,
                                height: 18,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                ),
                              )
                            : const Icon(Icons.upload_outlined),
                      ),
                    ],
                  )
                else
                  _editorField(entry.key, entry.value),
                const SizedBox(height: 12),
              ],
              for (final entry in _switches.entries)
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: Text(_fieldLabel(entry.key)),
                  value: entry.value,
                  onChanged: (value) =>
                      setState(() => _switches[entry.key] = value),
                ),
              const SizedBox(height: 8),
              const Text(
                'Changes are checked by Supabase row-level policies. IDs and timestamps are managed by the database.',
                style: TextStyle(fontSize: 12),
              ),
            ],
          ),
        ),
      ),
    ),
    actions: [
      TextButton(
        onPressed: _uploading ? null : _cancel,
        child: const Text('Cancel'),
      ),
      FilledButton(
        onPressed: _uploading ? null : _save,
        child: const Text('Save'),
      ),
    ],
  );

  Widget _textField(String key, TextEditingController controller) =>
      TextFormField(
        controller: controller,
        keyboardType: _isNumeric(key, _source[key])
            ? const TextInputType.numberWithOptions(decimal: true)
            : TextInputType.text,
        minLines: _isLongText(key) ? 3 : 1,
        maxLines: _isLongText(key) ? 6 : 1,
        decoration: InputDecoration(labelText: _fieldLabel(key)),
        validator: _requiredField(key)
            ? (value) => value == null || value.trim().isEmpty
                  ? 'This field is required.'
                  : null
            : null,
      );

  Widget _editorField(String field, TextEditingController controller) {
    final referenceTable = adminReferenceTableForField(
      widget.table.table,
      field,
    );
    if (referenceTable == null) return _textField(field, controller);

    return ref
        .watch(adminReferenceRowsProvider(referenceTable))
        .when(
          loading: () => _textField(field, controller),
          error: (_, _) => _textField(field, controller),
          data: (rows) {
            if (rows.isEmpty) {
              return _textField(field, controller);
            }
            final titleField = adminReferenceTitleField(referenceTable);
            final currentValue = controller.text;
            final containsCurrent = rows.any(
              (row) => '${row['id'] ?? ''}' == currentValue,
            );
            final items = <DropdownMenuItem<String>>[
              DropdownMenuItem<String>(
                value: '',
                child: Text('Select ${_fieldLabel(field)}'),
              ),
              for (final row in rows)
                DropdownMenuItem<String>(
                  value: '${row['id'] ?? ''}',
                  child: Text(
                    '${row[titleField] ?? row['name'] ?? row['id'] ?? 'Record'}',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              if (currentValue.isNotEmpty && !containsCurrent)
                DropdownMenuItem<String>(
                  value: currentValue,
                  child: Text('Current record (${_shortId(currentValue)})'),
                ),
            ];
            return DropdownButtonFormField<String>(
              initialValue: currentValue.isNotEmpty ? currentValue : '',
              isExpanded: true,
              decoration: InputDecoration(labelText: _fieldLabel(field)),
              items: items,
              onChanged: (value) => controller.text = value ?? '',
              validator: _requiredField(field)
                  ? (value) => value == null || value.isEmpty
                        ? 'Choose a related record.'
                        : null
                  : null,
            );
          },
        );
  }

  Future<void> _uploadImage(String field) async {
    final parentField = widget.table.key == 'product-images'
        ? 'product_id'
        : 'project_id';
    final ownerId = _controllers[parentField]?.text.trim() ?? '';
    if (ownerId.isEmpty) {
      _showToast(context, 'Enter the product or project ID first.');
      return;
    }
    setState(() => _uploading = true);
    try {
      final path = await widget.onUpload(widget.table.key, ownerId);
      if (path != null && mounted) {
        _uploadedPaths.add(path);
        _controllers[field]?.text = path;
      }
    } on Object {
      if (mounted) {
        _showToast(
          context,
          'Image upload failed. Check file size and storage policies.',
        );
      }
    } finally {
      if (mounted) setState(() => _uploading = false);
    }
  }

  Future<void> _cancel() async {
    for (final path in _uploadedPaths) {
      try {
        await widget.onDiscardUpload(widget.table.key, path);
      } on Object {
        // A later storage cleanup can remove files not referenced by rows.
      }
    }
    if (mounted) Navigator.pop(context);
  }

  void _save() {
    if (widget.row == null) {
      final slug = _controllers['slug'];
      final title = _controllers[widget.table.titleField]?.text.trim();
      if (slug != null && slug.text.trim().isEmpty && title != null) {
        slug.text = _slugify(title);
      }
    }
    if (!_formKey.currentState!.validate()) return;
    final result = <String, dynamic>{};
    for (final entry in _controllers.entries) {
      final key = entry.key;
      final text = entry.value.text.trim();
      final original = _source[key];
      if (text.isEmpty && original == null) {
        result[key] = null;
      } else if (original is int ||
          const {'sort_order', 'rating'}.contains(key)) {
        final value = int.tryParse(text);
        if (value == null) {
          _showToast(context, '${_fieldLabel(key)} must be a whole number.');
          return;
        }
        result[key] = value;
      } else if (original is num || key == 'price') {
        final value = num.tryParse(text);
        if (text.isNotEmpty && value == null) {
          _showToast(context, '${_fieldLabel(key)} must be a number.');
          return;
        }
        result[key] = value;
      } else if (original is Map || original is List) {
        try {
          result[key] = jsonDecode(text);
        } on FormatException {
          _showToast(context, '${_fieldLabel(key)} must contain valid JSON.');
          return;
        }
      } else {
        result[key] = text.isEmpty ? null : text;
      }
    }
    result.addAll(_switches);
    if (_uploadedPaths.isNotEmpty) {
      result['_admin_uploaded_paths'] = List<String>.from(_uploadedPaths);
    }
    if (widget.row == null) {
      final label = result[widget.table.titleField];
      if (result.containsKey('slug') &&
          (result['slug'] as String? ?? '').trim().isEmpty &&
          label is String) {
        result['slug'] = _slugify(label);
      }
    }
    Navigator.pop(context, result);
  }
}

bool _isNumeric(String key, Object? value) =>
    value is num || const {'sort_order', 'rating', 'price'}.contains(key);
bool _isLongText(String key) => const {
  'description',
  'short_description',
  'summary',
  'body',
  'answer',
  'help_text',
}.contains(key);
bool _requiredField(String key) => const {
  'name',
  'title',
  'question',
  'label',
  'key',
  'slug',
  'category_id',
  'service_id',
  'question_id',
  'question_key',
  'option_value',
  'value',
  'language_code',
  'product_id',
  'project_id',
}.contains(key);
String _fieldLabel(String key) => key
    .split('_')
    .map(
      (word) =>
          word.isEmpty ? word : '${word[0].toUpperCase()}${word.substring(1)}',
    )
    .join(' ');
String _shortId(String value) =>
    value.length <= 12 ? value : '${value.substring(0, 8)}…';
String _slugify(String value) => value
    .trim()
    .toLowerCase()
    .replaceAll(RegExp(r'[^a-z0-9]+'), '-')
    .replaceAll(RegExp(r'^-|-$'), '');

class AdminUsersPage extends StatefulWidget {
  const AdminUsersPage({super.key});
  @override
  State<AdminUsersPage> createState() => _AdminUsersPageState();
}

class _AdminUsersPageState extends State<AdminUsersPage> {
  int _lastPage = 1;
  bool _working = false;

  @override
  Widget build(BuildContext context) => AdminGate(
    child: Consumer(
      builder: (context, ref, _) {
        final currentUserId = ref.watch(authUserProvider).value?.id;
        final firstPage = ref.watch(adminUserPageProvider(1));
        final pages = <AsyncValue<List<AdminUserRecord>>>[
          for (var page = 1; page <= _lastPage; page++)
            ref.watch(adminUserPageProvider(page)),
        ];
        return Scaffold(
          appBar: AppBar(title: const Text('Users and access')),
          body: firstPage.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (_, _) => AppStatePanel(
              title: 'Could not load user accounts',
              message: 'Deploy the admin-user-management Edge Function and verify its server secrets.',
              isError: true,
              actionLabel: 'Retry',
              onAction: () => ref.invalidate(adminUserPageProvider(1)),
            ),
            data: (_) {
              final users = <AdminUserRecord>[];
              for (final page in pages) {
                final value = page.value;
                if (value != null) users.addAll(value);
              }
              final lastValue = pages.last.value;
              final hasMore = lastValue != null && lastValue.length == 50;
              return RefreshIndicator(
                onRefresh: () async {
                  for (var page = 1; page <= _lastPage; page++) {
                    ref.invalidate(adminUserPageProvider(page));
                  }
                },
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 28),
                  children: [
                    Text(
                      'Customer and staff accounts',
                      style: Theme.of(context).textTheme.headlineSmall,
                    ),
                    const SizedBox(height: 6),
                    Text(
                      '${users.length} account${users.length == 1 ? '' : 's'} loaded. Authentication changes are handled by the protected Supabase Function.',
                    ),
                    const SizedBox(height: 14),
                    for (final user in users) ...[
                      _AdminUserCard(
                        user: user,
                        isSelf: user.id == currentUserId,
                        busy: _working,
                        onRoles: () => _manageRoles(context, ref, user),
                        onSuspension: () => _setSuspended(context, ref, user),
                      ),
                      const SizedBox(height: 8),
                    ],
                    if (hasMore)
                      OutlinedButton.icon(
                        onPressed: _working
                            ? null
                            : () => setState(() => _lastPage++),
                        icon: const Icon(Icons.expand_more),
                        label: const Text('Load more users'),
                      ),
                  ],
                ),
              );
            },
          ),
        );
      },
    ),
  );

  Future<void> _manageRoles(
    BuildContext context,
    WidgetRef ref,
    AdminUserRecord user,
  ) async {
    final current = user.roles.toSet();
    final next = await showDialog<Set<String>>(
      context: context,
      builder: (context) => _RoleEditor(
        initial: current,
        isSelf: user.id == ref.read(authUserProvider).value?.id,
      ),
    );
    if (next == null || !context.mounted) return;
    setState(() => _working = true);
    try {
      final repository = ref.read(adminRepositoryProvider);
      for (final role in const [
        'admin',
        'operations',
        'estimator',
        'support',
        'content_manager',
      ]) {
        if (current.contains(role) != next.contains(role)) {
          await repository.setUserRole(
            userId: user.id,
            role: role,
            enabled: next.contains(role),
          );
        }
      }
      for (var page = 1; page <= _lastPage; page++) {
        ref.invalidate(adminUserPageProvider(page));
      }
      if (context.mounted) {
        _showToast(context, 'Staff access updated.');
      }
    } on Object {
      if (context.mounted) {
        _showToast(
          context,
          'Could not update roles. Check the Edge Function and admin role.',
        );
      }
    } finally {
      if (mounted) setState(() => _working = false);
    }
  }

  Future<void> _setSuspended(
    BuildContext context,
    WidgetRef ref,
    AdminUserRecord user,
  ) async {
    final suspend = !user.isSuspended;
    final answer = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(suspend ? 'Suspend sign-in?' : 'Restore sign-in?'),
        content: Text(
          suspend
              ? 'This user will not be able to sign in until access is restored.'
              : 'This user will be able to sign in again.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(suspend ? 'Suspend' : 'Restore'),
          ),
        ],
      ),
    );
    if (answer != true || !context.mounted) return;
    setState(() => _working = true);
    try {
      await ref
          .read(adminRepositoryProvider)
          .setUserSuspended(userId: user.id, suspended: suspend);
      for (var page = 1; page <= _lastPage; page++) {
        ref.invalidate(adminUserPageProvider(page));
      }
      if (context.mounted) {
        _showToast(
          context,
          suspend ? 'Sign-in suspended.' : 'Sign-in restored.',
        );
      }
    } on Object {
      if (context.mounted) {
        _showToast(context, 'Could not change sign-in access.');
      }
    } finally {
      if (mounted) setState(() => _working = false);
    }
  }
}

class _AdminUserCard extends StatelessWidget {
  const _AdminUserCard({
    required this.user,
    required this.isSelf,
    required this.busy,
    required this.onRoles,
    required this.onSuspension,
  });
  final AdminUserRecord user;
  final bool isSelf, busy;
  final VoidCallback onRoles, onSuspension;
  @override
  Widget build(BuildContext context) => ContentCard(
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const CircleAvatar(child: Icon(Icons.person_outline)),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    user.name.isEmpty ? 'FixPK user' : user.name,
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  Text(
                    user.email.isEmpty ? user.id : user.email,
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],
              ),
            ),
            StatusChip(
              label: user.isSuspended ? 'Suspended' : 'Active',
              tone: user.isSuspended ? StatusTone.error : StatusTone.success,
            ),
          ],
        ),
        if (user.phone.isNotEmpty) ...[
          const SizedBox(height: 6),
          Text(user.phone),
        ],
        const SizedBox(height: 10),
        Wrap(
          spacing: 6,
          runSpacing: 6,
          children: user.roles.isEmpty
              ? const [Chip(label: Text('Customer'))]
              : user.roles.map((role) => Chip(label: Text(role))).toList(),
        ),
        const SizedBox(height: 6),
        Wrap(
          spacing: 8,
          children: [
            TextButton.icon(
              onPressed: busy ? null : onRoles,
              icon: const Icon(Icons.admin_panel_settings_outlined),
              label: const Text('Manage roles'),
            ),
            TextButton.icon(
              onPressed: busy || isSelf ? null : onSuspension,
              icon: Icon(
                user.isSuspended
                    ? Icons.lock_open_outlined
                    : Icons.block_outlined,
              ),
              label: Text(user.isSuspended ? 'Restore access' : 'Suspend'),
            ),
          ],
        ),
      ],
    ),
  );
}

class _RoleEditor extends StatefulWidget {
  const _RoleEditor({required this.initial, required this.isSelf});
  final Set<String> initial;
  final bool isSelf;
  @override
  State<_RoleEditor> createState() => _RoleEditorState();
}

class _RoleEditorState extends State<_RoleEditor> {
  late final Set<String> _roles = Set<String>.from(widget.initial);
  static const _available = {
    'admin': 'Administrator',
    'operations': 'Operations',
    'estimator': 'Estimator',
    'support': 'Support',
    'content_manager': 'Content manager',
  };
  @override
  Widget build(BuildContext context) => AlertDialog(
    title: const Text('Staff roles'),
    content: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        for (final entry in _available.entries)
          CheckboxListTile(
            contentPadding: EdgeInsets.zero,
            title: Text(entry.value),
            value: _roles.contains(entry.key),
            onChanged: widget.isSelf && entry.key == 'admin'
                ? null
                : (selected) => setState(() {
                    if (selected == true) {
                      _roles.add(entry.key);
                    } else {
                      _roles.remove(entry.key);
                    }
                  }),
          ),
      ],
    ),
    actions: [
      TextButton(
        onPressed: () => Navigator.pop(context),
        child: const Text('Cancel'),
      ),
      FilledButton(
        onPressed: () => Navigator.pop(context, _roles),
        child: const Text('Save roles'),
      ),
    ],
  );
}

void _showToast(BuildContext context, String message) {
  ScaffoldMessenger.of(context)
    ..hideCurrentSnackBar()
    ..showSnackBar(SnackBar(content: Text(message)));
}

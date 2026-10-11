import 'dart:typed_data';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../app/providers.dart';

class AdminContentTable {
  const AdminContentTable({
    required this.key,
    required this.table,
    required this.label,
    required this.titleField,
    required this.createValues,
    this.description,
  });

  final String key;
  final String table;
  final String label;
  final String titleField;
  final Map<String, dynamic> createValues;
  final String? description;
}

/// Allowlisted tables are the only ones exposed by the generic admin editor.
const adminContentTables = <AdminContentTable>[
  AdminContentTable(
    key: 'service-categories',
    table: 'service_categories',
    label: 'Service categories',
    titleField: 'name',
    description: 'Organize services into customer-facing groups.',
    createValues: {
      'name': '',
      'description': '',
      'icon_name': 'handyman',
      'sort_order': 0,
      'is_active': true,
    },
  ),
  AdminContentTable(
    key: 'services',
    table: 'services',
    label: 'Services',
    titleField: 'name',
    description: 'Create, update, publish, or retire a FixPK service.',
    createValues: {
      'category_id': '',
      'name': '',
      'short_description': '',
      'description': '',
      'sort_order': 0,
      'is_active': true,
    },
  ),
  AdminContentTable(
    key: 'service-questions',
    table: 'service_questions',
    label: 'Service form questions',
    titleField: 'label',
    createValues: {
      'service_id': '',
      'question_key': '',
      'label': '',
      'help_text': '',
      'input_type': 'text',
      'is_required': false,
      'sort_order': 0,
    },
  ),
  AdminContentTable(
    key: 'service-question-options',
    table: 'service_question_options',
    label: 'Question options',
    titleField: 'option_label',
    createValues: {
      'question_id': '',
      'option_value': '',
      'option_label': '',
      'sort_order': 0,
    },
  ),
  AdminContentTable(
    key: 'product-categories',
    table: 'product_categories',
    label: 'Product categories',
    titleField: 'name',
    createValues: {
      'name': '',
      'description': '',
      'sort_order': 0,
      'is_published': false,
    },
  ),
  AdminContentTable(
    key: 'products',
    table: 'products',
    label: 'Products',
    titleField: 'name',
    description: 'Product catalogue and publication controls.',
    createValues: {
      'category_id': '',
      'name': '',
      'slug': '',
      'summary': '',
      'description': '',
      'sku': '',
      'price': null,
      'currency': 'PKR',
      'is_available': true,
      'sort_order': 0,
      'is_published': false,
    },
  ),
  AdminContentTable(
    key: 'product-images',
    table: 'product_images',
    label: 'Product images',
    titleField: 'alt_text',
    createValues: {
      'product_id': '',
      'object_path': '',
      'alt_text': '',
      'sort_order': 0,
    },
  ),
  AdminContentTable(
    key: 'product-specifications',
    table: 'product_specifications',
    label: 'Product specifications',
    titleField: 'name',
    createValues: {'product_id': '', 'name': '', 'value': '', 'sort_order': 0},
  ),
  AdminContentTable(
    key: 'projects',
    table: 'projects',
    label: 'Projects',
    titleField: 'title',
    description: 'Manage the FixPK portfolio and similar-project enquiries.',
    createValues: {
      'title': '',
      'slug': '',
      'category': '',
      'summary': '',
      'description': '',
      'location': '',
      'completed_on': null,
      'sort_order': 0,
      'is_published': false,
    },
  ),
  AdminContentTable(
    key: 'project-images',
    table: 'project_images',
    label: 'Project images',
    titleField: 'alt_text',
    createValues: {
      'project_id': '',
      'object_path': '',
      'alt_text': '',
      'sort_order': 0,
    },
  ),
  AdminContentTable(
    key: 'faq',
    table: 'faq',
    label: 'FAQs',
    titleField: 'question',
    createValues: {
      'question': '',
      'answer': '',
      'language_code': 'en',
      'sort_order': 0,
      'is_published': false,
    },
  ),
  AdminContentTable(
    key: 'banners',
    table: 'banners',
    label: 'Home banners',
    titleField: 'title',
    description: 'Home-page campaign content and visibility.',
    createValues: {
      'title': '',
      'subtitle': '',
      'image_url': '',
      'action_label': '',
      'action_deep_link': '',
      'sort_order': 0,
      'is_active': false,
    },
  ),
  AdminContentTable(
    key: 'app-content',
    table: 'app_content',
    label: 'App content',
    titleField: 'key',
    description: 'Localized, editable text sections and in-app content.',
    createValues: {
      'key': '',
      'language_code': 'en',
      'title': '',
      'body': '',
      'is_published': false,
    },
  ),
];

AdminContentTable? adminTableByKey(String key) {
  for (final item in adminContentTables) {
    if (item.key == key) return item;
  }
  return null;
}

String? adminReferenceTableForField(String tableKey, String field) =>
    switch ((tableKey, field)) {
      ('services', 'category_id') => 'service-categories',
      ('service_questions', 'service_id') => 'services',
      ('service_question_options', 'question_id') => 'service-questions',
      ('products', 'category_id') => 'product-categories',
      ('product_images', 'product_id') ||
      ('product_specifications', 'product_id') => 'products',
      ('project_images', 'project_id') => 'projects',
      _ => null,
    };

String adminReferenceTitleField(String tableKey) => switch (tableKey) {
  'service-categories' ||
  'services' ||
  'product-categories' ||
  'products' => 'name',
  'service-questions' => 'label',
  'projects' => 'title',
  _ => 'id',
};

bool isAdminEditableField(String field) =>
    !const {'id', 'created_at', 'updated_at', 'deleted_at'}.contains(field);

bool isAdminTableFieldEditable(AdminContentTable table, String field) =>
    table.createValues.containsKey(field) && isAdminEditableField(field);

class AdminUserRecord {
  const AdminUserRecord({
    required this.id,
    required this.email,
    required this.name,
    required this.phone,
    required this.roles,
    required this.bannedUntil,
    required this.createdAt,
    required this.lastSignInAt,
  });

  final String id;
  final String email;
  final String name;
  final String phone;
  final List<String> roles;
  final DateTime? bannedUntil;
  final DateTime? createdAt;
  final DateTime? lastSignInAt;

  bool get isSuspended =>
      bannedUntil != null && bannedUntil!.isAfter(DateTime.now().toUtc());

  factory AdminUserRecord.fromJson(Map<String, dynamic> json) {
    final metadata = json['user_metadata'] is Map
        ? Map<String, dynamic>.from(json['user_metadata'] as Map)
        : <String, dynamic>{};
    return AdminUserRecord(
      id: '${json['id'] ?? ''}',
      email: '${json['email'] ?? ''}',
      name: '${metadata['full_name'] ?? metadata['name'] ?? ''}',
      phone: '${metadata['phone'] ?? ''}',
      roles: (json['roles'] as List? ?? const [])
          .map((role) => '$role')
          .toList(),
      bannedUntil: DateTime.tryParse('${json['banned_until'] ?? ''}'),
      createdAt: DateTime.tryParse('${json['created_at'] ?? ''}'),
      lastSignInAt: DateTime.tryParse('${json['last_sign_in_at'] ?? ''}'),
    );
  }
}

class AdminRepository {
  const AdminRepository(this._client);
  final SupabaseClient _client;

  Future<List<Map<String, dynamic>>> fetchRows(AdminContentTable table) async {
    final rows = await _client.from(table.table).select().limit(100);
    return rows.map((row) => Map<String, dynamic>.from(row)).toList();
  }

  Future<void> createRow(
    AdminContentTable table,
    Map<String, dynamic> values,
  ) async {
    await _client.from(table.table).insert(values);
  }

  Future<void> updateRow(
    AdminContentTable table,
    String id,
    Map<String, dynamic> values, {
    String? oldObjectPath,
  }) async {
    await _client.from(table.table).update(values).eq('id', id);
    if (oldObjectPath != null &&
        oldObjectPath.isNotEmpty &&
        values['object_path'] != oldObjectPath) {
      try {
        await removeCatalogueImage(table.key, oldObjectPath);
      } on Object {
        // The record remains valid; an unused object can be cleaned up later.
      }
    }
  }

  Future<String> uploadCatalogueImage({
    required String tableKey,
    required String ownerId,
    required String fileName,
    required Uint8List bytes,
  }) async {
    final bucket = _mediaBucket(tableKey);
    if (ownerId.trim().isEmpty || bytes.isEmpty) {
      throw const FormatException(
        'Choose a parent record and a non-empty image.',
      );
    }
    final extension = fileName.split('.').last.toLowerCase();
    if (!const {'jpg', 'jpeg', 'png', 'webp'}.contains(extension)) {
      throw const FormatException('Choose a JPG, PNG, or WebP image.');
    }
    if (bytes.length > 8 * 1024 * 1024) {
      throw const FormatException('Choose an image smaller than 8 MB.');
    }
    final safeName = fileName.replaceAll(RegExp(r'[^a-zA-Z0-9._-]'), '_');
    final path =
        '${ownerId.trim()}/${DateTime.now().toUtc().microsecondsSinceEpoch}-$safeName';
    await _client.storage
        .from(bucket)
        .uploadBinary(
          path,
          bytes,
          fileOptions: FileOptions(
            contentType: _imageMime(fileName),
            upsert: false,
          ),
        );
    return path;
  }

  Future<void> deleteRow(
    AdminContentTable table,
    String id, {
    String? objectPath,
  }) async {
    await _client.from(table.table).delete().eq('id', id);
    if (objectPath != null &&
        objectPath.isNotEmpty &&
        (table.key == 'product-images' || table.key == 'project-images')) {
      try {
        await removeCatalogueImage(table.key, objectPath);
      } on Object {
        // The row was deleted; the unreferenced object can be cleaned up later.
      }
    }
  }

  Future<void> removeCatalogueImage(String tableKey, String objectPath) async {
    await _client.storage.from(_mediaBucket(tableKey)).remove([objectPath]);
  }

  String _mediaBucket(String tableKey) => switch (tableKey) {
    'product-images' => 'product-images',
    'project-images' => 'project-images',
    _ => throw ArgumentError.value(tableKey, 'tableKey'),
  };

  String _imageMime(String name) {
    final extension = name.split('.').last.toLowerCase();
    return switch (extension) {
      'jpg' || 'jpeg' => 'image/jpeg',
      'png' => 'image/png',
      'webp' => 'image/webp',
      _ => 'application/octet-stream',
    };
  }

  Future<List<AdminUserRecord>> fetchUsers(int page) async {
    final result = await _client.functions.invoke(
      'admin-user-management',
      body: {'action': 'list', 'page': page, 'perPage': 50},
    );
    final body = result.data;
    if (body is! Map<String, dynamic> || body['users'] is! List) {
      throw const FormatException('Admin user response is invalid.');
    }
    return (body['users'] as List)
        .whereType<Map<String, dynamic>>()
        .map(AdminUserRecord.fromJson)
        .toList(growable: false);
  }

  Future<void> setUserRole({
    required String userId,
    required String role,
    required bool enabled,
  }) async {
    await _client.functions.invoke(
      'admin-user-management',
      body: {
        'action': 'set_role',
        'userId': userId,
        'role': role,
        'enabled': enabled,
      },
    );
  }

  Future<void> setUserSuspended({
    required String userId,
    required bool suspended,
  }) async {
    await _client.functions.invoke(
      'admin-user-management',
      body: {'action': suspended ? 'suspend' : 'restore', 'userId': userId},
    );
  }
}

final adminRepositoryProvider = Provider<AdminRepository>(
  (ref) => AdminRepository(ref.watch(supabaseClientProvider)),
);

final adminContentRowsProvider =
    FutureProvider.family<List<Map<String, dynamic>>, String>((ref, key) {
      final table = adminTableByKey(key);
      if (table == null) throw ArgumentError.value(key, 'key');
      return ref.watch(adminRepositoryProvider).fetchRows(table);
    });

final adminReferenceRowsProvider =
    FutureProvider.family<List<Map<String, dynamic>>, String>((ref, key) {
      final table = adminTableByKey(key);
      if (table == null) throw ArgumentError.value(key, 'key');
      return ref.watch(adminRepositoryProvider).fetchRows(table);
    });

final adminUserPageProvider = FutureProvider.family<List<AdminUserRecord>, int>(
  (ref, page) => ref.watch(adminRepositoryProvider).fetchUsers(page),
);

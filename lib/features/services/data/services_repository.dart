import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../app/providers.dart';
import '../../../core/storage/read_cache.dart';

class ServiceCategory {
  const ServiceCategory({
    required this.id,
    required this.name,
    required this.description,
    required this.iconName,
    required this.sortOrder,
  });

  final String id;
  final String name;
  final String description;
  final String iconName;
  final int sortOrder;

  factory ServiceCategory.fromRow(Map<String, dynamic> row) => ServiceCategory(
    id: '${row['id'] ?? row['slug'] ?? row['name'] ?? row['title'] ?? ''}',
    name: '${row['name'] ?? row['title'] ?? 'Service'}',
    description: '${row['description'] ?? ''}',
    iconName: '${row['icon_name'] ?? row['icon'] ?? ''}',
    sortOrder: _int(row['sort_order']),
  );
}

class ServiceItem {
  const ServiceItem({
    required this.id,
    required this.categoryId,
    required this.name,
    required this.description,
    required this.sortOrder,
  });

  final String id;
  final String categoryId;
  final String name;
  final String description;
  final int sortOrder;

  factory ServiceItem.fromRow(Map<String, dynamic> row) => ServiceItem(
    id: '${row['id'] ?? row['slug'] ?? row['name'] ?? row['title'] ?? ''}',
    categoryId: '${row['category_id'] ?? row['service_category_id'] ?? ''}',
    name: '${row['name'] ?? row['title'] ?? 'Service'}',
    description: '${row['short_description'] ?? row['description'] ?? ''}',
    sortOrder: _int(row['sort_order']),
  );
}

class ServiceCatalogue {
  const ServiceCatalogue({required this.categories, required this.services});
  final List<ServiceCategory> categories;
  final List<ServiceItem> services;
}

int _int(Object? value) =>
    value is num ? value.toInt() : int.tryParse('$value') ?? 0;

/// Reads only published catalogue rows; the database remains the source of truth.
class ServicesRepository {
  const ServicesRepository(this._client, this._cache);
  final SupabaseClient _client;
  final ReadCache _cache;

  Stream<ServiceCatalogue> watchCatalogue() => _cache.watch(
    'services.v1',
    () async {
      // Independent reads run together; unpublished rows never reach the client.
      return Future.wait([
        _client
            .from('service_categories')
            .select('id,name,description,icon_name,sort_order')
            .eq('is_published', true)
            .order('sort_order')
            .order('id'),
        _client
            .from('services')
            .select('id,category_id,name,description,sort_order')
            .eq('is_published', true)
            .order('sort_order')
            .order('id'),
      ]);
    },
    (data) {
      final categoryRows = (data as List)[0] as List;
      final serviceRows = data[1] as List;
      final categories =
          _activeRows(categoryRows)
              .map(ServiceCategory.fromRow)
              .where((item) => item.id.isNotEmpty)
              .toList()
            ..sort((a, b) => a.sortOrder.compareTo(b.sortOrder));
      final categoryIds = categories.map((item) => item.id).toSet();
      final services =
          _activeRows(serviceRows)
              .map(ServiceItem.fromRow)
              .where(
                (item) =>
                    item.id.isNotEmpty && categoryIds.contains(item.categoryId),
              )
              .toList()
            ..sort((a, b) => a.sortOrder.compareTo(b.sortOrder));
      return ServiceCatalogue(categories: categories, services: services);
    },
  );

  static List<Map<String, dynamic>> _activeRows(List<dynamic> rows) =>
      rows.whereType<Map<String, dynamic>>().where((row) {
        for (final key in const ['is_active', 'is_published', 'active']) {
          final value = row[key];
          if (value is bool && !value) return false;
        }
        return true;
      }).toList();
}

final servicesRepositoryProvider = Provider<ServicesRepository>((ref) {
  return ServicesRepository(
    ref.watch(supabaseClientProvider),
    ref.watch(readCacheProvider),
  );
});

final serviceCatalogueProvider = StreamProvider<ServiceCatalogue>((ref) {
  return ref.watch(servicesRepositoryProvider).watchCatalogue();
});

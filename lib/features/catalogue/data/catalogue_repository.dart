import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../app/providers.dart';
import '../../../core/storage/read_cache.dart';

class ProductCategoryRecord {
  const ProductCategoryRecord({
    required this.id,
    required this.name,
    required this.description,
    required this.sortOrder,
  });

  final String id;
  final String name;
  final String description;
  final int sortOrder;

  factory ProductCategoryRecord.fromRow(Map<String, dynamic> row) =>
      ProductCategoryRecord(
        id: '${row['id'] ?? ''}',
        name: '${row['name'] ?? ''}',
        description: '${row['description'] ?? ''}',
        sortOrder: _toInt(row['sort_order']),
      );
}

class ProductImageRecord {
  const ProductImageRecord({
    required this.url,
    required this.altText,
    required this.sortOrder,
  });

  final String url;
  final String altText;
  final int sortOrder;

  factory ProductImageRecord.fromRow(
    Map<String, dynamic> row,
    String publicUrl,
  ) => ProductImageRecord(
    url: publicUrl,
    altText: '${row['alt_text'] ?? ''}',
    sortOrder: _toInt(row['sort_order']),
  );
}

class ProductSpecificationRecord {
  const ProductSpecificationRecord({
    required this.name,
    required this.value,
    required this.sortOrder,
  });

  final String name;
  final String value;
  final int sortOrder;

  factory ProductSpecificationRecord.fromRow(Map<String, dynamic> row) =>
      ProductSpecificationRecord(
        name: '${row['name'] ?? ''}',
        value: '${row['value'] ?? ''}',
        sortOrder: _toInt(row['sort_order']),
      );
}

class ProductRecord {
  const ProductRecord({
    required this.id,
    required this.categoryId,
    required this.name,
    required this.slug,
    required this.summary,
    required this.description,
    required this.sku,
    required this.price,
    required this.currency,
    required this.isAvailable,
    required this.images,
    required this.specifications,
  });

  final String id;
  final String categoryId;
  final String name;
  final String slug;
  final String summary;
  final String description;
  final String sku;
  final num? price;
  final String currency;
  final bool isAvailable;
  final List<ProductImageRecord> images;
  final List<ProductSpecificationRecord> specifications;

  factory ProductRecord.fromRow(
    Map<String, dynamic> row, {
    List<ProductImageRecord> images = const [],
    List<ProductSpecificationRecord> specifications = const [],
  }) => ProductRecord(
    id: '${row['id'] ?? ''}',
    categoryId: '${row['category_id'] ?? ''}',
    name: '${row['name'] ?? ''}',
    slug: '${row['slug'] ?? ''}',
    summary: '${row['summary'] ?? ''}',
    description: '${row['description'] ?? ''}',
    sku: '${row['sku'] ?? ''}',
    price: _toNumOrNull(row['price']),
    currency: '${row['currency'] ?? 'PKR'}'.trim(),
    isAvailable: row['is_available'] == true,
    images: images,
    specifications: specifications,
  );
}

class ProjectImageRecord {
  const ProjectImageRecord({
    required this.url,
    required this.altText,
    required this.sortOrder,
  });

  final String url;
  final String altText;
  final int sortOrder;
}

class ProjectRecord {
  const ProjectRecord({
    required this.id,
    required this.title,
    required this.slug,
    required this.category,
    required this.summary,
    required this.description,
    required this.location,
    required this.completedOn,
    required this.sortOrder,
    required this.images,
  });

  final String id;
  final String title;
  final String slug;
  final String category;
  final String summary;
  final String description;
  final String location;
  final DateTime? completedOn;
  final int sortOrder;
  final List<ProjectImageRecord> images;

  factory ProjectRecord.fromRow(
    Map<String, dynamic> row, {
    List<ProjectImageRecord> images = const [],
  }) => ProjectRecord(
    id: '${row['id'] ?? ''}',
    title: '${row['title'] ?? ''}',
    slug: '${row['slug'] ?? ''}',
    category: '${row['category'] ?? ''}',
    summary: '${row['summary'] ?? ''}',
    description: '${row['description'] ?? ''}',
    location: '${row['location'] ?? ''}',
    completedOn: row['completed_on'] == null
        ? null
        : DateTime.tryParse('${row['completed_on']}'),
    sortOrder: _toInt(row['sort_order']),
    images: images,
  );
}

class ProductCatalogue {
  const ProductCatalogue({required this.categories, required this.products});
  final List<ProductCategoryRecord> categories;
  final List<ProductRecord> products;
}

class CatalogueRepository {
  const CatalogueRepository(this._client, this._cache);
  final SupabaseClient _client;
  final ReadCache _cache;

  Stream<ProductCatalogue> watchProducts() =>
      _cache.watch('products.v1', _fetchProductRows, _decodeProducts);

  Future<dynamic> _fetchProductRows() async {
    final categoryFuture = _client
        .from('product_categories')
        .select('id,name,description,sort_order,is_published')
        .eq('is_published', true)
        .order('sort_order')
        .order('name');
    final productFuture = _client
        .from('products')
        .select(
          'id,category_id,name,slug,summary,description,sku,price,currency,is_available,sort_order',
        )
        .eq('is_published', true)
        .order('sort_order')
        .order('name');

    final initial = await Future.wait([categoryFuture, productFuture]);
    final categoryRows = initial[0];
    final productRows = initial[1];
    if (productRows.isEmpty) {
      return [
        categoryRows,
        productRows,
        <Map<String, dynamic>>[],
        <Map<String, dynamic>>[],
      ];
    }
    final productIds = productRows.map((row) => row['id'].toString()).toList();
    final imageFuture = _client
        .from('product_images')
        .select('id,product_id,object_path,alt_text,sort_order')
        .inFilter('product_id', productIds)
        .order('sort_order');
    final specFuture = _client
        .from('product_specifications')
        .select('id,product_id,name,value,sort_order')
        .inFilter('product_id', productIds)
        .order('sort_order');
    final details = await Future.wait([imageFuture, specFuture]);
    return [categoryRows, productRows, details[0], details[1]];
  }

  ProductCatalogue _decodeProducts(dynamic data) {
    final groups = data as List;
    final categoryRows = (groups[0] as List).cast<Map<String, dynamic>>();
    final productRows = (groups[1] as List).cast<Map<String, dynamic>>();
    final imageRows = (groups[2] as List).cast<Map<String, dynamic>>();
    final specRows = (groups[3] as List).cast<Map<String, dynamic>>();
    final imagesByProduct = <String, List<ProductImageRecord>>{};
    for (final row in imageRows) {
      final path = row['object_path']?.toString() ?? '';
      if (path.isEmpty) continue;
      final productId = row['product_id'].toString();
      imagesByProduct
          .putIfAbsent(productId, () => [])
          .add(
            ProductImageRecord.fromRow(
              row,
              _client.storage.from('product-images').getPublicUrl(path),
            ),
          );
    }
    final specsByProduct = <String, List<ProductSpecificationRecord>>{};
    for (final row in specRows) {
      specsByProduct
          .putIfAbsent(row['product_id'].toString(), () => [])
          .add(ProductSpecificationRecord.fromRow(row));
    }
    final products = productRows
        .map(
          (row) => ProductRecord.fromRow(
            row,
            images: imagesByProduct[row['id'].toString()] ?? const [],
            specifications: specsByProduct[row['id'].toString()] ?? const [],
          ),
        )
        .toList(growable: false);
    return ProductCatalogue(
      categories: categoryRows
          .map(ProductCategoryRecord.fromRow)
          .toList(growable: false),
      products: products,
    );
  }

  Stream<List<ProjectRecord>> watchProjects() =>
      _cache.watch('projects.v1', _fetchProjectRows, _decodeProjects);

  Future<dynamic> _fetchProjectRows() async {
    final rows = await _client
        .from('projects')
        .select(
          'id,title,slug,category,summary,description,location,completed_on,sort_order,is_published',
        )
        .eq('is_published', true)
        .order('sort_order')
        .order('completed_on', ascending: false);
    if (rows.isEmpty) {
      return [<Map<String, dynamic>>[], <Map<String, dynamic>>[]];
    }
    final projectIds = rows.map((row) => row['id'].toString()).toList();
    final imageRows = await _client
        .from('project_images')
        .select('id,project_id,object_path,alt_text,sort_order')
        .inFilter('project_id', projectIds)
        .order('sort_order');
    return [rows, imageRows];
  }

  List<ProjectRecord> _decodeProjects(dynamic data) {
    final groups = data as List;
    final rows = (groups[0] as List).cast<Map<String, dynamic>>();
    final imageRows = (groups[1] as List).cast<Map<String, dynamic>>();
    final imagesByProject = <String, List<ProjectImageRecord>>{};
    for (final row in imageRows) {
      final path = row['object_path']?.toString() ?? '';
      if (path.isEmpty) continue;
      imagesByProject
          .putIfAbsent(row['project_id'].toString(), () => [])
          .add(
            ProjectImageRecord(
              url: _client.storage.from('project-images').getPublicUrl(path),
              altText: '${row['alt_text'] ?? ''}',
              sortOrder: _toInt(row['sort_order']),
            ),
          );
    }
    return rows
        .map(
          (row) => ProjectRecord.fromRow(
            row,
            images: imagesByProject[row['id'].toString()] ?? const [],
          ),
        )
        .toList(growable: false);
  }
}

int _toInt(Object? value) =>
    value is num ? value.toInt() : int.tryParse('$value') ?? 0;

num? _toNumOrNull(Object? value) => value == null
    ? null
    : value is num
    ? value
    : num.tryParse('$value');

final catalogueRepositoryProvider = Provider<CatalogueRepository>(
  (ref) => CatalogueRepository(
    ref.watch(supabaseClientProvider),
    ref.watch(readCacheProvider),
  ),
);

final productCatalogueProvider = StreamProvider<ProductCatalogue>(
  (ref) => ref.watch(catalogueRepositoryProvider).watchProducts(),
);

final projectCatalogueProvider = StreamProvider<List<ProjectRecord>>(
  (ref) => ref.watch(catalogueRepositoryProvider).watchProjects(),
);

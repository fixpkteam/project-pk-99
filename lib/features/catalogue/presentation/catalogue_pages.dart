import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/providers.dart';
import '../../../core/widgets/components.dart';
import '../../foundation/presentation/foundation_pages.dart' show PageBody;
import '../data/catalogue_repository.dart';

String _money(num? amount, String currency) {
  if (amount == null) return 'Request a quote';
  final formatted = amount % 1 == 0
      ? amount.toStringAsFixed(0)
      : amount.toStringAsFixed(2);
  return '$currency $formatted';
}

Widget _catalogueImage(
  String? url,
  String semanticLabel, {
  double height = 180,
}) => Semantics(
  label: semanticLabel,
  image: true,
  child: SizedBox(
    height: height,
    width: double.infinity,
    child: url == null || url.isEmpty
        ? const ColoredBox(
            color: Color(0xFFF3F5F8),
            child: Center(
              child: Icon(Icons.image_outlined, size: 36, color: Colors.grey),
            ),
          )
        : Image.network(
            url,
            fit: BoxFit.cover,
            errorBuilder: (_, _, _) => const ColoredBox(
              color: Color(0xFFF3F5F8),
              child: Center(
                child: Icon(
                  Icons.broken_image_outlined,
                  size: 36,
                  color: Colors.grey,
                ),
              ),
            ),
          ),
  ),
);

class ProductsPage extends ConsumerStatefulWidget {
  const ProductsPage({super.key, this.enquiryContext});
  final String? enquiryContext;

  @override
  ConsumerState<ProductsPage> createState() => _ProductsPageState();
}

class _ProductsPageState extends ConsumerState<ProductsPage> {
  final _search = TextEditingController();
  String _query = '';
  String? _categoryId;

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (ref.watch(configProvider).preview) {
      return _previewPage(
        context,
        title: 'Products',
        message: 'Connect the FixPK catalogue to browse verified products and request current pricing.',
        icon: Icons.inventory_2_outlined,
      );
    }
    final catalogue = ref.watch(productCatalogueProvider);
    final query = _query.trim().toLowerCase();
    return Scaffold(
      appBar: AppBar(title: const Text('Products')),
      body: SafeArea(
        child: catalogue.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (_, _) => AppStatePanel(
            title: 'Products could not load',
            message: 'Check your connection and try again.',
            isError: true,
            actionLabel: 'Retry',
            onAction: () => ref.invalidate(productCatalogueProvider),
          ),
          data: (data) {
            final products = data.products.where((product) {
              final categoryMatches =
                  _categoryId == null || product.categoryId == _categoryId;
              final searchMatches =
                  '${product.name} ${product.summary} ${product.sku}'
                      .toLowerCase()
                      .contains(query);
              return categoryMatches && searchMatches;
            }).toList();
            return ListView(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
              children: [
                Text(
                  'Products and solutions',
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
                const SizedBox(height: 8),
                const Text(
                  'Browse FixPK products. Availability and final pricing are confirmed by our team.',
                ),
                if (widget.enquiryContext?.isNotEmpty == true) ...[
                  const SizedBox(height: 16),
                  _EnquiryContextCard(message: widget.enquiryContext!),
                ],
                const SizedBox(height: 20),
                AppSearchField(
                  controller: _search,
                  onChanged: (value) => setState(() => _query = value),
                ),
                if (data.categories.isNotEmpty) ...[
                  const SizedBox(height: 16),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      FilterChip(
                        label: const Text('All'),
                        selected: _categoryId == null,
                        onSelected: (_) => setState(() => _categoryId = null),
                      ),
                      for (final category in data.categories)
                        FilterChip(
                          label: Text(category.name),
                          selected: _categoryId == category.id,
                          onSelected: (_) => setState(
                            () => _categoryId = _categoryId == category.id
                                ? null
                                : category.id,
                          ),
                        ),
                    ],
                  ),
                ],
                const SizedBox(height: 16),
                if (products.isEmpty)
                  AppStatePanel(
                    title: data.products.isEmpty
                        ? 'Products are being prepared'
                        : 'No matching products',
                    message: data.products.isEmpty
                        ? 'Please check back soon or contact FixPK for help.'
                        : 'Try another search or clear the category filter.',
                    icon: Icons.inventory_2_outlined,
                    actionLabel: data.products.isEmpty ? null : 'Clear filters',
                    onAction: data.products.isEmpty
                        ? null
                        : () => setState(() {
                            _categoryId = null;
                            _query = '';
                            _search.clear();
                          }),
                  )
                else
                  for (final product in products) ...[
                    _ProductCard(
                      product: product,
                      onTap: () => context.push(
                        '/products/${Uri.encodeComponent(product.id)}',
                        extra: widget.enquiryContext,
                      ),
                    ),
                    const SizedBox(height: 12),
                  ],
              ],
            );
          },
        ),
      ),
    );
  }
}

class _ProductCard extends StatelessWidget {
  const _ProductCard({required this.product, required this.onTap});
  final ProductRecord product;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => ContentCard(
    onTap: onTap,
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: _catalogueImage(
            product.images.isEmpty ? null : product.images.first.url,
            product.images.isEmpty ? 'No product image' : product.name,
            height: 160,
          ),
        ),
        const SizedBox(height: 12),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Text(
                product.name,
                style: Theme.of(context).textTheme.titleMedium,
              ),
            ),
            StatusChip(
              label: product.isAvailable ? 'Available' : 'Enquire',
              tone: product.isAvailable
                  ? StatusTone.success
                  : StatusTone.neutral,
            ),
          ],
        ),
        if (product.summary.isNotEmpty) ...[
          const SizedBox(height: 4),
          Text(product.summary, maxLines: 3, overflow: TextOverflow.ellipsis),
        ],
        const SizedBox(height: 8),
        Text(
          _money(product.price, product.currency),
          style: Theme.of(context).textTheme.titleSmall,
        ),
        const SizedBox(height: 12),
        const Align(
          alignment: Alignment.centerRight,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('View details'),
              SizedBox(width: 4),
              Icon(Icons.arrow_forward, size: 16),
            ],
          ),
        ),
      ],
    ),
  );
}

class ProductDetailPage extends ConsumerWidget {
  const ProductDetailPage({
    super.key,
    required this.productId,
    this.enquiryContext,
  });
  final String productId;
  final String? enquiryContext;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (ref.watch(configProvider).preview) {
      return _previewPage(
        context,
        title: 'Product details',
        message:
            'Connect Supabase to view the live product and specifications.',
        icon: Icons.inventory_2_outlined,
      );
    }
    final catalogue = ref.watch(productCatalogueProvider);
    return Scaffold(
      appBar: AppBar(title: const Text('Product details')),
      body: SafeArea(
        child: catalogue.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (_, _) => AppStatePanel(
            title: 'Product could not load',
            message: 'Check your connection and try again.',
            isError: true,
            actionLabel: 'Retry',
            onAction: () => ref.invalidate(productCatalogueProvider),
          ),
          data: (data) {
            final matches = data.products.where((item) => item.id == productId);
            if (matches.isEmpty) {
              return const AppStatePanel(
                title: 'Product not found',
                message:
                    'It may no longer be published in the FixPK catalogue.',
              );
            }
            final product = matches.first;
            return ListView(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
              children: [
                if (product.images.isNotEmpty)
                  ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: _catalogueImage(
                      product.images.first.url,
                      product.images.first.altText.isEmpty
                          ? product.name
                          : product.images.first.altText,
                      height: 230,
                    ),
                  )
                else
                  ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: _catalogueImage(
                      null,
                      'No product image',
                      height: 180,
                    ),
                  ),
                if (product.images.length > 1) ...[
                  const SizedBox(height: 8),
                  SizedBox(
                    height: 72,
                    child: ListView.separated(
                      scrollDirection: Axis.horizontal,
                      itemCount: product.images.length,
                      separatorBuilder: (_, _) => const SizedBox(width: 8),
                      itemBuilder: (context, index) => ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: _catalogueImage(
                          product.images[index].url,
                          product.images[index].altText,
                          height: 72,
                        ),
                      ),
                    ),
                  ),
                ],
                const SizedBox(height: 20),
                Text(
                  product.name,
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
                if (product.sku.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(
                    'SKU ${product.sku}',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],
                const SizedBox(height: 8),
                Text(
                  _money(product.price, product.currency),
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 8),
                StatusChip(
                  label: product.isAvailable
                      ? 'Available to enquire'
                      : 'Availability by enquiry',
                  tone: product.isAvailable
                      ? StatusTone.success
                      : StatusTone.neutral,
                ),
                if (product.summary.isNotEmpty) ...[
                  const SizedBox(height: 16),
                  Text(
                    product.summary,
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                ],
                if (product.description.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  Text(product.description),
                ],
                if (product.specifications.isNotEmpty) ...[
                  const SizedBox(height: 24),
                  Text(
                    'Specifications',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 8),
                  ContentCard(
                    child: Column(
                      children: [
                        for (
                          var i = 0;
                          i < product.specifications.length;
                          i++
                        ) ...[
                          if (i > 0) const Divider(height: 16),
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Expanded(
                                child: Text(product.specifications[i].name),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: Text(
                                  product.specifications[i].value,
                                  textAlign: TextAlign.end,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
                if (enquiryContext?.isNotEmpty == true) ...[
                  const SizedBox(height: 20),
                  _EnquiryContextCard(message: enquiryContext!),
                ],
                const SizedBox(height: 24),
                AppButton(
                  label: 'Request a product quote',
                  icon: Icons.request_quote_outlined,
                  onPressed: () => context.go(
                    '/services?enquiry=${Uri.encodeQueryComponent(_productEnquiry(product))}',
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Choose a relevant FixPK service. The product and SKU will be included in your service request.',
                  textAlign: TextAlign.center,
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

class ProjectsPage extends ConsumerWidget {
  const ProjectsPage({super.key, this.enquiryContext});
  final String? enquiryContext;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (ref.watch(configProvider).preview) {
      return PageBody(
        children: [
          AppStatePanel(
            title: 'Connect to see FixPK projects',
            message:
                'Connect the FixPK project catalogue to browse verified work.',
            icon: Icons.apartment_outlined,
            actionLabel: 'Browse services',
            onAction: () => context.go('/services'),
          ),
        ],
      );
    }
    final projects = ref.watch(projectCatalogueProvider);
    return SafeArea(
      child: projects.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (_, _) => AppStatePanel(
          title: 'Projects could not load',
          message: 'Check your connection and try again.',
          isError: true,
          actionLabel: 'Retry',
          onAction: () => ref.invalidate(projectCatalogueProvider),
        ),
        data: (items) => items.isEmpty
            ? const AppStatePanel(
                title: 'Project portfolio is being prepared',
                message: 'Please check back soon for completed FixPK projects.',
                icon: Icons.apartment_outlined,
              )
            : ListView(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
                children: [
                  Text(
                    'Selected projects',
                    style: Theme.of(context).textTheme.headlineSmall,
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Explore work completed for homes, businesses and industrial sites.',
                  ),
                  if (enquiryContext?.isNotEmpty == true) ...[
                    const SizedBox(height: 16),
                    _EnquiryContextCard(message: enquiryContext!),
                  ],
                  const SizedBox(height: 16),
                  for (final project in items) ...[
                    _ProjectCard(
                      project: project,
                      onTap: () => context.push('/projects/${project.id}'),
                    ),
                    const SizedBox(height: 12),
                  ],
                ],
              ),
      ),
    );
  }
}

class _ProjectCard extends StatelessWidget {
  const _ProjectCard({required this.project, required this.onTap});
  final ProjectRecord project;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => ContentCard(
    onTap: onTap,
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: _catalogueImage(
            project.images.isEmpty ? null : project.images.first.url,
            project.images.isEmpty
                ? 'No project image'
                : project.images.first.altText,
            height: 180,
          ),
        ),
        const SizedBox(height: 12),
        Text(project.title, style: Theme.of(context).textTheme.titleMedium),
        if (project.category.isNotEmpty || project.location.isNotEmpty) ...[
          const SizedBox(height: 4),
          Text(
            [
              project.category,
              project.location,
            ].where((value) => value.isNotEmpty).join(' · '),
          ),
        ],
        if (project.summary.isNotEmpty) ...[
          const SizedBox(height: 8),
          Text(project.summary, maxLines: 3, overflow: TextOverflow.ellipsis),
        ],
        if (project.completedOn != null) ...[
          const SizedBox(height: 8),
          Text(
            'Completed ${MaterialLocalizations.of(context).formatMediumDate(project.completedOn!)}',
          ),
        ],
      ],
    ),
  );
}

class ProjectDetailPage extends ConsumerWidget {
  const ProjectDetailPage({super.key, required this.projectId});
  final String projectId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (ref.watch(configProvider).preview) {
      return _previewPage(
        context,
        title: 'Project details',
        message: 'Connect Supabase to view verified project details.',
        icon: Icons.apartment_outlined,
      );
    }
    final projects = ref.watch(projectCatalogueProvider);
    return Scaffold(
      appBar: AppBar(title: const Text('Project details')),
      body: SafeArea(
        child: projects.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (_, _) => AppStatePanel(
            title: 'Project could not load',
            message: 'Check your connection and try again.',
            isError: true,
            actionLabel: 'Retry',
            onAction: () => ref.invalidate(projectCatalogueProvider),
          ),
          data: (items) {
            final matches = items.where((item) => item.id == projectId);
            if (matches.isEmpty) {
              return const AppStatePanel(
                title: 'Project not found',
                message:
                    'It may no longer be published in the FixPK portfolio.',
              );
            }
            final project = matches.first;
            return ListView(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
              children: [
                for (final image in project.images) ...[
                  ClipRRect(
                    borderRadius: BorderRadius.circular(10),
                    child: _catalogueImage(
                      image.url,
                      image.altText.isEmpty ? project.title : image.altText,
                      height: 220,
                    ),
                  ),
                  const SizedBox(height: 10),
                ],
                Text(
                  project.title,
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
                if (project.category.isNotEmpty ||
                    project.location.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Text(
                    [
                      project.category,
                      project.location,
                    ].where((value) => value.isNotEmpty).join(' · '),
                  ),
                ],
                if (project.completedOn != null) ...[
                  const SizedBox(height: 8),
                  Text(
                    'Completed ${MaterialLocalizations.of(context).formatMediumDate(project.completedOn!)}',
                  ),
                ],
                if (project.summary.isNotEmpty) ...[
                  const SizedBox(height: 20),
                  Text(
                    project.summary,
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                ],
                if (project.description.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  Text(project.description),
                ],
                const SizedBox(height: 24),
                AppButton(
                  label: 'Need a similar project?',
                  onPressed: () => context.go(
                    '/services?enquiry=${Uri.encodeQueryComponent(_projectEnquiry(project))}',
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Choose a related service. This project will be included in your request for FixPK.',
                  textAlign: TextAlign.center,
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _EnquiryContextCard extends StatelessWidget {
  const _EnquiryContextCard({required this.message});
  final String message;

  @override
  Widget build(BuildContext context) => ContentCard(
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Icon(Icons.info_outline),
        const SizedBox(width: 12),
        Expanded(child: Text('Enquiry context: $message')),
      ],
    ),
  );
}

Widget _previewPage(
  BuildContext context, {
  required String title,
  required String message,
  required IconData icon,
}) => Scaffold(
  appBar: AppBar(title: Text(title)),
  body: SafeArea(
    child: Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: AppStatePanel(
          title: 'Connect to see the live catalogue',
          message: message,
          icon: icon,
          actionLabel: 'Browse services',
          onAction: () => context.go('/services'),
        ),
      ),
    ),
  ),
);

String _productEnquiry(ProductRecord product) =>
    'Product quote: ${product.name}${product.sku.isEmpty ? '' : ' (SKU ${product.sku})'}';

String _projectEnquiry(ProjectRecord project) =>
    'Similar project: ${project.title} (Project reference ${project.id})${project.location.isEmpty ? '' : ' in ${project.location}'}';

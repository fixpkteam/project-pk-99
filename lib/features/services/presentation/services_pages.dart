import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/providers.dart';
import '../../../core/widgets/components.dart';
import '../../../features/foundation/presentation/foundation_pages.dart'
    show PageBody, foundationServices;
import '../data/services_repository.dart';

IconData _serviceIcon(String value) {
  final name = value.toLowerCase();
  if (name.contains('solar')) return Icons.solar_power_outlined;
  if (name.contains('geyser') || name.contains('water')) {
    return Icons.water_drop_outlined;
  }
  if (name.contains('cctv') || name.contains('security')) {
    return Icons.videocam_outlined;
  }
  if (name.contains('hvac') || name.contains('ac')) {
    return Icons.ac_unit;
  }
  if (name.contains('elect')) {
    return Icons.bolt_outlined;
  }
  if (name.contains('print') || name.contains('brand')) {
    return Icons.print_outlined;
  }
  if (name.contains('glass') || name.contains('aluminium')) {
    return Icons.window_outlined;
  }
  if (name.contains('upvc') || name.contains('window')) {
    return Icons.door_front_door_outlined;
  }
  if (name.contains('construction') || name.contains('renovat')) {
    return Icons.construction;
  }
  return Icons.handyman_outlined;
}

class ServicesPage extends ConsumerStatefulWidget {
  const ServicesPage({super.key, this.enquiryContext});
  final String? enquiryContext;
  @override
  ConsumerState<ServicesPage> createState() => _ServicesPageState();
}

class _ServicesPageState extends ConsumerState<ServicesPage> {
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
    final preview = ref.watch(configProvider).preview;
    final catalogue = preview ? null : ref.watch(serviceCatalogueProvider);
    final normalized = _query.trim().toLowerCase();

    return PageBody(
      storageKey: 'services',
      children: [
        Text(
          'Services for every property',
          style: Theme.of(context).textTheme.headlineSmall,
        ),
        const SizedBox(height: 8),
        const Text(
          'Explore FixPK solutions for homes, businesses and industrial sites.',
        ),
        if (widget.enquiryContext?.isNotEmpty == true) ...[
          const SizedBox(height: 16),
          ContentCard(
            child: Text(
              'Your enquiry: ${widget.enquiryContext}. Choose a related service to continue.',
            ),
          ),
        ],
        const SizedBox(height: 20),
        AppSearchField(
          controller: _search,
          onChanged: (value) => setState(() => _query = value),
        ),
        const SizedBox(height: 20),
        if (preview)
          _previewServices(normalized)
        else
          catalogue!.when(
            loading: () => const Center(
              child: Padding(
                padding: EdgeInsets.all(32),
                child: CircularProgressIndicator(
                  semanticsLabel: 'Loading services',
                ),
              ),
            ),
            error: (error, stack) => AppStatePanel(
              title: 'Services could not load',
              message: 'Check your connection and try again.',
              icon: Icons.cloud_off_outlined,
              isError: true,
              actionLabel: 'Retry',
              onAction: () => ref.invalidate(serviceCatalogueProvider),
            ),
            data: (data) => _catalogueServices(data, normalized),
          ),
      ],
    );
  }

  Widget _previewServices(String query) {
    final matches = foundationServices.where(
      (service) =>
          '${service.title} ${service.subtitle}'.toLowerCase().contains(query),
    );
    if (matches.isEmpty) {
      return AppStatePanel(
        title: 'No matching services',
        message: 'Try another name or clear your search.',
        actionLabel: 'Clear search',
        onAction: () => setState(() {
          _query = '';
          _search.clear();
        }),
      );
    }
    return Column(
      children: [
        for (final service in matches) ...[
          ServiceCard(
            title: service.title,
            subtitle: service.subtitle,
            icon: service.icon,
            onTap: () => _showPreviewDetail(service.title, service.subtitle),
          ),
          const SizedBox(height: 12),
        ],
      ],
    );
  }

  Widget _catalogueServices(ServiceCatalogue data, String query) {
    final categories = data.categories.where(
      (category) => '${category.name} ${category.description}'
          .toLowerCase()
          .contains(query),
    );
    final services = data.services.where((service) {
      final categoryMatches =
          _categoryId == null || service.categoryId == _categoryId;
      final searchMatches = '${service.name} ${service.description}'
          .toLowerCase()
          .contains(query);
      return categoryMatches && searchMatches;
    }).toList();
    if (data.categories.isEmpty && data.services.isEmpty) {
      return const AppStatePanel(
        title: 'Services are being prepared',
        message: 'Please check back soon or contact FixPK for help.',
        icon: Icons.handyman_outlined,
      );
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (data.categories.isNotEmpty) ...[
          Text('Categories', style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              FilterChip(
                label: const Text('All'),
                selected: _categoryId == null,
                onSelected: (_) => setState(() => _categoryId = null),
              ),
              for (final category in categories)
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
          const SizedBox(height: 20),
        ],
        Text(
          'Available services',
          style: Theme.of(context).textTheme.titleLarge,
        ),
        const SizedBox(height: 12),
        if (services.isEmpty)
          AppStatePanel(
            title: 'No matching services',
            message: 'Clear the category or search for another service.',
            actionLabel: 'Clear filters',
            onAction: () => setState(() {
              _categoryId = null;
              _query = '';
              _search.clear();
            }),
          ),
        for (final service in services) ...[
          ServiceCard(
            title: service.name,
            subtitle: service.description.isEmpty
                ? 'View service details'
                : service.description,
            icon: _serviceIcon(service.name),
            onTap: () {
              final enquiry = widget.enquiryContext;
              final path = '/services/${Uri.encodeComponent(service.id)}';
              context.push(
                enquiry == null || enquiry.isEmpty
                    ? path
                    : '$path?enquiry=${Uri.encodeQueryComponent(enquiry)}',
              );
            },
          ),
          const SizedBox(height: 12),
        ],
      ],
    );
  }

  void _showPreviewDetail(String title, String description) {
    showModalBottomSheet<void>(
      context: context,
      useSafeArea: true,
      builder: (context) => Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 8),
            Text(description),
            const SizedBox(height: 16),
            const Text(
              'Connect Supabase to load the live catalogue and submit a service request.',
            ),
            const SizedBox(height: 12),
            Align(
              alignment: Alignment.centerRight,
              child: TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Close'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class ServiceDetailPage extends ConsumerWidget {
  const ServiceDetailPage({
    super.key,
    required this.serviceId,
    this.enquiryContext,
  });
  final String serviceId;
  final String? enquiryContext;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (ref.watch(configProvider).preview) {
      return Scaffold(
        appBar: AppBar(title: const Text('Service details')),
        body: SafeArea(
          child: PageBody(
            children: [
              const Icon(Icons.handyman_outlined, size: 40),
              const SizedBox(height: 16),
              Text(
                'FixPK service',
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              const SizedBox(height: 12),
              const Text(
                'Connect the Supabase environment to open live service details.',
              ),
            ],
          ),
        ),
      );
    }
    final catalogue = ref.watch(serviceCatalogueProvider);
    return Scaffold(
      appBar: AppBar(title: const Text('Service details')),
      body: SafeArea(
        child: catalogue.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (_, _) =>
              const Center(child: Text('Service details are unavailable.')),
          data: (data) {
            final matches = data.services.where((item) => item.id == serviceId);
            if (matches.isEmpty) {
              return const Center(
                child: Text('This service is no longer available.'),
              );
            }
            final service = matches.first;
            return PageBody(
              children: [
                Icon(_serviceIcon(service.name), size: 40),
                const SizedBox(height: 16),
                Text(
                  service.name,
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
                const SizedBox(height: 12),
                Text(
                  service.description.isEmpty
                      ? 'Contact FixPK to discuss requirements and arrange a quotation.'
                      : service.description,
                ),
                if (enquiryContext?.isNotEmpty == true) ...[
                  const SizedBox(height: 16),
                  ContentCard(child: Text('Enquiry context: $enquiryContext')),
                ],
                const SizedBox(height: 24),
                AppButton(
                  label: 'Request this service',
                  onPressed: () {
                    final base =
                        '/requests/new?serviceId=${Uri.encodeComponent(service.id)}';
                    final enquiry = enquiryContext;
                    context.push(
                      enquiry == null || enquiry.isEmpty
                          ? base
                          : '$base&context=${Uri.encodeQueryComponent(enquiry)}',
                    );
                  },
                ),
                const SizedBox(height: 8),
                const Text(
                  'Tell FixPK what you need and add the property details.',
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

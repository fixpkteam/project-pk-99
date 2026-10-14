import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/providers.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/components.dart';
import '../../foundation/presentation/foundation_pages.dart' show PageBody;
import '../data/services_repository.dart';
import 'service_visuals.dart';

class ServicesPage extends ConsumerStatefulWidget {
  const ServicesPage({
    super.key,
    this.enquiryContext,
    this.initialCategory,
    this.focusSearch = false,
  });
  final String? enquiryContext;
  final String? initialCategory;
  final bool focusSearch;
  @override
  ConsumerState<ServicesPage> createState() => _ServicesPageState();
}

class _ServicesPageState extends ConsumerState<ServicesPage> {
  final _search = TextEditingController();
  final _focus = FocusNode();
  String _query = '';
  String _audience = 'all';
  @override
  void didUpdateWidget(covariant ServicesPage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.initialCategory != widget.initialCategory) {
      _search.clear();
      _query = '';
      _audience = 'all';
    }
    if (widget.focusSearch && !oldWidget.focusSearch) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _focus.requestFocus();
      });
    }
  }

  @override
  void dispose() {
    _search.dispose();
    _focus.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final preview = ref.watch(configProvider).preview;
    final state = preview
        ? AsyncData(_previewCatalogue())
        : ref.watch(serviceCatalogueProvider);
    return ColoredBox(
      color: const Color(0xFFF8FAFD),
      child: Align(
        alignment: Alignment.topCenter,
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 720),
          child: RefreshIndicator(
            onRefresh: () async {
              if (!preview) ref.invalidate(serviceCatalogueProvider);
            },
            child: CustomScrollView(
              key: PageStorageKey(
                'services:${widget.initialCategory ?? 'all'}',
              ),
              keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
              physics: const AlwaysScrollableScrollPhysics(),
              slivers: [
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
                  sliver: SliverToBoxAdapter(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        TextField(
                          controller: _search,
                          focusNode: _focus,
                          autofocus: widget.focusSearch,
                          onChanged: (value) => setState(
                            () => _query = value.trim().toLowerCase(),
                          ),
                          textInputAction: TextInputAction.search,
                          decoration: InputDecoration(
                            hintText: 'Search services…',
                            prefixIcon: const Icon(Icons.search_rounded),
                            suffixIcon: _query.isEmpty
                                ? null
                                : IconButton(
                                    tooltip: 'Clear search',
                                    icon: const Icon(Icons.close),
                                    onPressed: () => setState(() {
                                      _search.clear();
                                      _query = '';
                                    }),
                                  ),
                            filled: true,
                            fillColor: const Color(0xFFEDF2F8),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(28),
                              borderSide: BorderSide.none,
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(28),
                              borderSide: BorderSide.none,
                            ),
                          ),
                        ),
                        const SizedBox(height: 12),
                        SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          child: Row(
                            children: [
                              for (final choice in const {
                                'all': 'All',
                                'residential': 'Residential',
                                'commercial': 'Commercial',
                                'industrial': 'Industrial',
                              }.entries)
                                Padding(
                                  padding: const EdgeInsets.only(right: 8),
                                  child: ChoiceChip(
                                    label: Text(choice.value),
                                    selected: _audience == choice.key,
                                    showCheckmark: false,
                                    selectedColor: FixPkColors.action,
                                    backgroundColor: const Color(0xFFEDF2F8),
                                    side: BorderSide.none,
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 8,
                                      vertical: 10,
                                    ),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(16),
                                    ),
                                    labelStyle: TextStyle(
                                      color: _audience == choice.key
                                          ? Colors.white
                                          : FixPkColors.body,
                                      fontWeight: FontWeight.w600,
                                    ),
                                    onSelected: (_) =>
                                        setState(() => _audience = choice.key),
                                  ),
                                ),
                            ],
                          ),
                        ),
                        if (widget.enquiryContext?.isNotEmpty == true) ...[
                          const SizedBox(height: 12),
                          ContentCard(
                            child: Text(
                              'Your enquiry: ${widget.enquiryContext}',
                            ),
                          ),
                        ],
                        const SizedBox(height: 14),
                      ],
                    ),
                  ),
                ),
                ...state.when(
                  loading: () => [
                    SliverPadding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      sliver: SliverList.builder(
                        itemCount: 5,
                        itemBuilder: (_, _) => const Padding(
                          padding: EdgeInsets.only(bottom: 10),
                          child: _ServiceSkeleton(),
                        ),
                      ),
                    ),
                  ],
                  error: (_, _) => [
                    SliverToBoxAdapter(
                      child: AppStatePanel(
                        title: 'Services could not load',
                        message: 'Check your connection and try again.',
                        isError: true,
                        actionLabel: 'Retry',
                        onAction: () =>
                            ref.invalidate(serviceCatalogueProvider),
                      ),
                    ),
                  ],
                  data: (data) => _rows(data, preview),
                ),
                const SliverToBoxAdapter(child: SizedBox(height: 24)),
              ],
            ),
          ),
        ),
      ),
    );
  }

  List<Widget> _rows(ServiceCatalogue data, bool preview) {
    final selected = data.categories
        .where(
          (c) =>
              c.slug == widget.initialCategory ||
              c.id == widget.initialCategory,
        )
        .firstOrNull;
    final categories = data.categories
        .where((c) => _audience == 'all' || c.audiences.contains(_audience))
        .toList();
    final eligible = categories.map((c) => c.id).toSet();
    final services = data.services
        .where(
          (s) =>
              eligible.contains(s.categoryId) &&
              (selected == null || selected.id == s.categoryId) &&
              '${s.name} ${s.description}'.toLowerCase().contains(_query),
        )
        .toList();
    final showServices = selected != null || _query.isNotEmpty;
    final count = showServices ? services.length : categories.length;
    return [
      if (selected != null)
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    selected.name,
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                ),
                TextButton(
                  onPressed: () => context.go('/services'),
                  child: const Text('All services'),
                ),
              ],
            ),
          ),
        ),
      if (count == 0)
        SliverToBoxAdapter(
          child: AppStatePanel(
            title: data.categories.isEmpty
                ? 'Services are being prepared'
                : 'No matching services',
            message: data.categories.isEmpty
                ? 'Contact FixPK for help with your project.'
                : 'Try another name or clear your filters.',
            actionLabel: data.categories.isEmpty
                ? 'Contact support'
                : 'Clear filters',
            onAction: () {
              if (data.categories.isEmpty) {
                context.push('/account/support');
                return;
              }
              setState(() {
                _search.clear();
                _query = '';
                _audience = 'all';
              });
              if (widget.initialCategory != null) context.go('/services');
            },
          ),
        ),
      SliverPadding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        sliver: SliverList.builder(
          itemCount: count,
          itemBuilder: (context, index) {
            if (showServices) {
              final service = services[index];
              final category = data.categories.firstWhere(
                (c) => c.id == service.categoryId,
              );
              return ServiceRow(
                title: service.name,
                subtitle: service.description,
                artwork: category.iconName.isEmpty
                    ? category.name
                    : category.iconName,
                onTap: () => _openService(service, preview),
              );
            }
            final category = categories[index];
            return ServiceRow(
              title: category.name,
              subtitle: category.description,
              artwork: category.iconName.isEmpty
                  ? category.name
                  : category.iconName,
              onTap: () {
                final matching = data.services
                    .where((s) => s.categoryId == category.id)
                    .toList();
                if (matching.length == 1) {
                  _openService(matching.single, preview);
                  return;
                }
                final slug = Uri.encodeQueryComponent(
                  category.slug.isEmpty ? category.id : category.slug,
                );
                final enquiry = widget.enquiryContext;
                context.go(
                  '/services?category=$slug${enquiry == null ? '' : '&enquiry=${Uri.encodeQueryComponent(enquiry)}'}',
                );
              },
            );
          },
        ),
      ),
    ];
  }

  void _openService(ServiceItem service, bool preview) {
    if (preview) {
      showModalBottomSheet<void>(
        context: context,
        useSafeArea: true,
        isScrollControlled: true,
        builder: (sheetContext) => SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ServiceArtwork(name: service.name, size: 80),
              const SizedBox(height: 16),
              Text(service.name, style: Theme.of(context).textTheme.titleLarge),
              const SizedBox(height: 8),
              Text(service.description),
              const SizedBox(height: 16),
              const Text(
                'Use the connected FixPK app to submit your requirements.',
              ),
              Align(
                alignment: Alignment.centerRight,
                child: TextButton(
                  onPressed: () => Navigator.pop(sheetContext),
                  child: const Text('Close'),
                ),
              ),
            ],
          ),
        ),
      );
      return;
    }
    final enquiry = widget.enquiryContext;
    context.push(
      '/services/${Uri.encodeComponent(service.id)}${enquiry == null ? '' : '?enquiry=${Uri.encodeQueryComponent(enquiry)}'}',
    );
  }
}

class _ServiceSkeleton extends StatelessWidget {
  const _ServiceSkeleton();
  @override
  Widget build(BuildContext context) => Semantics(
    label: 'Loading services',
    child: Container(
      height: 88,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        children: [
          Container(
            width: 64,
            decoration: BoxDecoration(
              color: FixPkColors.surface,
              borderRadius: BorderRadius.circular(16),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(height: 14, width: 150, color: FixPkColors.surface),
                const SizedBox(height: 10),
                Container(height: 10, width: 190, color: FixPkColors.surface),
              ],
            ),
          ),
        ],
      ),
    ),
  );
}

ServiceCatalogue _previewCatalogue() => ServiceCatalogue(
  categories: [
    for (var i = 0; i < serviceVisuals.length; i++)
      ServiceCategory(
        id: serviceVisuals[i].key,
        slug: serviceVisuals[i].key,
        name: serviceVisuals[i].title,
        description: serviceVisuals[i].subtitle,
        iconName: serviceVisuals[i].key,
        sortOrder: i,
        audiences: serviceVisuals[i].audiences,
      ),
  ],
  services: [
    for (var i = 0; i < serviceVisuals.length; i++)
      if (serviceVisuals[i].key != 'digital')
        ServiceItem(
          id: 'preview-${serviceVisuals[i].key}',
          categoryId: serviceVisuals[i].key,
          name: serviceVisuals[i].title,
          description: serviceVisuals[i].subtitle,
          sortOrder: i,
        ),
    for (final name in const [
      'Website Design & Development',
      'App Development',
      'Social Media Management',
      'Ads & Promotion',
      'Influencer Marketing',
    ])
      ServiceItem(
        id: 'preview-$name',
        categoryId: 'digital',
        name: name,
        description: 'Plan your digital project with FixPK.',
        sortOrder: 20,
      ),
  ],
);

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
                Align(
                  alignment: Alignment.centerLeft,
                  child: ServiceArtwork(name: service.name, size: 96),
                ),
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

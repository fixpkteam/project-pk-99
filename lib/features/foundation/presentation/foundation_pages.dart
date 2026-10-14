import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/widgets/components.dart';

class PageBody extends StatelessWidget {
  const PageBody({super.key, required this.children, this.storageKey});
  final List<Widget> children;
  final String? storageKey;
  @override
  Widget build(BuildContext context) => Align(
    alignment: Alignment.topCenter,
    child: ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 720),
      child: ListView(
        key: storageKey == null ? null : PageStorageKey<String>(storageKey!),
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
        children: children,
      ),
    ),
  );
}

class PlannedPage extends StatelessWidget {
  const PlannedPage({
    super.key,
    required this.title,
    required this.message,
    required this.icon,
  });
  final String title;
  final String message;
  final IconData icon;
  @override
  Widget build(BuildContext context) => PageBody(
    children: [
      AppStatePanel(
        title: title,
        message: message,
        icon: icon,
        actionLabel: 'Explore services',
        onAction: () => context.go('/services'),
      ),
    ],
  );
}

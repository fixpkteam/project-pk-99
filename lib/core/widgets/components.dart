import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

enum ActionKind { primary, secondary, outline, text }

class AppButton extends StatelessWidget {
  const AppButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.kind = ActionKind.primary,
    this.busy = false,
    this.icon,
  });
  final String label;
  final VoidCallback? onPressed;
  final ActionKind kind;
  final bool busy;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    final child = Wrap(
      alignment: WrapAlignment.center,
      crossAxisAlignment: WrapCrossAlignment.center,
      spacing: 8,
      children: [
        if (busy)
          const SizedBox.square(
            dimension: 18,
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
        if (!busy && icon != null) Icon(icon, size: 20),
        Text(busy ? '$label…' : label, textAlign: TextAlign.center),
      ],
    );
    final action = busy ? null : onPressed;
    return switch (kind) {
      ActionKind.primary => FilledButton(onPressed: action, child: child),
      ActionKind.secondary => FilledButton.tonal(
        onPressed: action,
        child: child,
      ),
      ActionKind.outline => OutlinedButton(onPressed: action, child: child),
      ActionKind.text => TextButton(onPressed: action, child: child),
    };
  }
}

enum StatusTone { information, success, warning, error, neutral }

class StatusChip extends StatelessWidget {
  const StatusChip({
    super.key,
    required this.label,
    this.tone = StatusTone.information,
  });
  final String label;
  final StatusTone tone;
  @override
  Widget build(BuildContext context) {
    final (foreground, background) = switch (tone) {
      StatusTone.information => (
        FixPkColors.action,
        FixPkColors.informationSurface,
      ),
      StatusTone.success => (FixPkColors.success, FixPkColors.successSurface),
      StatusTone.warning => (FixPkColors.warning, FixPkColors.warningSurface),
      StatusTone.error => (FixPkColors.error, FixPkColors.errorSurface),
      StatusTone.neutral => (FixPkColors.body, FixPkColors.surface),
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        label,
        style: Theme.of(context).textTheme.labelSmall
            ?.copyWith(color: foreground),
      ),
    );
  }
}

class ContentCard extends StatelessWidget {
  const ContentCard({
    super.key,
    required this.child,
    this.onTap,
    this.semanticLabel,
  });
  final Widget child;
  final VoidCallback? onTap;
  final String? semanticLabel;
  @override
  Widget build(BuildContext context) => Semantics(
    label: semanticLabel,
    button: onTap != null,
    child: Material(
      color: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: const BorderSide(color: FixPkColors.border),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(padding: const EdgeInsets.all(16), child: child),
      ),
    ),
  );
}

class ServiceCard extends StatelessWidget {
  const ServiceCard({
    super.key,
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.onTap,
  });
  final String title;
  final String subtitle;
  final IconData icon;
  final VoidCallback onTap;
  @override
  Widget build(BuildContext context) => ContentCard(
    onTap: onTap,
    child: Row(
      children: [
        ExcludeSemantics(
          child: Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: FixPkColors.informationSurface,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: FixPkColors.action),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 4),
              Text(
                subtitle,
                style: Theme.of(context).textTheme.bodyMedium
                    ?.copyWith(color: FixPkColors.body),
              ),
            ],
          ),
        ),
        const SizedBox(width: 8),
        const ExcludeSemantics(
          child: Icon(Icons.chevron_right, color: FixPkColors.muted),
        ),
      ],
    ),
  );
}

class SummaryCard extends StatelessWidget {
  const SummaryCard({
    super.key,
    required this.title,
    required this.subtitle,
    required this.status,
    required this.onTap,
  });
  final String title;
  final String subtitle;
  final StatusChip status;
  final VoidCallback onTap;
  @override
  Widget build(BuildContext context) => ContentCard(
    onTap: onTap,
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        status,
        const SizedBox(height: 12),
        Text(title, style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 4),
        Text(subtitle, style: Theme.of(context).textTheme.bodyMedium),
      ],
    ),
  );
}

/// Products and projects share the media-card anatomy without fake imagery.
class MediaCard extends StatelessWidget {
  const MediaCard({
    super.key,
    required this.title,
    required this.subtitle,
    required this.action,
    required this.onTap,
    this.image,
  });
  final String title;
  final String subtitle;
  final String action;
  final VoidCallback onTap;
  final Widget? image;
  @override
  Widget build(BuildContext context) => ContentCard(
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: AspectRatio(
            aspectRatio: 16 / 9,
            child:
                image ??
                const ColoredBox(
                  color: FixPkColors.surface,
                  child: Center(
                    child: Icon(
                      Icons.image_outlined,
                      size: 32,
                      color: FixPkColors.muted,
                    ),
                  ),
                ),
          ),
        ),
        const SizedBox(height: 16),
        Text(title, style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 4),
        Text(subtitle),
        const SizedBox(height: 12),
        AppButton(label: action, onPressed: onTap, kind: ActionKind.outline),
      ],
    ),
  );
}

class AppSearchField extends StatelessWidget {
  const AppSearchField({
    super.key,
    required this.controller,
    required this.onChanged,
    this.label = 'Search services',
  });
  final TextEditingController controller;
  final ValueChanged<String> onChanged;
  final String label;
  @override
  Widget build(BuildContext context) => TextField(
    controller: controller,
    onChanged: onChanged,
    textInputAction: TextInputAction.search,
    decoration: InputDecoration(
      labelText: label,
      prefixIcon: const Icon(Icons.search),
      suffixIcon: IconButton(
        tooltip: 'Clear search',
        onPressed: () {
          controller.clear();
          onChanged('');
        },
        icon: const Icon(Icons.close),
      ),
    ),
  );
}

class AppStatePanel extends StatelessWidget {
  const AppStatePanel({
    super.key,
    required this.title,
    required this.message,
    this.icon = Icons.inbox_outlined,
    this.actionLabel,
    this.onAction,
    this.isError = false,
  });
  final String title;
  final String message;
  final IconData icon;
  final String? actionLabel;
  final VoidCallback? onAction;
  final bool isError;
  @override
  Widget build(BuildContext context) => Semantics(
    liveRegion: isError,
    child: Padding(
      padding: const EdgeInsets.symmetric(vertical: 32, horizontal: 16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ExcludeSemantics(
            child: Icon(
              icon,
              size: 40,
              color: isError ? FixPkColors.error : FixPkColors.action,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            title,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 8),
          Text(
            message,
            textAlign: TextAlign.center,
            style: const TextStyle(color: FixPkColors.body),
          ),
          if (actionLabel != null && onAction != null) ...[
            const SizedBox(height: 20),
            AppButton(label: actionLabel!, onPressed: onAction),
          ],
        ],
      ),
    ),
  );
}

class SkeletonCard extends StatelessWidget {
  const SkeletonCard({super.key});
  @override
  Widget build(BuildContext context) => Semantics(
    label: 'Loading content',
    child: ExcludeSemantics(
      child: ContentCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(height: 18, width: 180, color: FixPkColors.surface),
            const SizedBox(height: 12),
            Container(height: 12, color: FixPkColors.surface),
            const SizedBox(height: 8),
            Container(height: 12, width: 220, color: FixPkColors.surface),
          ],
        ),
      ),
    ),
  );
}

class UploadControl extends StatelessWidget {
  const UploadControl({
    super.key,
    required this.onSelect,
    this.filename,
    this.onRemove,
  });
  final VoidCallback onSelect;
  final String? filename;
  final VoidCallback? onRemove;
  @override
  Widget build(BuildContext context) => ContentCard(
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Text(
          'Photos and documents',
          style: TextStyle(fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 8),
        const Text('Images up to 10 MB. PDFs up to 20 MB. Maximum 10 files.'),
        const SizedBox(height: 12),
        AppButton(
          label: 'Choose file',
          icon: Icons.upload_file,
          kind: ActionKind.outline,
          onPressed: onSelect,
        ),
        if (filename != null)
          ListTile(
            contentPadding: EdgeInsets.zero,
            title: Text(filename!),
            trailing: IconButton(
              tooltip: 'Remove file',
              onPressed: onRemove,
              icon: const Icon(Icons.close),
            ),
          ),
      ],
    ),
  );
}

Future<bool> showConfirmation(
  BuildContext context, {
  required String title,
  required String message,
  required String confirmLabel,
}) async =>
    await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(confirmLabel),
          ),
        ],
      ),
    ) ??
    false;

void showFeedback(BuildContext context, String message) {
  ScaffoldMessenger.of(context).hideCurrentSnackBar();
  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
}

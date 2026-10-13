import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/providers.dart';
import '../data/outbox_providers.dart';

/// Mobile operating systems suspend apps. Retry while foregrounded and on
/// resume; do not promise delivery while the app has been force-closed.
class OutboxSync extends ConsumerStatefulWidget {
  const OutboxSync({super.key, required this.child});
  final Widget child;
  @override
  ConsumerState<OutboxSync> createState() => _OutboxSyncState();
}

class _OutboxSyncState extends ConsumerState<OutboxSync>
    with WidgetsBindingObserver {
  Timer? _timer;
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  void _start() {
    _timer?.cancel();
    if (ref.read(configProvider).preview ||
        ref.read(authUserProvider).value == null) {
      return;
    }
    _timer = Timer.periodic(const Duration(seconds: 15), (_) => _sync());
  }

  Future<void> _sync({bool force = false}) async {
    if (!mounted ||
        ref.read(configProvider).preview ||
        ref.read(authUserProvider).value == null) {
      return;
    }
    try {
      await ref.read(requestOutboxProvider).sync(force: force);
    } on Object {
      /* The pending-requests screen exposes local storage failures. */
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _start();
      unawaited(_sync(force: true));
    } else {
      _timer?.cancel();
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    ref.listen(authUserProvider, (before, after) {
      if (before?.value?.id != after.value?.id && after.value != null) {
        _start();
        unawaited(_sync(force: true));
      }
    });
    return widget.child;
  }
}

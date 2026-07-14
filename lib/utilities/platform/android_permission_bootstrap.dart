import 'package:flutter/material.dart';

import '../../services/android_permission_service.dart';

class AndroidPermissionBootstrap extends StatefulWidget {
  const AndroidPermissionBootstrap({required this.child, super.key});

  final Widget child;

  @override
  State<AndroidPermissionBootstrap> createState() =>
      _AndroidPermissionBootstrapState();
}

class _AndroidPermissionBootstrapState
    extends State<AndroidPermissionBootstrap> {
  final _service = const AndroidPermissionService();
  bool _requested = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_requested) return;
    _requested = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _service.requestStartupPermissions();
    });
  }

  @override
  Widget build(BuildContext context) => widget.child;
}

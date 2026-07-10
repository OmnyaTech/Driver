import 'package:flutter/material.dart';

class ScreenActionController {
  VoidCallback? _openCreate;

  bool get canCreate => _openCreate != null;

  void bindCreate(VoidCallback callback) {
    _openCreate = callback;
  }

  void clear() {
    _openCreate = null;
  }

  void openCreate() {
    _openCreate?.call();
  }
}

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../utilities/state/app_session.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final session = context.watch<AppSession>();

    return Scaffold(
      appBar: AppBar(title: const Text('Configuracoes')),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          SwitchListTile(
            value: session.themeMode == ThemeMode.dark,
            onChanged: (_) => session.toggleThemeMode(),
            title: const Text('Tema escuro'),
          ),
        ],
      ),
    );
  }
}

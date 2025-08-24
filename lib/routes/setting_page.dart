import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../utils/theme_mode_notifier.dart';
import 'package:flutter_gen/gen_l10n/S.dart';

class SettingsPage extends StatelessWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final notifier = context.watch<ThemeModeNotifier>();
    final s = S.of(context);

    return Scaffold(
      body: ListView(
        children: [
          const SizedBox(height: 8),
          SwitchListTile(
            title: Text(s?.darkMode ?? 'Dark Mode'),
            subtitle: Text(
              notifier.themeMode == ThemeMode.system
                  ? (s?.followSystem ?? 'Follow system')
                  : notifier.isDark
                  ? (s?.darkModeOn ?? 'Dark mode is ON')
                  : (s?.darkModeOff ?? 'Dark mode is OFF'),
            ),
            value: notifier.isDark,
            onChanged: (bool v) {
              notifier.setMode(v ? ThemeMode.dark : ThemeMode.light);
            },
          ),
          ListTile(
            title: Text(s?.followSystem ?? 'Follow system'),
            trailing: notifier.themeMode == ThemeMode.system
                ? const Icon(Icons.check)
                : null,
            onTap: () => notifier.setMode(ThemeMode.system),
          ),
        ],
      ),
    );
  }
}

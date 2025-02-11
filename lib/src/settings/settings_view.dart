import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import 'settings_controller.dart';
import '../services/auth_service.dart';

/// Displays the various settings that can be customized by the user.
///
/// When a user changes a setting, the SettingsController is updated and
/// Widgets that listen to the SettingsController are rebuilt.
class SettingsView extends StatefulWidget {
  const SettingsView({
    super.key,
    required this.controller,
    this.onNavigateBack,  // Make it optional
  });

  static const routeName = '/settings';

  final SettingsController controller;
  final VoidCallback? onNavigateBack;

  @override
  State<SettingsView> createState() => _SettingsViewState();
}

class _SettingsViewState extends State<SettingsView> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
        automaticallyImplyLeading: false,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: widget.onNavigateBack,
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Theme selection dropdown
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Theme', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                  DropdownButton<ThemeMode>(
                    value: widget.controller.themeMode,
                    onChanged: widget.controller.updateThemeMode,
                    items: const [
                      DropdownMenuItem(
                        value: ThemeMode.system,
                        child: Text('System Theme'),
                      ),
                      DropdownMenuItem(
                        value: ThemeMode.light,
                        child: Text('Light Theme'),
                      ),
                      DropdownMenuItem(
                        value: ThemeMode.dark,
                        child: Text('Dark Theme'),
                      )
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 24),
              // Delete confirmation setting
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Delete Confirmation', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                  Switch(
                    value: widget.controller.showDeleteConfirmation,
                    onChanged: widget.controller.updateShowDeleteConfirmation,
                  ),
                ],
              ),
              const SizedBox(height: 24),
              // Logout section
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Logout', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                  IconButton(
                    icon: const Icon(Icons.logout),
                    onPressed: () {
                      context.read<AuthService>().signOut();
                    },
                  ),
                ],
              ),
              const SizedBox(height: 24),
              // Advanced Settings
              Theme(
                data: Theme.of(context).copyWith(
                  dividerColor: Colors.transparent,
                ),
                child: ExpansionTile(
                  title: const Text('Advanced Settings', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                  controlAffinity: ListTileControlAffinity.leading,
                  textColor: Theme.of(context).textTheme.bodyLarge?.color,
                  iconColor: Theme.of(context).iconTheme.color,
                  children: [
                    // Supabase settings
                    const Padding(
                      padding: EdgeInsets.only(top: 8.0),
                      child: Text('Supabase Settings', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                    ),
                    const SizedBox(height: 8),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16.0),
                      child: TextField(
                        controller: TextEditingController(text: widget.controller.supabaseUrl),
                        decoration: const InputDecoration(
                          labelText: 'Supabase URL',
                          border: OutlineInputBorder(),
                          helperText: 'e.g., https://your-project.supabase.co',
                        ),
                        onSubmitted: (value) async {
                          try {
                            await widget.controller.updateSupabaseUrl(value);
                            if (mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text('Supabase URL updated. Please restart the app.')),
                              );
                            }
                          } catch (e) {
                            if (mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(content: Text('Error: $e')),
                              );
                            }
                          }
                        },
                      ),
                    ),
                    const SizedBox(height: 16),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16.0),
                      child: TextField(
                        controller: TextEditingController(text: widget.controller.supabaseKey),
                        decoration: const InputDecoration(
                          labelText: 'Supabase API Key',
                          border: OutlineInputBorder(),
                          helperText: 'Your project\'s anon/public API key',
                        ),
                        onSubmitted: (value) async {
                          try {
                            await widget.controller.updateSupabaseKey(value);
                            if (mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text('Supabase API key updated. Please restart the app.')),
                              );
                            }
                          } catch (e) {
                            if (mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(content: Text('Error: $e')),
                              );
                            }
                          }
                        },
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              // Version information
              const Text('Version', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              Text(widget.controller.version),
            ],
          ),
        ),
      ),
    );
  }
}

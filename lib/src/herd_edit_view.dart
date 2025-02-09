import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'settings/settings_controller.dart';

class HerdEditView extends StatefulWidget {
  final Map<String, dynamic> herd;
  final SupabaseClient supabaseClient;
  final VoidCallback onHerdChanged;
  final SettingsController settingsController;

  const HerdEditView({
    super.key,
    required this.herd,
    required this.supabaseClient,
    required this.onHerdChanged,
    required this.settingsController,
  });

  @override
  State<HerdEditView> createState() => _HerdEditViewState();
}

class _HerdEditViewState extends State<HerdEditView> {
  late TextEditingController _herdNameController;
  late TextEditingController _numberOfAnimalsController;

  @override
  void initState() {
    super.initState();
    _herdNameController = TextEditingController(text: widget.herd['name'] ?? '');
    _numberOfAnimalsController = TextEditingController(
      text: widget.herd['numberOfAnimals']?.toString() ?? '0'
    );
  }

  Future<void> _saveHerd() async {
    final String name = _herdNameController.text.trim();
    final int? numberOfAnimals = int.tryParse(_numberOfAnimalsController.text);
    final ctx = context;

    if (name.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a herd name')),
      );
      return;
    }

    if (numberOfAnimals == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a valid number of animals')),
      );
      return;
    }

    if (numberOfAnimals < 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Number of animals cannot be negative')),
      );
      return;
    }

    try {
      await widget.supabaseClient
        .from('herds')
        .update({
          'name': name,
          'numberOfAnimals': numberOfAnimals,
        })
        .eq('uid', widget.herd['uid']);
        
      widget.onHerdChanged();
      if (mounted) {
        Navigator.of(ctx).pop();
      }
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $error')),
        );
      }
    }
  }

  Future<void> _toggleHerdStatus() async {
    final ctx = context;
    final bool isCurrentlyActive = widget.herd['active'] ?? true;
    final String action = isCurrentlyActive ? 'Deactivate' : 'Activate';
    bool shouldToggle = true;

    if (widget.settingsController.showDeleteConfirmation && isCurrentlyActive) {
      bool dontShowAgain = false;
      shouldToggle = await showDialog<bool>(
        context: context,
        builder: (BuildContext context) {
          return StatefulBuilder(
            builder: (context, setState) {
              return AlertDialog(
                title: Text('$action Herd'),
                content: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Are you sure you want to $action this herd? '
                      '${isCurrentlyActive ? 'This will hide it from the list but preserve its history.' : ''}'
                    ),
                    if (isCurrentlyActive) ...[
                      const SizedBox(height: 16),
                      CheckboxListTile(
                        title: const Text('Don\'t ask me again'),
                        value: dontShowAgain,
                        onChanged: (value) {
                          setState(() {
                            dontShowAgain = value ?? false;
                          });
                        },
                        controlAffinity: ListTileControlAffinity.leading,
                        contentPadding: EdgeInsets.zero,
                      ),
                    ],
                  ],
                ),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(false),
                    child: const Text('Cancel'),
                  ),
                  FilledButton(
                    onPressed: () {
                      if (dontShowAgain) {
                        widget.settingsController.updateShowDeleteConfirmation(false);
                      }
                      Navigator.of(context).pop(true);
                    },
                    child: Text(action),
                  ),
                ],
              );
            },
          );
        },
      ) ?? false;
    }

    if (!shouldToggle) return;

    try {
      await widget.supabaseClient
        .from('herds')
        .update({'active': !isCurrentlyActive})
        .eq('uid', widget.herd['uid']);
        
      widget.onHerdChanged();
      if (mounted) {
        Navigator.of(ctx).pop();
      }
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $error')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final bool isCurrentlyActive = widget.herd['active'] ?? true;
    final String actionText = isCurrentlyActive ? 'Deactivate' : 'Activate';
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('Edit Herd'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TextField(
              controller: _herdNameController,
              decoration: const InputDecoration(
                labelText: 'Herd Name',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _numberOfAnimalsController,
              decoration: const InputDecoration(
                labelText: 'Number of Animals',
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: 32),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                FilledButton(
                  onPressed: _saveHerd,
                  child: const Text('Save'),
                ),
                OutlinedButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('Cancel'),
                ),
                FilledButton.tonal(
                  onPressed: _toggleHerdStatus,
                  child: Text(
                    actionText,
                    style: TextStyle(
                      color: isCurrentlyActive
                        ? Theme.of(context).colorScheme.error
                        : Theme.of(context).colorScheme.primary,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

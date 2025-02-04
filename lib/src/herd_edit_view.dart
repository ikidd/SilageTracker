import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class HerdEditView extends StatefulWidget {
  final Map<String, dynamic> herd;
  final SupabaseClient supabaseClient;
  final VoidCallback onHerdChanged;

  const HerdEditView({
    super.key,
    required this.herd,
    required this.supabaseClient,
    required this.onHerdChanged,
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

  Future<void> _deactivateHerd() async {
    final ctx = context;
    // Show confirmation dialog
    final bool? confirm = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Deactivate Herd'),
          content: const Text(
            'Are you sure you want to deactivate this herd? '
            'This will hide it from the list but preserve its history.'
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text('Deactivate'),
            ),
          ],
        );
      },
    );

    if (confirm != true) return;

    try {
      await widget.supabaseClient
        .from('herds')
        .update({'active': false})
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
                  onPressed: _deactivateHerd,
                  child: Text(
                    'Deactivate',
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.error,
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

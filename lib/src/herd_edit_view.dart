import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class HerdEditView extends StatefulWidget {
  final Map<String, dynamic> herd;
  final SupabaseClient supabaseClient; // Change to SupabaseClient
  final VoidCallback onHerdChanged; // Add callback parameter

  const HerdEditView({
    super.key,
    required this.herd,
    required this.supabaseClient, // Update parameter
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
    _herdNameController = TextEditingController(text: widget.herd['name']);
    _numberOfAnimalsController = TextEditingController(text: widget.herd['numberOfAnimals'].toString());
  }

  Future<void> _saveHerd() async {
    final String name = _herdNameController.text;
    final int? numberOfAnimals = int.tryParse(_numberOfAnimalsController.text);
    final ctx = context;

    if (name.isNotEmpty && numberOfAnimals != null) {
      final response = await widget.supabaseClient
          .from('herds')
          .update({
            'name': name,
            'numberOfAnimals': numberOfAnimals,
          })
          .eq('id', widget.herd['id'])
          .execute();
      
      if (response.error != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: ${response.error!.message}')),
        );
        return;
      }
      widget.onHerdChanged(); // Call the callback to refresh the herd list
      if (mounted) {
        Navigator.of(ctx).pop();
      }
    }
  }

  Future<void> _deleteHerd() async {
    final ctx = context;
    final response = await widget.supabaseClient
        .from('herds')
        .delete()
        .eq('id', widget.herd['id'])
        .execute();
    
    if (response.error != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: ${response.error!.message}')),
      );
      return;
    }
    
    widget.onHerdChanged(); // Call the callback to refresh the herd list
    if (mounted) {
      Navigator.of(ctx).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Edit Herd'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            TextField(
              controller: _herdNameController,
              decoration: InputDecoration(labelText: 'Herd Name'),
            ),
            TextField(
              controller: _numberOfAnimalsController,
              decoration: InputDecoration(labelText: 'Number of Animals'),
              keyboardType: TextInputType.number,
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                ElevatedButton(
                  onPressed: _saveHerd,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Theme.of(context).primaryColor,
                  ),
                  child: const Text('Save'),
                ),
                ElevatedButton(
                  onPressed: _deleteHerd,
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                  child: const Text('Delete'),
                ),
                ElevatedButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('Cancel'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

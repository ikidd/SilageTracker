import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'herd_edit_view.dart';

class HerdsView extends StatefulWidget {
  final SupabaseClient supabaseClient;

  const HerdsView({
    super.key,
    required this.supabaseClient,
  });

  static const routeName = '/herds';

  @override
  _HerdsViewState createState() => _HerdsViewState();
}

class _HerdsViewState extends State<HerdsView> {
  final TextEditingController _herdNameController = TextEditingController();
  final TextEditingController _numberOfAnimalsController = TextEditingController();
  List<Map<String, dynamic>> _herds = [];

  @override
  void initState() {
    super.initState();
    _loadHerds();
  }

  Future<void> _loadHerds() async {
    try {
      final dynamic response = await widget.supabaseClient
          .from('herds')
          .select()
          .eq('active', true); // Only select active herds
      if (response is List) {
        setState(() {
          _herds = List<Map<String, dynamic>>.from(response);
        });
      }
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading herds: $error')),
        );
      }
    }
  }

  Future<void> _addHerd() async {
    final String name = _herdNameController.text.trim();
    final int? numberOfAnimals = int.tryParse(_numberOfAnimalsController.text);
    final user = widget.supabaseClient.auth.currentUser;

    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please log in to add a herd')),
      );
      return;
    }

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
        .insert({
          'name': name,
          'numberOfAnimals': numberOfAnimals,
          'active': true, // Set active status when creating
        });
      _herdNameController.clear();
      _numberOfAnimalsController.clear();
      _loadHerds();
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
        title: const Text('Herds'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
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
            const SizedBox(height: 16),
            FilledButton(
              onPressed: _addHerd,
              child: const Text('Add Herd'),
            ),
            const SizedBox(height: 24),
            // Header row
            Row(
              children: [
                Expanded(
                  flex: 2,
                  child: Text(
                    'Herd Name',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                ),
                Expanded(
                  flex: 1,
                  child: Text(
                    'Animals',
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                ),
                const SizedBox(width: 48), // Width of IconButton
              ],
            ),
            const Divider(thickness: 2),
            Expanded(
              child: ListView.builder(
                itemCount: _herds.length,
                itemBuilder: (context, index) {
                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4.0),
                    child: Row(
                      children: [
                        Expanded(
                          flex: 2,
                          child: Text(
                            _herds[index]['name'],
                            style: Theme.of(context).textTheme.bodyLarge,
                          ),
                        ),
                        Expanded(
                          flex: 1,
                          child: Text(
                            '${_herds[index]['numberOfAnimals'] ?? 0}',
                            textAlign: TextAlign.center,
                            style: Theme.of(context).textTheme.bodyLarge,
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.edit),
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => HerdEditView(
                                  herd: _herds[index],
                                  supabaseClient: widget.supabaseClient,
                                  onHerdChanged: _loadHerds,
                                ),
                              ),
                            );
                          },
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

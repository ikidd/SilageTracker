import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'herd_edit_view.dart';

class HerdsView extends StatefulWidget {
  final SupabaseClient supabaseClient; // Add SupabaseClient parameter

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
    final response = await widget.supabaseClient
        .from('herds')
        .select()
        .execute();
    if (response.error == null && response.data is List) {
      setState(() {
        _herds = (response.data as List).cast<Map<String, dynamic>>();
      });
    }
  }

  Future<void> _addHerd() async {
    final String name = _herdNameController.text;
    final int? numberOfAnimals = int.tryParse(_numberOfAnimalsController.text);

    if (name.isNotEmpty && numberOfAnimals != null) {
      final response = await widget.supabaseClient
          .from('herds')
          .insert({
            'name': name,
            'numberOfAnimals': numberOfAnimals,
          })
          .execute();
      if (response.error != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: ${response.error!.message}')),
        );
        return;
      }
      _herdNameController.clear();
      _numberOfAnimalsController.clear();
      _loadHerds();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Herds'),
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
            ElevatedButton(
              onPressed: _addHerd,
              child: Text('Add'),
            ),
            SizedBox(height: 20),
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
                SizedBox(width: 48), // Width of IconButton
              ],
            ),
            Divider(thickness: 2),
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
                            '${_herds[index]['numberOfAnimals']}',
                            textAlign: TextAlign.center,
                            style: Theme.of(context).textTheme.bodyLarge,
                          ),
                        ),
                        IconButton(
                          icon: Icon(Icons.edit),
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

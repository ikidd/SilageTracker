import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'in_progress_screen.dart';

class SilageEntryView extends StatefulWidget {
  const SilageEntryView({super.key, required this.supabaseClient});
  final SupabaseClient supabaseClient;
  static const routeName = '/silage-entry';

  @override
  State<SilageEntryView> createState() => _SilageEntryViewState();
}

class _SilageEntryViewState extends State<SilageEntryView> {
  final TextEditingController _loadSizeController = TextEditingController(text: '0');
  final TextEditingController _grainPercentageController = TextEditingController(text: '0');
  String _result = '';
  List<Map<String, dynamic>> _herds = [];
  List<Map<String, dynamic>> _silageEntries = [];
  Map<String, dynamic>? _selectedHerd;

  @override
  void initState() {
    super.initState();
    _loadHerds();
    _loadSilageEntries();
  }

  Future<void> _loadHerds() async {
    print('Loading herds...'); // Corrected debug log
    try {
      final dynamic response = await widget.supabaseClient
          .from('herds')
          .select();
      print('Herds loaded: $response'); // Debug log
      if (response is List) {
        setState(() {
          _herds = List<Map<String, dynamic>>.from(response);
        });
      }
    } catch (error) {
      print('Error loading herds: $error'); // Error handling
    }
  }

  Future<void> _loadSilageEntries() async {
    print('Loading silage entries...'); // Debug log
    try {
      final dynamic response = await widget.supabaseClient
          .from('silage_fed')
          .select('*, herds(name)')
          .order('created_at', ascending: false)
          .limit(10);
      print('Silage entries loaded: $response'); // Debug log
      if (response is List) {
        setState(() {
          _silageEntries = List<Map<String, dynamic>>.from(response);
        });
      }
    } catch (error) {
      print('Error loading silage entries: $error'); // Error handling
    }
  }

  void _calculateGrainWeight() {
    final double? loadSize = double.tryParse(_loadSizeController.text);
    final double? grainPercentage = double.tryParse(_grainPercentageController.text);

    if (loadSize != null && grainPercentage != null) {
      final double grainWeight = loadSize * (grainPercentage / 100);
      setState(() {
        _result = 'Load size @ $grainPercentage% = ${grainWeight.toStringAsFixed(2)} lbs of grain';
      });
    } else {
      setState(() {
        _result = 'Please enter valid numbers for load size and grain percentage.';
      });
    }
  }

  void _resetEntryFields() {
    _loadSizeController.text = '0';
    _grainPercentageController.text = '0';
    setState(() {
      _result = '';
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Silage Entry'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Dropdown for selecting herd
            DropdownButtonFormField<String?>(
              value: _selectedHerd?['uid'],
              decoration: const InputDecoration(
                labelText: 'Select Herd',
                border: OutlineInputBorder(),
              ),
              items: [
                const DropdownMenuItem<String?>(
                  value: null,
                  child: Text('Select a herd'),
                ),
                ..._herds.map((herd) {
                  return DropdownMenuItem<String?>(
                    value: herd['uid'],
                    child: Text('${herd['name']} (${herd['numberOfAnimals']} animals)'),
                  );
                }).toList(),
              ],
              onChanged: (value) {
                setState(() {
                  if (value != null) {
                    try {
                      _selectedHerd = _herds.firstWhere((herd) => herd['uid'] == value);
                    } catch (e) {
                      _selectedHerd = null;
                      print('Herd not found for id $value');
                    }
                  } else {
                    _selectedHerd = null;
                  }
                });
              },
            ),
            SizedBox(height: 16),
            // TextField for load size
            TextField(
              controller: _loadSizeController,
              decoration: const InputDecoration(
                labelText: 'Load size (lbs)',
                border: OutlineInputBorder(),
              ),
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              textInputAction: TextInputAction.next,
              onChanged: (value) => _calculateGrainWeight(),
            ),
            const SizedBox(height: 16),
            // TextField for grain percentage
            TextField(
              controller: _grainPercentageController,
              decoration: const InputDecoration(
                labelText: 'Grain percentage (%)',
                border: OutlineInputBorder(),
              ),
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              textInputAction: TextInputAction.done,
              onChanged: (value) => _calculateGrainWeight(),
              onSubmitted: (_) => FocusScope.of(context).unfocus(),
            ),
            SizedBox(height: 20),
            // Button to start feeding
            ElevatedButton(
              onPressed: () async {
                if (_selectedHerd == null) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Please select a herd before starting feeding.')),
                  );
                  return;
                }

                final result = await Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => InProgressScreen(
                      supabaseClient: widget.supabaseClient,
                      herdId: _selectedHerd!['uid'],
                      loadSize: double.tryParse(_loadSizeController.text) ?? 0,
                      grainPercentage: double.tryParse(_grainPercentageController.text) ?? 0,
                    ),
                  ),
                );
                if (result == true) {
                  await _loadSilageEntries();
                  _resetEntryFields();
                }
              },
              child: Text('Start Feeding'),
            ),
            SizedBox(height: 10),
            // Display result
            Text(
              _result,
              style: Theme.of(context).textTheme.titleLarge,
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 20),
            // ListBox to display silage_fed records
            Expanded(
              child: Card(
                elevation: 2,
                child: Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: _silageEntries.isEmpty
                      ? Center(child: Text('No silage entries found.'))
                      : ListView.builder(
                          itemCount: _silageEntries.length,
                          itemBuilder: (context, index) {
                            final entry = _silageEntries[index];
                            return ListTile(
                              title: Text('${entry['herds']['name']}'),
                              subtitle: Text(
                                'Fed ${entry['amount_fed']} lbs @ ${entry['grain_percentage']}% grain\n'
                                '${DateTime.parse(entry['created_at']).toLocal()}',
                              ),
                            );
                          },
                        ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

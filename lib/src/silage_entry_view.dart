import 'package:flutter/material.dart';
import 'package:sqflite/sqflite.dart';
import 'in_progress_screen.dart';

class SilageEntryView extends StatefulWidget {
  const SilageEntryView({super.key, required this.database}); // Include the database parameter
  final Database database; // Add database field
  static const routeName = '/silage-entry';

  @override
  State<SilageEntryView> createState() => _SilageEntryViewState();
}

class _SilageEntryViewState extends State<SilageEntryView> {
  final TextEditingController _loadSizeController = TextEditingController();
  final TextEditingController _grainPercentageController = TextEditingController();
  String _result = '';
  List<Map<String, dynamic>> _herds = [];
  List<Map<String, dynamic>> _silageEntries = [];
  Map<String, dynamic>? _selectedHerd;

  @override
  void initState() {
    super.initState();
    _initializeDatabase();
    _loadHerds();
    _loadSilageEntries();
  }

  Future<void> _initializeDatabase() async {
    await widget.database.execute('''
      CREATE TABLE IF NOT EXISTS silage_fed (
        uid TEXT PRIMARY KEY,
        herd_id INTEGER,
        amount_fed REAL,
        grain_percentage REAL,
        fed_at DATETIME DEFAULT CURRENT_TIMESTAMP
      )
    ''');
  }

  Future<void> _loadHerds() async {
    final List<Map<String, dynamic>> herds = await widget.database.query('herds');
    setState(() {
      _herds = herds;
    });
  }

  Future<void> _loadSilageEntries() async {
    final List<Map<String, dynamic>> entries = await widget.database.rawQuery('''
      SELECT sf.*, h.name as herd_name 
      FROM silage_fed sf 
      JOIN herds h ON sf.herd_id = h.id 
      ORDER BY sf.fed_at DESC
      LIMIT 10
    ''');
    setState(() {
      _silageEntries = entries;
    });
  }

  void _calculateGrainWeight() {
    final double? loadSize = double.tryParse(_loadSizeController.text);
    final double? grainPercentage = double.tryParse(_grainPercentageController.text);

    if (loadSize != null && grainPercentage != null) {
      final double grainWeight = loadSize * (grainPercentage / 100);
      setState(() {
        _result = 'Load size @ $grainPercentage% = ${grainWeight.toStringAsFixed(2)} lbs of grain';
      });
    }
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
            Expanded(
              child: Card(
                child: ListView.builder(
                  itemCount: _silageEntries.length,
                  itemBuilder: (context, index) {
                    final entry = _silageEntries[index];
                    return ListTile(
                      title: Text('${entry['herd_name']}'),
                      subtitle: Text(
                        'Fed ${entry['amount_fed']} lbs @ ${entry['grain_percentage']}% grain\n'
                        '${DateTime.parse(entry['fed_at']).toLocal()}'
                      ),
                    );
                  },
                ),
              ),
            ),
            SizedBox(height: 16),
DropdownButtonFormField<int>(
  value: _selectedHerd?['id'],
  decoration: InputDecoration(
    labelText: 'Select Herd',
    border: OutlineInputBorder(),
  ),
  items: _herds.map((herd) {
    return DropdownMenuItem<int>(
      value: herd['id'],
      child: Text('${herd['name']} (${herd['numberOfAnimals']} animals)'),
    );
  }).toList(),
  onChanged: (value) {
    setState(() {
      _selectedHerd = _herds.firstWhere((herd) => herd['id'] == value);
    });
  },
),
            SizedBox(height: 16),
            TextField(
              controller: _loadSizeController,
              decoration: InputDecoration(
                labelText: 'Load size (lbs)',
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.number,
              onChanged: (value) => _calculateGrainWeight(),
            ),
            SizedBox(height: 16),
            TextField(
              controller: _grainPercentageController,
              decoration: InputDecoration(
                labelText: 'Grain percentage (%)',
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.number,
              onChanged: (value) => _calculateGrainWeight(),
            ),
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: () async {
                final result = await Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => InProgressScreen(
                      database: widget.database,
                      herdId: _selectedHerd?['id'],
                      loadSize: double.tryParse(_loadSizeController.text) ?? 0,
                      grainPercentage: double.tryParse(_grainPercentageController.text) ?? 0,
                    ),
                  ),
                );
                if (result == true) {
                  _loadSilageEntries();
                }
              },
              child: Text('Start Feeding'),
            ),
            Text(
              _result,
              style: Theme.of(context).textTheme.titleLarge,
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

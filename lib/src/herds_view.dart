import 'package:flutter/material.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'herd_edit_view.dart';

class HerdsView extends StatefulWidget {
  final Database database; // Add database parameter

  const HerdsView({
    super.key,
    required this.database,
  });

  static const routeName = '/herds';

  @override
  _HerdsViewState createState() => _HerdsViewState();
}

class _HerdsViewState extends State<HerdsView> {
  final TextEditingController _herdNameController = TextEditingController();
  final TextEditingController _numberOfAnimalsController = TextEditingController();
  List<Map<String, dynamic>> _herds = [];
  late Database _database;

  @override
  void initState() {
    super.initState();
    _initDatabase();
  }

  Future<void> _initDatabase() async {
    try {
      _database = await openDatabase(
        join(await getDatabasesPath(), 'herds_database.db'),
        onCreate: (db, version) {
          return db.execute(
            'CREATE TABLE herds(id INTEGER PRIMARY KEY, name TEXT, numberOfAnimals INTEGER)',
          );
        },
        version: 1,
      );
    } catch (e) {
      print('Error opening database: $e');
    }
    _loadHerds();
  }

  Future<void> _loadHerds() async {
    final List<Map<String, dynamic>> herds = await _database.query('herds');
    setState(() {
      _herds = herds;
    });
  }

  Future<void> _addHerd() async {
    final String name = _herdNameController.text;
    final int? numberOfAnimals = int.tryParse(_numberOfAnimalsController.text);

    if (name.isNotEmpty && numberOfAnimals != null) {
      await _database.insert(
        'herds',
        {'name': name, 'numberOfAnimals': numberOfAnimals},
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
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
                                  database: _database,
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

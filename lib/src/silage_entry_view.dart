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
  List<Map<String, dynamic>> _silageEntries = [];
  List<Map<String, dynamic>> _filteredEntries = [];
  String? _dateFilter;
  String? _herdFilter;
  List<String> _uniqueHerds = [];

  @override
  void initState() {
    super.initState();
    _loadSilageEntries();
  }

  void _updateFilters() {
    setState(() {
      _filteredEntries = _silageEntries.where((entry) {
        bool matchesDate = true;
        bool matchesHerd = true;

        if (_dateFilter != null && _dateFilter!.isNotEmpty) {
          final entryDate = DateTime.parse(entry['created_at']).toLocal().toString().split(' ')[0];
          matchesDate = entryDate == _dateFilter;
        }

        if (_herdFilter != null && _herdFilter!.isNotEmpty) {
          matchesHerd = entry['herds']['name'] == _herdFilter;
        }

        return matchesDate && matchesHerd;
      }).toList();

      // Update unique herds list
      _uniqueHerds = _silageEntries
          .map((e) => e['herds']['name'] as String)
          .toSet()
          .toList()
        ..sort();
    });
  }

  Future<void> _deleteSilageEntry(String uid) async {
    try {
      await widget.supabaseClient
          .from('silage_fed')
          .delete()
          .eq('uid', uid);
      await _loadSilageEntries(); // Reload the list after deletion
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error deleting entry: $error'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _loadSilageEntries() async {
    print('Loading silage entries...'); // Debug log
    try {
      final dynamic response = await widget.supabaseClient
          .from('silage_fed')
          .select('*, herds(name)')
          .order('created_at', ascending: false);
      print('Silage entries loaded: $response'); // Debug log
      if (response is List) {
        setState(() {
          _silageEntries = List<Map<String, dynamic>>.from(response);
          _filteredEntries = _silageEntries;
          _updateFilters();
        });
      }
    } catch (error) {
      print('Error loading silage entries: $error'); // Error handling
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
            // Button to start new load
            ElevatedButton(
              onPressed: () async {
                final result = await Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => InProgressScreen(
                      supabaseClient: widget.supabaseClient,
                    ),
                  ),
                );
                if (result == true) {
                  await _loadSilageEntries();
                }
              },
              child: Text('Start New Load'),
            ),
            SizedBox(height: 20),
            // DataTable to display silage_fed records
            Expanded(
              child: Card(
                elevation: 2,
                child: SingleChildScrollView(
                  child: _silageEntries.isEmpty
                      ? Center(child: Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Text('No silage entries found.'),
                        ))
                      : DataTable(
                          columns: [
                              DataColumn(
                                label: Row(
                                  children: [
                                    const Text('Date'),
                                    IconButton(
                                      icon: const Icon(Icons.filter_list),
                                      onPressed: () async {
                                        final date = await showDatePicker(
                                          context: context,
                                          initialDate: DateTime.now(),
                                          firstDate: DateTime(2000),
                                          lastDate: DateTime.now(),
                                        );
                                        if (date != null) {
                                          setState(() {
                                            _dateFilter = date.toString().split(' ')[0];
                                            _updateFilters();
                                          });
                                        }
                                      },
                                    ),
                                    if (_dateFilter != null)
                                      IconButton(
                                        icon: const Icon(Icons.clear),
                                        onPressed: () {
                                          setState(() {
                                            _dateFilter = null;
                                            _updateFilters();
                                          });
                                        },
                                      ),
                                  ],
                                ),
                              ),
                              DataColumn(
                                label: Row(
                                  children: [
                                    const Text('Herd'),
                                    PopupMenuButton<String>(
                                      icon: const Icon(Icons.filter_list),
                                      onSelected: (String value) {
                                        setState(() {
                                          _herdFilter = value;
                                          _updateFilters();
                                        });
                                      },
                                      itemBuilder: (BuildContext context) {
                                        return [
                                          const PopupMenuItem<String>(
                                            value: '',
                                            child: Text('Clear Filter'),
                                          ),
                                          ..._uniqueHerds.map((herd) => PopupMenuItem<String>(
                                            value: herd,
                                            child: Text(herd),
                                          )),
                                        ];
                                      },
                                    ),
                                    if (_herdFilter != null && _herdFilter!.isNotEmpty)
                                      IconButton(
                                        icon: const Icon(Icons.clear),
                                        onPressed: () {
                                          setState(() {
                                            _herdFilter = null;
                                            _updateFilters();
                                          });
                                        },
                                      ),
                                  ],
                                ),
                              ),
                              const DataColumn(
                                label: Text('Amount Fed (lbs)'),
                              ),
                              const DataColumn(
                                label: Text(''),
                              ),
                            ],
                            rows: _filteredEntries.map((entry) {
                              final date = DateTime.parse(entry['created_at']).toLocal();
                              return DataRow(
                                cells: [
                                  DataCell(Text(date.toString().split(' ')[0])),
                                  DataCell(Text(entry['herds']['name'])),
                                  DataCell(Text('${entry['amount_fed']} lbs')),
                                  DataCell(
                                    IconButton(
                                      icon: const Icon(Icons.delete_outline, color: Colors.red),
                                      onPressed: () async {
                                        final confirmed = await showDialog<bool>(
                                          context: context,
                                          builder: (BuildContext context) {
                                            return AlertDialog(
                                              title: const Text('Confirm Delete'),
                                              content: const Text('Are you sure you want to delete this entry?'),
                                              actions: [
                                                TextButton(
                                                  onPressed: () => Navigator.of(context).pop(false),
                                                  child: const Text('Cancel'),
                                                ),
                                                TextButton(
                                                  onPressed: () => Navigator.of(context).pop(true),
                                                  style: TextButton.styleFrom(
                                                    foregroundColor: Colors.red,
                                                  ),
                                                  child: const Text('Delete'),
                                                ),
                                              ],
                                            );
                                          },
                                        );
                                        
                                        if (confirmed == true) {
                                          await _deleteSilageEntry(entry['uid']);
                                        }
                                      },
                                    ),
                                  ),
                                ],
                              );
                            }).toList(),
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

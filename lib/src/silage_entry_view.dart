import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'in_progress_screen.dart';

import 'settings/settings_controller.dart';
import 'settings/settings_view.dart';

class SilageEntryView extends StatefulWidget {
  const SilageEntryView({
    super.key,
    required this.supabaseClient,
    required this.settingsController,
  });
  
  final SupabaseClient supabaseClient;
  final SettingsController settingsController;
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
          .select('*, herds(name), grain_percentage')
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
        title: const Text('Silage Entry'),
      ),
      body: SafeArea(
        bottom: false,
        child: Padding(
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
                child: const Text('Start New Load'),
              ),
              const SizedBox(height: 20),
              // DataTable to display silage_fed records
              Expanded(
                child: Card(
                  elevation: 2,
                  child: SingleChildScrollView(
                    child: _silageEntries.isEmpty
                        ? const Center(
                            child: Padding(
                              padding: EdgeInsets.all(16.0),
                              child: Text('No silage entries found.'),
                            ),
                          )
                        : DataTable(
                            columnSpacing: 8,
                            horizontalMargin: 8,
                            columns: [
                              DataColumn(
                                label: Container(
                                  width: 70,
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      const Text('Date',
                                          style: TextStyle(fontSize: 12)),
                                      const SizedBox(width: 2),
                                      InkWell(
                                        child:
                                            const Icon(Icons.filter_list, size: 14),
                                        onTap: () async {
                                          final date = await showDatePicker(
                                            context: context,
                                            initialDate: DateTime.now(),
                                            firstDate: DateTime(2000),
                                            lastDate: DateTime.now(),
                                          );
                                          if (date != null) {
                                            setState(() {
                                              _dateFilter =
                                                  date.toString().split(' ')[0];
                                              _updateFilters();
                                            });
                                          }
                                        },
                                      ),
                                      if (_dateFilter != null) ...[
                                        const SizedBox(width: 2),
                                        InkWell(
                                          child:
                                              const Icon(Icons.clear, size: 14),
                                          onTap: () {
                                            setState(() {
                                              _dateFilter = null;
                                              _updateFilters();
                                            });
                                          },
                                        ),
                                      ],
                                    ],
                                  ),
                                ),
                              ),
                              DataColumn(
                                label: Container(
                                  width: 80,
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      const Text('Herd',
                                          style: TextStyle(fontSize: 12)),
                                      const SizedBox(width: 2),
                                      PopupMenuButton<String>(
                                        padding: EdgeInsets.zero,
                                        icon: const Icon(Icons.filter_list,
                                            size: 14),
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
                                            ..._uniqueHerds.map((herd) =>
                                                PopupMenuItem<String>(
                                                  value: herd,
                                                  child: Text(herd),
                                                )),
                                          ];
                                        },
                                      ),
                                      if (_herdFilter != null &&
                                          _herdFilter!.isNotEmpty) ...[
                                        const SizedBox(width: 2),
                                        InkWell(
                                          child:
                                              const Icon(Icons.clear, size: 14),
                                          onTap: () {
                                            setState(() {
                                              _herdFilter = null;
                                              _updateFilters();
                                            });
                                          },
                                        ),
                                      ],
                                    ],
                                  ),
                                ),
                              ),
                              DataColumn(
                                label: Container(
                                  width: 60,
                                  child: const Text('Lbs',
                                      style: TextStyle(fontSize: 12)),
                                ),
                              ),
                              DataColumn(
                                label: Container(
                                  width: 60,
                                  child: const Text('Grain %',
                                      style: TextStyle(fontSize: 12)),
                                ),
                              ),
                              const DataColumn(
                                label: SizedBox(width: 24),
                              ),
                            ],
                            rows: _filteredEntries.map((entry) {
                              final date =
                                  DateTime.parse(entry['created_at']).toLocal();
                              final months = [
                                '',
                                'Jan',
                                'Feb',
                                'Mar',
                                'Apr',
                                'May',
                                'Jun',
                                'Jul',
                                'Aug',
                                'Sep',
                                'Oct',
                                'Nov',
                                'Dec'
                              ];
                              final formattedDate =
                                  '${months[date.month]} ${date.day}';
                              return DataRow(
                                cells: [
                                  DataCell(
                                    Container(
                                      width: 70,
                                      child: Text(
                                        formattedDate,
                                        style: const TextStyle(fontSize: 12),
                                      ),
                                    ),
                                  ),
                                  DataCell(
                                    Container(
                                      width: 80,
                                      child: Text(
                                        entry['herds']['name'],
                                        style: const TextStyle(fontSize: 12),
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                  ),
                                  DataCell(
                                    Container(
                                      width: 60,
                                      child: Text(
                                        entry['amount_fed'].toString(),
                                        style: const TextStyle(fontSize: 12),
                                      ),
                                    ),
                                  ),
                                  DataCell(
                                    Container(
                                      width: 60,
                                      child: Text(
                                        '${(entry['grain_percentage'] as num?)?.toStringAsFixed(1) ?? '0.0'}%',
                                        style: const TextStyle(fontSize: 12),
                                      ),
                                    ),
                                  ),
                                  DataCell(
                                    IconButton(
                                      padding: EdgeInsets.zero,
                                      constraints:
                                          const BoxConstraints.tightFor(width: 24),
                                      icon: const Icon(Icons.delete_outline,
                                          color: Colors.red, size: 16),
                                      onPressed: () async {
                                        bool shouldDelete = true;

                                        if (widget.settingsController
                                            .showDeleteConfirmation) {
                                          bool dontShowAgain = false;
                                          shouldDelete =
                                              await showDialog<bool>(
                                                    context: context,
                                                    builder:
                                                        (BuildContext context) {
                                                      return StatefulBuilder(
                                                        builder:
                                                            (context, setState) {
                                                          return AlertDialog(
                                                            title: const Text(
                                                                'Confirm Delete'),
                                                            content: Column(
                                                              mainAxisSize:
                                                                  MainAxisSize
                                                                      .min,
                                                              crossAxisAlignment:
                                                                  CrossAxisAlignment
                                                                      .start,
                                                              children: [
                                                                const Text(
                                                                    'Are you sure you want to delete this entry?'),
                                                                const SizedBox(
                                                                    height: 16),
                                                                CheckboxListTile(
                                                                  title: const Text(
                                                                      'Don\'t ask me again'),
                                                                  value:
                                                                      dontShowAgain,
                                                                  onChanged:
                                                                      (value) {
                                                                    setState(() {
                                                                      dontShowAgain =
                                                                          value ??
                                                                              false;
                                                                    });
                                                                  },
                                                                  controlAffinity:
                                                                      ListTileControlAffinity
                                                                          .leading,
                                                                  contentPadding:
                                                                      EdgeInsets
                                                                          .zero,
                                                                ),
                                                              ],
                                                            ),
                                                            actions: [
                                                              TextButton(
                                                                onPressed: () =>
                                                                    Navigator.of(
                                                                            context)
                                                                        .pop(
                                                                            false),
                                                                child: const Text(
                                                                    'Cancel'),
                                                              ),
                                                              TextButton(
                                                                onPressed: () {
                                                                  if (dontShowAgain) {
                                                                    widget
                                                                        .settingsController
                                                                        .updateShowDeleteConfirmation(
                                                                            false);
                                                                  }
                                                                  Navigator.of(
                                                                          context)
                                                                      .pop(true);
                                                                },
                                                                style: TextButton
                                                                    .styleFrom(
                                                                  foregroundColor:
                                                                      Colors.red,
                                                                ),
                                                                child: const Text(
                                                                    'Delete'),
                                                              ),
                                                            ],
                                                          );
                                                        },
                                                      );
                                                    },
                                                  ) ??
                                              false;
                                        }

                                        if (shouldDelete) {
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
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';

class InProgressScreen extends StatefulWidget {
  final SupabaseClient supabaseClient;
  const InProgressScreen({
    super.key,
    required this.supabaseClient,
  });

  @override
  _InProgressScreenState createState() => _InProgressScreenState();
}

class _InProgressScreenState extends State<InProgressScreen> {
  final TextEditingController _loadSizeController = TextEditingController(text: '0');
  final TextEditingController _grainPercentageController = TextEditingController(text: '0');
  final TextEditingController _amountUsedController = TextEditingController(text: '0');
  final Uuid _uuid = Uuid();
  String _result = '';
  String _carryOverInfo = '';
  double _carriedOverLoad = 0;
  double _carriedOverGrain = 0;
  List<Map<String, dynamic>> _herds = [];
  Map<String, dynamic>? _selectedHerd;

  @override
  void initState() {
    super.initState();
    _loadHerds();
  }

  Future<void> _loadHerds() async {
    try {
      final dynamic response = await widget.supabaseClient
          .from('herds')
          .select();
      if (response is List) {
        setState(() {
          _herds = List<Map<String, dynamic>>.from(response);
        });
      }
    } catch (error) {
      print('Error loading herds: $error');
    }
  }

  void _resetForm() {
    setState(() {
      _selectedHerd = null;
      _loadSizeController.text = '0';
      _amountUsedController.text = '0';
      _grainPercentageController.text = '0';
      _result = '';
    });
  }

  void _onLoadSizeChanged(String value) {
    final double? loadSize = double.tryParse(value);
    if (loadSize != null) {
      // Default amount used to load size
      _amountUsedController.text = loadSize.toString();
      _calculateGrainWeight();
    }
  }

  void _calculateGrainWeight() {
    final double? loadSize = double.tryParse(_loadSizeController.text);
    final double? grainPercentage = double.tryParse(_grainPercentageController.text);

    if (loadSize != null && grainPercentage != null) {
      // Calculate required grain based only on new load size
      final double requiredGrain = loadSize * (grainPercentage / 100);
      
      setState(() {
        if (_carriedOverLoad > 0) {
          // Show carryover information
          final double carriedOverPercentage = (_carriedOverGrain / _carriedOverLoad) * 100;
          _carryOverInfo = 'Carried over from last load: ${_carriedOverLoad.toStringAsFixed(2)} lbs with '
              '${_carriedOverGrain.toStringAsFixed(2)} lbs grain (${carriedOverPercentage.toStringAsFixed(1)}%)';
          
          // Calculate additional grain needed by subtracting carried over grain
          final double additionalGrainNeeded = requiredGrain - _carriedOverGrain;
          _result = 'Required grain for load: ${requiredGrain.toStringAsFixed(2)} lbs\n'
              'Using ${_carriedOverGrain.toStringAsFixed(2)} lbs from carryover\n'
              'Add ${additionalGrainNeeded.toStringAsFixed(2)} lbs of grain';
        } else {
          _carryOverInfo = '';
          _result = 'Add ${requiredGrain.toStringAsFixed(2)} lbs of grain to reach $grainPercentage%';
        }
      });
    } else {
      setState(() {
        _result = 'Please enter valid numbers for load size and grain percentage.';
        _carryOverInfo = '';
      });
    }
  }

  Future<void> _saveLoad() async {
    final double? loadSize = double.tryParse(_loadSizeController.text);
    final double? amountUsed = double.tryParse(_amountUsedController.text);
    final double? grainPercentage = double.tryParse(_grainPercentageController.text);
    
    if (_selectedHerd == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a herd before saving.')),
      );
      return;
    }

    if (loadSize == null || amountUsed == null || grainPercentage == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter valid numbers for all fields.')),
      );
      return;
    }

    // Only consider current load for amount validation
    if (amountUsed > loadSize) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Amount used cannot be greater than the current load size.')),
      );
      return;
    }

    try {
      await widget.supabaseClient
        .from('silage_fed')
        .insert({
          'uid': _uuid.v4(),
          'herd_id': _selectedHerd!['uid'],
          'amount_fed': amountUsed,
          'grain_percentage': grainPercentage,
          'created_at': DateTime.now().toIso8601String(),
        });

      // Calculate remaining amount from current load only
      final double remaining = loadSize - amountUsed;
      
      setState(() {
        if (remaining > 0) {
          // Set carryover based only on current load's remaining amount
          _carriedOverLoad = remaining;
          _carriedOverGrain = remaining * (grainPercentage / 100);
          
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(
              'Load saved. Remaining: ${remaining.toStringAsFixed(2)} lbs with '
              '${_carriedOverGrain.toStringAsFixed(2)} lbs grain'
            )),
          );
        } else {
          // Reset carryover when nothing remains
          _carriedOverLoad = 0;
          _carriedOverGrain = 0;
          
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Load saved successfully')),
          );
          Navigator.pop(context, true);
        }
        _resetForm();
      });
    } catch (error) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $error')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('In Progress'),
        actions: [
          TextButton.icon(
            onPressed: () => Navigator.pop(context, false),
            icon: const Icon(Icons.exit_to_app),
            label: const Text('Exit'),
            style: TextButton.styleFrom(
              foregroundColor: Theme.of(context).colorScheme.onPrimary,
            ),
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
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
            const SizedBox(height: 16),
            TextField(
              controller: _loadSizeController,
              decoration: const InputDecoration(
                labelText: 'Load size (lbs)',
                border: OutlineInputBorder(),
              ),
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              textInputAction: TextInputAction.next,
              onChanged: _onLoadSizeChanged,
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _grainPercentageController,
              decoration: const InputDecoration(
                labelText: 'Grain percentage (%)',
                border: OutlineInputBorder(),
              ),
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              textInputAction: TextInputAction.next,
              onChanged: (value) => _calculateGrainWeight(),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _amountUsedController,
              decoration: const InputDecoration(
                labelText: 'Amount Used (lbs)',
                border: OutlineInputBorder(),
              ),
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              textInputAction: TextInputAction.done,
            ),
            const SizedBox(height: 16),
            if (_carryOverInfo.isNotEmpty) ...[
              Text(
                _carryOverInfo,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: Theme.of(context).colorScheme.secondary,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
            ],
            Text(
              _result,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                color: Theme.of(context).colorScheme.primary,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            FilledButton(
              onPressed: _saveLoad,
              child: const Text('Save Load'),
            ),
          ],
        ),
      ),
    );
  }
}

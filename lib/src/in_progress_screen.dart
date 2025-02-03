import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';

class InProgressScreen extends StatefulWidget {
  final SupabaseClient supabaseClient;
  final String? herdId;
  final double loadSize;
  final double grainPercentage;

  const InProgressScreen({
    super.key,
    required this.supabaseClient,
    required this.herdId,
    required this.loadSize,
    required this.grainPercentage,
  });

  @override
  _InProgressScreenState createState() => _InProgressScreenState();
}

class _InProgressScreenState extends State<InProgressScreen> {
  final TextEditingController _amountUsedController = TextEditingController();
  final Uuid _uuid = Uuid();

  @override
  void initState() {
    super.initState();
    _amountUsedController.text = widget.loadSize.toString();
  }

  Future<void> _saveLoad() async {
    final double? amountUsed = double.tryParse(_amountUsedController.text);
    if (amountUsed != null && widget.herdId != null) {
      final String uid = _uuid.v4();
      try {
        await widget.supabaseClient
          .from('silage_fed')
          .insert({
            'uid': uid,
            'herd_id': widget.herdId,
            'amount_fed': amountUsed,
            'grain_percentage': widget.grainPercentage,
            'created_at': DateTime.now().toIso8601String(),
          });
      } catch (error) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $error')),
        );
        return;
      }
      Navigator.pop(context, true); // Return true to indicate refresh needed
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('In Progress'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TextField(
              controller: _amountUsedController,
              decoration: InputDecoration(
                labelText: 'Amount Used (lbs)',
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.number,
            ),
            SizedBox(height: 16),
            ElevatedButton(
              onPressed: _saveLoad,
              child: Text('Save Load'),
            ),
          ],
        ),
      ),
    );
  }
}

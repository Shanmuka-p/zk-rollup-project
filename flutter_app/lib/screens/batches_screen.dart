import 'package:flutter/material.dart';
import '../../../lib/services/api_service.dart';
import '../main.dart';

class BatchesScreen extends StatefulWidget {
  final ApiService apiService;
  const BatchesScreen({super.key, required this.apiService});

  @override
  State<BatchesScreen> createState() => _BatchesScreenState();
}

class _BatchesScreenState extends State<BatchesScreen> {
  List<dynamic> _batches = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchBatches();
  }

  Future<void> _fetchBatches() async {
    try {
      final batches = await widget.apiService.getBatches();
      setState(() => _batches = batches);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const AppNavBar(),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : ListView.builder(
              padding: const EdgeInsets.all(24.0),
              itemCount: _batches.length,
              itemBuilder: (context, index) {
                final batch = _batches[index];
                return Card(
                  child: ExpansionTile(
                    title: Text(
                      'Batch Index: ${batch['batch_index'] ?? "Pending"}',
                    ),
                    subtitle: Text(
                      'Tx Count: ${batch['tx_count']} | Relayer: ${batch['relayer_address']}',
                    ),
                    children: [
                      Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Batch Hash: ${batch['batch_hash']}'),
                            Text('New State Root: ${batch['new_state_root']}'),
                            Text(
                              'Committed At: ${batch['committed_at'] ?? "Pending..."}',
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
    );
  }
}

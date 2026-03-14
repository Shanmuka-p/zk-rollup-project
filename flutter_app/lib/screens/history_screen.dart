import 'package:flutter/material.dart';
import 'package:flutter_app/services/api_service.dart';
//import '../../../lib/services/api_service.dart';
import '../main.dart';

class HistoryScreen extends StatefulWidget {
  final ApiService apiService;
  const HistoryScreen({super.key, required this.apiService});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  final _filterController = TextEditingController();
  List<dynamic> _intents = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchHistory();
  }

  Future<void> _fetchHistory() async {
    setState(() => _isLoading = true);
    try {
      final intents = await widget.apiService.getIntents(
        address: _filterController.text.isNotEmpty
            ? _filterController.text
            : null,
      );
      setState(() => _intents = intents);
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
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          children: [
            Row(
              children: [
                Expanded(
                  child: Semantics(
                    identifier: 'history-filter-input',
                    child: TextField(
                      controller: _filterController,
                      decoration: const InputDecoration(
                        labelText: 'Filter by Address',
                        border: OutlineInputBorder(),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                ElevatedButton(
                  onPressed: _fetchHistory,
                  child: const Text('Search'),
                ),
              ],
            ),
            const SizedBox(height: 20),
            Expanded(
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : ListView.builder(
                      itemCount: _intents.length,
                      itemBuilder: (context, index) {
                        final intent = _intents[index];
                        return Card(
                          child: ListTile(
                            title: Text('To: ${intent['to_address']}'),
                            subtitle: Text(
                              'Amount (Wei): ${intent['amount_wei']}',
                            ),
                            trailing: Chip(
                              label: Text(intent['status']),
                              backgroundColor: intent['status'] == 'pending'
                                  ? Colors.orange
                                  : Colors.green,
                            ),
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

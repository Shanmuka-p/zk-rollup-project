import 'package:flutter/material.dart';
import 'package:flutter_app/services/api_service.dart';
//import '../../../lib/services/api_service.dart';
import '../main.dart'; // For AppNavBar

class DashboardScreen extends StatefulWidget {
  final ApiService apiService;
  const DashboardScreen({super.key, required this.apiService});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  final TextEditingController _addressController = TextEditingController();
  Map<String, dynamic>? _rollupState;
  String _balanceEth = "0.0";
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _fetchState();
  }

  Future<void> _fetchState() async {
    setState(() => _isLoading = true);
    try {
      final state = await widget.apiService.getRollupState();
      setState(() => _rollupState = state);

      if (_addressController.text.isNotEmpty) {
        final deposit = await widget.apiService.getDeposit(
          _addressController.text,
        );
        setState(() => _balanceEth = deposit['balanceEth'] ?? "0.0");
      }
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
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "Wallet Dashboard",
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 20),

            // Required Address Input
            Semantics(
              identifier: 'wallet-address-input',
              child: TextField(
                controller: _addressController,
                decoration: const InputDecoration(
                  labelText: 'Your Wallet Address',
                  border: OutlineInputBorder(),
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Required Refresh Button
            Semantics(
              identifier: 'refresh-button',
              child: ElevatedButton(
                onPressed: _fetchState,
                child: _isLoading
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Text('Refresh Data'),
              ),
            ),

            const Divider(height: 40),

            // Display Area
            Text(
              "On-Chain Balance: $_balanceEth ETH",
              style: const TextStyle(fontSize: 18),
            ),
            const SizedBox(height: 20),
            if (_rollupState != null) ...[
              const Text(
                "Rollup State:",
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              Text("Current State Root: ${_rollupState!['currentStateRoot']}"),
              Text("Total Batches Committed: ${_rollupState!['batchCount']}"),
              Text("Contract Address: ${_rollupState!['contractAddress']}"),
            ],
          ],
        ),
      ),
    );
  }
}

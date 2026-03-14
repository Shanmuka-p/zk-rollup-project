import 'package:flutter/material.dart';
import 'package:flutter_app/services/api_service.dart';
//import '../../../lib/services/api_service.dart';
import '../main.dart';

class SendScreen extends StatefulWidget {
  final ApiService apiService;
  const SendScreen({super.key, required this.apiService});

  @override
  State<SendScreen> createState() => _SendScreenState();
}

class _SendScreenState extends State<SendScreen> {
  final _fromController = TextEditingController();
  final _toController = TextEditingController();
  final _amountController = TextEditingController();
  bool _isSubmitting = false;

  Future<void> _submit() async {
    setState(() => _isSubmitting = true);
    try {
      // Convert ETH input to Wei (simplified string multiplication for this demo)
      final amountEth = double.parse(_amountController.text);
      final amountWei = (amountEth * 1e18).toStringAsFixed(0);

      await widget.apiService.submitIntent(
        _fromController.text,
        _toController.text,
        amountWei,
      );
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Intent submitted successfully!'), backgroundColor: Colors.green)
        );
        _toController.clear();
        _amountController.clear();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString()), backgroundColor: Colors.red)
        );
      }
    } finally {
      setState(() => _isSubmitting = false);
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
            const Text("Send Payment Intent", style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
            const SizedBox(height: 20),
            
            TextField(
              controller: _fromController,
              decoration: const InputDecoration(labelText: 'From Address', border: OutlineInputBorder()),
            ),
            const SizedBox(height: 16),
            
            Semantics(
              identifier: 'to-address-input',
              child: TextField(
                controller: _toController,
                decoration: const InputDecoration(labelText: 'To Address', border: OutlineInputBorder()),
              ),
            ),
            const SizedBox(height: 16),
            
            Semantics(
              identifier: 'amount-input',
              child: TextField(
                controller: _amountController,
                decoration: const InputDecoration(labelText: 'Amount (ETH)', border: OutlineInputBorder()),
                keyboardType: TextInputType.number,
              ),
            ),
            const SizedBox(height: 24),
            
            Semantics(
              identifier: 'submit-intent-button',
              child: ElevatedButton(
                onPressed: _isSubmitting ? null : _submit,
                child: _isSubmitting 
                    ? const CircularProgressIndicator() 
                    : const Text('Submit Intent'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
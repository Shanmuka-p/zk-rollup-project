import 'dart:convert';
import 'package:http/http.dart' as http;

class ApiService {
  static const String _baseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'http://localhost:4000',
  );

  Future<Map<String, dynamic>> getDeposit(String address) async {
    final response = await http.get(Uri.parse('$_baseUrl/deposits/$address'));
    if (response.statusCode == 200) return json.decode(response.body);
    throw Exception('Failed to load deposit');
  }

  Future<Map<String, dynamic>> getRollupState() async {
    final response = await http.get(Uri.parse('$_baseUrl/state'));
    if (response.statusCode == 200) return json.decode(response.body);
    throw Exception('Failed to load state');
  }

  Future<Map<String, dynamic>> submitIntent(
    String from,
    String to,
    String amountWei,
  ) async {
    final response = await http.post(
      Uri.parse('$_baseUrl/intents'),
      headers: {'Content-Type': 'application/json'},
      body: json.encode({
        'fromAddress': from,
        'toAddress': to,
        'amountWei': amountWei,
      }),
    );
    if (response.statusCode == 201) return json.decode(response.body);
    throw Exception(
      json.decode(response.body)['error'] ?? 'Failed to submit intent',
    );
  }

  Future<List<dynamic>> getIntents({String? address, String? status}) async {
    final queryParams = <String, String>{};
    if (address != null && address.isNotEmpty) queryParams['address'] = address;
    if (status != null && status.isNotEmpty) queryParams['status'] = status;

    final uri = Uri.parse(
      '$_baseUrl/intents',
    ).replace(queryParameters: queryParams.isNotEmpty ? queryParams : null);
    final response = await http.get(uri);
    if (response.statusCode == 200)
      return json.decode(response.body)['intents'];
    throw Exception('Failed to load intents');
  }

  Future<List<dynamic>> getBatches() async {
    final response = await http.get(Uri.parse('$_baseUrl/batches'));
    if (response.statusCode == 200)
      return json.decode(response.body)['batches'];
    throw Exception('Failed to load batches');
  }

  Future<Map<String, dynamic>> getBatchDetail(int batchIndex) async {
    final response = await http.get(Uri.parse('$_baseUrl/batches/$batchIndex'));
    if (response.statusCode == 200) return json.decode(response.body);
    throw Exception('Failed to load batch details');
  }
}

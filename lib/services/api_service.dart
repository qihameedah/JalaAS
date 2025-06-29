// lib/services/api_service.dart
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/contact.dart';
import '../models/account_statement.dart';

class ApiService {
  static const String _powerAutomateUrl =
      'https://prod-245.westeurope.logic.azure.com:443/workflows/7027d0574e584e088fe34c5a2a4ddae7/triggers/manual/paths/invoke?api-version=2016-06-01&sp=%2Ftriggers%2Fmanual%2Frun&sv=1.0&sig=nAcu6QCYe2i9KGcb8qHyqVjBbe-3nSs3AHm0mpkFikI';

  static const String _tokenUrl =
      'https://script.google.com/macros/s/AKfycby7q0QHLM9YZ8zCOGpgQGXtSPSTdtWrXJe_v5Nls1tYG2NZAws-ezDZ1U9Q1XA-sa25/exec';

  static Future<String> _getToken() async {
    try {
      final response = await http.get(Uri.parse(_tokenUrl));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final tokens = data['data'] as List;

        if (tokens.isNotEmpty) {
          // Get the last token (most recent)
          return tokens.last['token'] as String;
        }
      }

      throw Exception('Failed to get token');
    } catch (e) {
      throw Exception('Failed to get token: $e');
    }
  }

  static Future<Map<String, dynamic>> _makeApiRequest({
    required String url,
    required String method,
    Map<String, dynamic>? headers,
    Map<String, dynamic>? body,
  }) async {
    try {
      final token = await _getToken();

      final requestBody = {
        'url': url,
        'token': token,
        'method': method,
        if (headers != null) 'headers': headers,
        if (body != null) 'body': body,
      };

      final response = await http.post(
        Uri.parse(_powerAutomateUrl),
        headers: {'Content-Type': 'application/json'},
        body: json.encode(requestBody),
      );

      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        throw Exception('API request failed: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('API request failed: $e');
    }
  }

  static Future<List<Contact>> getContacts() async {
    const String contactsUrl =
        'https://gw.bisan.com/api/v2/jalaf/contact?fields=code,nameAR,area,area.name,salesman,streetAddress,taxId,phone&search=enabled:yes';

    final response = await _makeApiRequest(
      url: contactsUrl,
      method: 'GET',
    );

    final rows = response['rows'] as List;
    return rows.map((row) => Contact.fromBisanJson(row)).toList();
  }

  static Future<List<AccountStatement>> getAccountStatements({
    required String contactCode,
    required String fromDate,
    required String toDate,
  }) async {
    final String statementsUrl =
        'https://gw.bisan.com/api/v2/jalaf/REPORT/customerStatement.json?search=fromDate:$fromDate,toDate:$toDate,reference:$contactCode,currency:01,branch:00,showTotalPerAct:true,includeCashMov:true,showSettledAmounts:false,lg_status:مرحل';

    final response = await _makeApiRequest(
      url: statementsUrl,
      method: 'GET',
    );

    final rows = response['rows'] as List;
    return rows.map((row) => AccountStatement.fromJson(row)).toList();
  }

  static Future<List<AccountStatementDetail>> getAccountStatementDetails({
    required String contactCode,
    required String fromDate,
    required String toDate,
  }) async {
    final String detailsUrl =
        'https://gw.bisan.com/api/v2/jalaf/REPORT/customerStatementDetail.json?search=fromDate:$fromDate,toDate:$toDate,reference:$contactCode,includeCashMov:true,priceIncludeTax:true,showCashInfo:true,showItemInfo:true,selectAll:true,lg_status:مرحل';

    final response = await _makeApiRequest(
      url: detailsUrl,
      method: 'GET',
    );

    final rows = response['rows'] as List;
    return rows.map((row) => AccountStatementDetail.fromJson(row)).toList();
  }
}

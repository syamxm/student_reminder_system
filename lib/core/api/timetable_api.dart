import 'dart:convert';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:http/http.dart' as http;

const _baseUrl = 'https://api.syamxm.com';

class TimetableNotFoundException implements Exception {}

class TimetableApiException implements Exception {
  TimetableApiException(this.message);
  final String message;
  @override
  String toString() => 'TimetableApiException: $message';
}

class TimetableApi {
  TimetableApi({FirebaseAuth? auth}) : _auth = auth ?? FirebaseAuth.instance;

  final FirebaseAuth _auth;

  Future<String> _token() async {
    final token = await _auth.currentUser?.getIdToken();
    if (token == null) throw StateError('User not signed in.');
    return token;
  }

  Future<Map<String, dynamic>> scrape(String matricNumber) async {
    final token = await _token();

    final response = await http.post(
      Uri.parse('$_baseUrl/api/timetable/scrape'),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
      body: jsonEncode({'matric_number': matricNumber}),
    );

    if (response.statusCode == 404) throw TimetableNotFoundException();
    if (response.statusCode != 200) {
      throw TimetableApiException('HTTP ${response.statusCode}: ${response.body}');
    }

    return jsonDecode(response.body) as Map<String, dynamic>;
  }

  Future<List<Map<String, dynamic>>> fetchCampuses() async {
    final token = await _token();

    final response = await http.get(
      Uri.parse('$_baseUrl/api/campuses'),
      headers: {'Authorization': 'Bearer $token'},
    );

    if (response.statusCode != 200) {
      throw TimetableApiException('HTTP ${response.statusCode}: ${response.body}');
    }

    final data = jsonDecode(response.body) as Map<String, dynamic>;
    return (data['campuses'] as List).cast<Map<String, dynamic>>();
  }

  Future<List<Map<String, dynamic>>> fetchFaculties(String campusCode) async {
    final token = await _token();

    final response = await http.get(
      Uri.parse('$_baseUrl/api/faculties?campus=${Uri.encodeComponent(campusCode)}'),
      headers: {'Authorization': 'Bearer $token'},
    );

    if (response.statusCode != 200) {
      throw TimetableApiException('HTTP ${response.statusCode}: ${response.body}');
    }

    final data = jsonDecode(response.body) as Map<String, dynamic>;
    return (data['faculties'] as List).cast<Map<String, dynamic>>();
  }
}

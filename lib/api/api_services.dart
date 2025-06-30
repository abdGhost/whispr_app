import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:whispr_app/models/confession_model.dart';

class ApiServices {
  final String baseUrl = 'https://whisper-2nhg.onrender.com/api';

  Future<Map<String, dynamic>?> registerOnAppStart() async {
    final url = Uri.parse('$baseUrl/auth/register');

    try {
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({"password": ""}),
      );

      print('🔗 Register API Status: ${response.statusCode}');

      if (response.statusCode == 201) {
        final data = jsonDecode(response.body);
        return {'userId': data['userId'], 'username': data['username']};
      } else {
        print('❌ Registration failed: ${response.body}');
        return null;
      }
    } catch (e) {
      print('⚠️ Exception in registerOnAppStart: $e');
      return null;
    }
  }

  Future<List<Confession>> getAllConfession() async {
    final url = Uri.parse('$baseUrl/confessions/');

    try {
      final response = await http.get(url);
      print('🔗 Get All Confessions Response: ${response.body}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        List confessions = data['confessions'];
        return confessions.map((json) => Confession.fromJson(json)).toList();
      } else {
        throw Exception('Failed to load confessions: ${response.body}');
      }
    } catch (e) {
      print('⚠️ Exception in getAllConfession: $e');
      rethrow;
    }
  }

  Future<List<Confession>> getConfessionByCategory(String category) async {
    final url = Uri.parse('$baseUrl/confessions?category=$category');

    try {
      print('🔗 Get Confession By Category URL: $url');
      final response = await http.get(url);
      print('🔗 Get Confession By Category Response: ${response.body}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        List confessions = data['confessions'];
        return confessions.map((json) => Confession.fromJson(json)).toList();
      } else {
        throw Exception(
          'Failed to load confessions by category: ${response.body}',
        );
      }
    } catch (e) {
      print('⚠️ Exception in getConfessionByCategory: $e');
      rethrow;
    }
  }
}

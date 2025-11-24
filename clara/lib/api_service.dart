import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;

class ChatResult {
  final String answer;
  final String? sessionId;
  ChatResult({required this.answer, this.sessionId});
}

class ApiService {
  static const String baseUrl = 'http://192.168.56.1:8000'; // <-- your PC's IP

  static String? sessionId; // Store session for memory

  // Upload any file (PDF/image/photo)
  static Future<Map<String, dynamic>> uploadFile(File file, {String userId = 'arvinth'}) async {
    final uri = Uri.parse('$baseUrl/api/upload?user_id=$userId');
    final req = http.MultipartRequest('POST', uri)
      ..files.add(await http.MultipartFile.fromPath('file', file.path));
    final resp = await req.send();
    final body = await resp.stream.bytesToString();
    if (resp.statusCode >= 200 && resp.statusCode < 300) {
      return json.decode(body) as Map<String, dynamic>;
    } else {
      throw Exception('Upload failed ${resp.statusCode}: $body');
    }
  }

  // Chat with Clara (session-aware)
  static Future<ChatResult> chat(String question, {String userId = 'arvinth'}) async {
    final uri = Uri.parse('$baseUrl/api/chat');
    final res = await http.post(
      uri,
      headers: {'Content-Type': 'application/json'},
      body: json.encode({
        'query': question,
        'user_id': userId,
        if (sessionId != null) 'session_id': sessionId,
      }),
    );
    if (res.statusCode >= 200 && res.statusCode < 300) {
      final data = json.decode(res.body) as Map<String, dynamic>;
      final sid = (data['session_id'] as String?) ?? sessionId;
      sessionId = sid;
      return ChatResult(answer: (data['answer'] as String?) ?? '', sessionId: sid);
    } else {
      throw Exception('Chat failed ${res.statusCode}: ${res.body}');
    }
  }

  // For old usage: get just the answer string
  static Future<String> getClaraResponse(String question, {String userId = 'arvinth'}) async {
    final r = await chat(question, userId: userId);
    return r.answer;
  }

  // Get chat history (optional)
  static Future<List<dynamic>> history({String userId = 'arvinth', String? sessionId}) async {
    final uri = Uri.parse('$baseUrl/api/history?user_id=$userId${sessionId != null ? '&session_id=$sessionId' : ''}');
    final res = await http.get(uri);
    if (res.statusCode >= 200 && res.statusCode < 300) {
      return json.decode(res.body) as List<dynamic>;
    } else {
      throw Exception('History failed ${res.statusCode}: ${res.body}');
    }
  }
}
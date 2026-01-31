import 'dart:convert';
import 'package:http/http.dart' as http;

class ApiException implements Exception {
  final String message;
  final int? statusCode;
  ApiException(this.message, {this.statusCode});

  @override
  String toString() => message;
}

class ApiService {
  static final ApiService _instance = ApiService._internal();
  factory ApiService() => _instance;
  ApiService._internal();

  String baseUrl = 'http://localhost:5000';
  String? _accessToken;
  String? _refreshToken;
  String? _userId;
  String? _userName;
  String? _userEmail;

  bool get isLoggedIn => _accessToken != null;
  String? get userId => _userId;
  String? get userName => _userName;
  String? get userEmail => _userEmail;
  String? get accessToken => _accessToken;

  Map<String, String> get _headers => {
        'Content-Type': 'application/json',
        if (_accessToken != null) 'Authorization': 'Bearer $_accessToken',
      };

  Future<Map<String, dynamic>> _handleResponse(http.Response response) async {
    final body = jsonDecode(response.body) as Map<String, dynamic>;

    if (response.statusCode >= 200 && response.statusCode < 300) {
      return body['data'] as Map<String, dynamic>? ?? body;
    }

    final error = body['error'] ?? 'Something went wrong';
    throw ApiException(error.toString(), statusCode: response.statusCode);
  }

  // ─── Auth ─────────────────────────────────────────────

  Future<Map<String, dynamic>> signup(
      String email, String password, String name) async {
    final response = await http.post(
      Uri.parse('$baseUrl/auth/signup'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'email': email, 'password': password, 'name': name}),
    );

    final data = await _handleResponse(response);

    final session = data['session'] as Map<String, dynamic>?;
    if (session != null) {
      _accessToken = session['access_token'] as String?;
      _refreshToken = session['refresh_token'] as String?;
    }

    final user = data['user'] as Map<String, dynamic>?;
    if (user != null) {
      _userId = user['id'] as String?;
      _userName = user['full_name'] as String? ?? name;
      _userEmail = user['email'] as String?;
    }

    return data;
  }

  Future<Map<String, dynamic>> login(String email, String password) async {
    final response = await http.post(
      Uri.parse('$baseUrl/auth/login'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'email': email, 'password': password}),
    );

    final data = await _handleResponse(response);

    final session = data['session'] as Map<String, dynamic>?;
    if (session != null) {
      _accessToken = session['access_token'] as String?;
      _refreshToken = session['refresh_token'] as String?;
    }

    final user = data['user'] as Map<String, dynamic>?;
    if (user != null) {
      _userId = user['id'] as String?;
      _userName = user['full_name'] as String? ?? '';
      _userEmail = user['email'] as String?;
    }

    return data;
  }

  Future<void> logout() async {
    try {
      await http.post(
        Uri.parse('$baseUrl/auth/logout'),
        headers: _headers,
      );
    } finally {
      _accessToken = null;
      _refreshToken = null;
      _userId = null;
      _userName = null;
      _userEmail = null;
    }
  }

  Future<Map<String, dynamic>> getMe() async {
    final response = await http.get(
      Uri.parse('$baseUrl/auth/me'),
      headers: _headers,
    );
    return _handleResponse(response);
  }

  // ─── Session ──────────────────────────────────────────

  Future<Map<String, dynamic>> submitCrave(
      String craveItem, double latitude, double longitude) async {
    final response = await http.post(
      Uri.parse('$baseUrl/session/crave'),
      headers: _headers,
      body: jsonEncode({
        'crave_item': craveItem,
        'latitude': latitude,
        'longitude': longitude,
      }),
    );
    return _handleResponse(response);
  }

  Future<Map<String, dynamic>> selectOption(
      String sessionId, String selectedOption) async {
    final response = await http.post(
      Uri.parse('$baseUrl/session/select'),
      headers: _headers,
      body: jsonEncode({
        'session_id': sessionId,
        'selected_option': selectedOption,
      }),
    );
    return _handleResponse(response);
  }

  Future<Map<String, dynamic>> chooseType(
      String sessionId, String sessionType) async {
    final response = await http.post(
      Uri.parse('$baseUrl/session/choose-type'),
      headers: _headers,
      body: jsonEncode({
        'session_id': sessionId,
        'session_type': sessionType,
      }),
    );
    return _handleResponse(response);
  }

  // ─── Challenge ────────────────────────────────────────

  Future<Map<String, dynamic>> selectChallenge(
      String sessionId, String challengeDescription, int timeLimit) async {
    final response = await http.post(
      Uri.parse('$baseUrl/challenge/select'),
      headers: _headers,
      body: jsonEncode({
        'session_id': sessionId,
        'challenge_description': challengeDescription,
        'time_limit': timeLimit,
      }),
    );
    return _handleResponse(response);
  }

  Future<Map<String, dynamic>> startChallenge(String challengeId) async {
    final response = await http.post(
      Uri.parse('$baseUrl/challenge/start'),
      headers: _headers,
      body: jsonEncode({'challenge_id': challengeId}),
    );
    return _handleResponse(response);
  }

  Future<Map<String, dynamic>> completeChallenge(
      String challengeId, int completionPercentage) async {
    final response = await http.post(
      Uri.parse('$baseUrl/challenge/complete'),
      headers: _headers,
      body: jsonEncode({
        'challenge_id': challengeId,
        'completion_percentage': completionPercentage,
      }),
    );
    return _handleResponse(response);
  }

  // ─── User ─────────────────────────────────────────────

  Future<Map<String, dynamic>> getProfile() async {
    final response = await http.get(
      Uri.parse('$baseUrl/user/profile'),
      headers: _headers,
    );
    return _handleResponse(response);
  }

  Future<Map<String, dynamic>> updateProfile({
    String? name,
    int? age,
    double? height,
    double? weight,
  }) async {
    final body = <String, dynamic>{};
    if (name != null) body['name'] = name;
    if (age != null) body['age'] = age;
    if (height != null) body['height'] = height;
    if (weight != null) body['weight'] = weight;

    final response = await http.put(
      Uri.parse('$baseUrl/user/profile'),
      headers: _headers,
      body: jsonEncode(body),
    );
    return _handleResponse(response);
  }

  Future<Map<String, dynamic>> getHistory() async {
    final response = await http.get(
      Uri.parse('$baseUrl/user/history'),
      headers: _headers,
    );
    return _handleResponse(response);
  }
}

import 'dart:convert';
import 'dart:typed_data';

import 'package:http/http.dart' as http;

import '../models/player_profile.dart';

class ProfileApi {
  ProfileApi({http.Client? client}) : _client = client ?? http.Client();

  static const baseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'http://localhost:3000',
  );

  final http.Client _client;

  Future<PlayerProfile> register({
    required String username,
    required String password,
  }) => _authenticate(
    path: '/auth/register',
    username: username,
    password: password,
    expectedStatus: 201,
  );

  Future<PlayerProfile> login({
    required String username,
    required String password,
  }) => _authenticate(
    path: '/auth/login',
    username: username,
    password: password,
    expectedStatus: 200,
  );

  Future<PlayerProfile> _authenticate({
    required String path,
    required String username,
    required String password,
    required int expectedStatus,
  }) async {
    final response = await _client.post(
      Uri.parse('$baseUrl$path'),
      headers: const {'Content-Type': 'application/json'},
      body: jsonEncode({'username': username, 'password': password}),
    );
    final body = jsonDecode(response.body) as Map<String, dynamic>;
    if (response.statusCode != expectedStatus) {
      throw ProfileApiException(
        body['error'] as String? ?? 'Server returned ${response.statusCode}.',
      );
    }
    final account = body['account'] as Map<String, dynamic>;
    return PlayerProfile(
      id: account['id'] as String,
      displayName: account['username'] as String,
      bio: '',
    );
  }

  Future<PlayerProfile> createProfile({
    required String displayName,
    required String bio,
    Uint8List? avatarBytes,
    String? avatarName,
  }) async {
    final request =
        http.MultipartRequest('POST', Uri.parse('$baseUrl/profiles'))
          ..fields['displayName'] = displayName
          ..fields['bio'] = bio;
    if (avatarBytes != null) {
      request.files.add(
        http.MultipartFile.fromBytes(
          'avatar',
          avatarBytes,
          filename: avatarName ?? 'avatar.jpg',
        ),
      );
    }
    final response = await http.Response.fromStream(
      await _client.send(request),
    );
    if (response.statusCode != 201) {
      throw ProfileApiException(
        'Server returned ${response.statusCode}: ${response.body}',
      );
    }
    return PlayerProfile.fromJson(
      jsonDecode(response.body) as Map<String, dynamic>,
    );
  }
}

class ProfileApiException implements Exception {
  const ProfileApiException(this.message);
  final String message;
  @override
  String toString() => message;
}

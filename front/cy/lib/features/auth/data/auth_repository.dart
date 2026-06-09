import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:google_sign_in/google_sign_in.dart';

class AuthUser {
  final String id;
  final String name;
  final String email;

  const AuthUser({required this.id, required this.name, required this.email});

  factory AuthUser.fromJson(Map<String, dynamic> json) => AuthUser(
        id: json['id'] as String,
        name: json['name'] as String,
        email: json['email'] as String,
      );

  Map<String, dynamic> toJson() => {'id': id, 'name': name, 'email': email};
}

class AuthRepository {
  static const _jwtKey = 'auth_jwt';
  static const _userKey = 'auth_user';

  // Android emulator → 10.0.2.2, iOS simulator / web → 127.0.0.1, real device → server IP
  static const _baseUrl = 'http://10.0.2.2:3000';

  final _storage = const FlutterSecureStorage();
  final _googleSignIn = GoogleSignIn(scopes: ['email', 'profile']);
  late final Dio _dio;

  AuthRepository() {
    _dio = Dio(BaseOptions(
      baseUrl: _baseUrl,
      connectTimeout: const Duration(seconds: 10),
      receiveTimeout: const Duration(seconds: 10),
    ));
  }

  Future<({String jwt, AuthUser user})> signInWithGoogle() async {
    final googleUser = await _googleSignIn.signIn();
    if (googleUser == null) throw Exception('sign_in_cancelled');

    final googleAuth = await googleUser.authentication;
    final idToken = googleAuth.idToken;
    if (idToken == null) throw Exception('id_token_null');

    final response = await _dio.post<Map<String, dynamic>>(
      '/auth/google',
      data: {'idToken': idToken},
    );

    final data = response.data!;
    final jwt = data['jwt'] as String;
    final user = AuthUser.fromJson(data['user'] as Map<String, dynamic>);

    await Future.wait([
      _storage.write(key: _jwtKey, value: jwt),
      _storage.write(key: _userKey, value: jsonEncode(user.toJson())),
    ]);

    return (jwt: jwt, user: user);
  }

  Future<({String jwt, AuthUser user})?> getSavedSession() async {
    final jwt = await _storage.read(key: _jwtKey);
    if (jwt == null || _isJwtExpired(jwt)) return null;

    final userJson = await _storage.read(key: _userKey);
    if (userJson == null) return null;

    final user = AuthUser.fromJson(
      jsonDecode(userJson) as Map<String, dynamic>,
    );
    return (jwt: jwt, user: user);
  }

  Future<void> clearSession() async {
    await Future.wait([
      _storage.delete(key: _jwtKey),
      _storage.delete(key: _userKey),
    ]);
  }

  bool _isJwtExpired(String jwt) {
    try {
      final parts = jwt.split('.');
      if (parts.length != 3) return true;
      final payload = utf8.decode(
        base64Url.decode(base64Url.normalize(parts[1])),
      );
      final data = jsonDecode(payload) as Map<String, dynamic>;
      final exp = data['exp'];
      if (exp == null) return false;
      return DateTime.now().isAfter(
        DateTime.fromMillisecondsSinceEpoch((exp as int) * 1000),
      );
    } catch (_) {
      return true;
    }
  }
}

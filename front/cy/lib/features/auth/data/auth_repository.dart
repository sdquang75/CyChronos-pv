import 'package:dio/dio.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:google_sign_in/google_sign_in.dart';
import '../../../core/network/api_client.dart';

class AuthUser {
  /// バックエンド users テーブルの user_id(トリップ系APIで使用)
  final int? userId;
  final String uid;
  final String name;
  final String email;
  final String? photoUrl;

  const AuthUser({
    this.userId,
    required this.uid,
    required this.name,
    required this.email,
    this.photoUrl,
  });

  factory AuthUser.fromFirebase(User user, {int? userId}) => AuthUser(
        userId: userId,
        uid: user.uid,
        name: user.displayName ?? '',
        email: user.email ?? '',
        photoUrl: user.photoURL,
      );
}

/// ログイン時: バックエンド users に未登録(404)
class AccountNotRegisteredException implements Exception {}

class AuthRepository {
  final _auth = FirebaseAuth.instance;
  final _googleSignIn = GoogleSignIn();
  final Dio _dio = ApiClient.instance;

  /// ログイン: Googleサインイン → POST /api/auth/login
  /// 未登録なら [AccountNotRegisteredException] を投げる
  Future<AuthUser> signInWithGoogle() async {
    final user = await _signInWithGoogleFirebase();
    final idToken = await _requireIdToken(user);
    try {
      final data = await _postAuth('/api/auth/login', idToken);
      return AuthUser.fromFirebase(user, userId: data['user_id'] as int?);
    } on DioException catch (e) {
      if (e.response?.statusCode == 404) {
        await signOut();
        throw AccountNotRegisteredException();
      }
      rethrow;
    }
  }

  /// アカウント作成: Googleサインイン → POST /api/auth/register
  /// 登録済み(409)の場合はそのままログインに切り替える
  Future<AuthUser> registerWithGoogle() async {
    final user = await _signInWithGoogleFirebase();
    final idToken = await _requireIdToken(user);
    try {
      final data = await _postAuth('/api/auth/register', idToken);
      return AuthUser.fromFirebase(user, userId: data['user_id'] as int?);
    } on DioException catch (e) {
      if (e.response?.statusCode == 409) {
        final data = await _postAuth('/api/auth/login', idToken);
        return AuthUser.fromFirebase(user, userId: data['user_id'] as int?);
      }
      rethrow;
    }
  }

  /// セッション復元: FirebaseのキャッシュにユーザーがいればログインAPIで
  /// user_id と最新プロフィールを取得する
  Future<AuthUser?> getCurrentUser() async {
    final user = _auth.currentUser;
    if (user == null) return null;
    try {
      final idToken = await _requireIdToken(user);
      final data = await _postAuth('/api/auth/login', idToken);
      return AuthUser.fromFirebase(user, userId: data['user_id'] as int?);
    } on DioException catch (e) {
      if (e.response?.statusCode == 404) {
        // バックエンド側で未登録(削除済みなど)→ セッションを破棄
        await signOut();
        return null;
      }
      // バックエンド未起動・オフライン時は Firebase セッションのみで続行
      return AuthUser.fromFirebase(user);
    } catch (_) {
      return AuthUser.fromFirebase(user);
    }
  }

  Future<void> signOut() async {
    await _auth.signOut();
    if (!kIsWeb) await _googleSignIn.signOut();
  }

  Future<User> _signInWithGoogleFirebase() async {
    try {
      late final UserCredential credential;

      if (kIsWeb) {
        // Web: popup flow — prompt forces account picker every time
        final provider = GoogleAuthProvider()
          ..setCustomParameters({'prompt': 'select_account'});
        credential = await _auth.signInWithPopup(provider);
      } else {
        // Android/iOS: native Google Sign-In → Firebase credential
        final googleUser = await _googleSignIn.signIn();
        if (googleUser == null) throw Exception('sign_in_cancelled');

        final googleAuth = await googleUser.authentication;
        final oauthCredential = GoogleAuthProvider.credential(
          accessToken: googleAuth.accessToken,
          idToken: googleAuth.idToken,
        );
        credential = await _auth.signInWithCredential(oauthCredential);
      }

      return credential.user!;
    } on FirebaseAuthException catch (e) {
      // ポップアップをユーザーが閉じた・多重に開いた場合はキャンセル扱い
      if (e.code == 'popup-closed-by-user' ||
          e.code == 'cancelled-popup-request' ||
          e.code == 'user-cancelled') {
        throw Exception('sign_in_cancelled');
      }
      if (e.code == 'popup-blocked') {
        throw Exception('ポップアップがブロックされました。ブラウザの設定でポップアップを許可してください。');
      }
      throw Exception(e.message ?? 'auth_error');
    }
  }

  Future<String> _requireIdToken(User user) async {
    final idToken = await user.getIdToken();
    if (idToken == null) throw Exception('auth_error');
    return idToken;
  }

  Future<Map<String, dynamic>> _postAuth(String path, String idToken) async {
    final res = await _dio.post(
      path,
      options: Options(headers: {'Authorization': 'Bearer $idToken'}),
    );
    return (res.data as Map).cast<String, dynamic>();
  }
}

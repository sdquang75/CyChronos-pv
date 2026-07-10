import 'package:dio/dio.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_facebook_auth/flutter_facebook_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import '../../../core/network/api_client.dart';

class AuthUser {
  /// バックエンド users テーブルの user_id(trips/suggest APIで使用)。
  /// バックエンドに繋がらない場合は null のまま、Firebaseセッションのみで続行する。
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

class AuthRepository {
  final _auth = FirebaseAuth.instance;
  final _googleSignIn = GoogleSignIn();
  final Dio _dio = ApiClient.instance;

  // ログイン専用のボタン/導線は無い(サードパーティログインで別途「登録」を
  // 挟むのは不自然なため)。バックエンドに未登録(404)なら、その場で
  // 自動的に /api/auth/register を叩いてアカウントを作る。
  Future<AuthUser> _linkBackend(User user) async {
    final idToken = await user.getIdToken();
    if (idToken == null) return AuthUser.fromFirebase(user);

    try {
      final data = await _postAuth('/api/auth/login', idToken);
      return AuthUser.fromFirebase(user, userId: data['user_id'] as int?);
    } on DioException catch (e) {
      if (e.response?.statusCode == 404) {
        final data = await _postAuth('/api/auth/register', idToken);
        return AuthUser.fromFirebase(user, userId: data['user_id'] as int?);
      }
      // バックエンド未起動・オフライン等はFirebaseセッションのみで続行させる
      debugPrint('auth backend link failed: $e');
      return AuthUser.fromFirebase(user);
    }
  }

  Future<Map<String, dynamic>> _postAuth(String path, String idToken) async {
    final res = await _dio.post(
      path,
      options: Options(headers: {'Authorization': 'Bearer $idToken'}),
    );
    return (res.data as Map).cast<String, dynamic>();
  }

  Future<AuthUser> signInWithGoogle() async {
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

      return _linkBackend(credential.user!);
    } on FirebaseAuthException catch (e) {
      throw Exception(e.message ?? 'auth_error');
    }
  }

  Future<AuthUser> signInWithFacebook() async {
    try {
      late final UserCredential credential;

      if (kIsWeb) {
        // Web: Firebase handles the Facebook popup flow directly
        final provider = FacebookAuthProvider()
          ..addScope('email')
          ..addScope('public_profile');
        credential = await _auth.signInWithPopup(provider);
      } else {
        // Android/iOS: native Facebook Login → Firebase credential
        final result = await FacebookAuth.instance.login(
          permissions: const ['email', 'public_profile'],
        );

        switch (result.status) {
          case LoginStatus.cancelled:
            throw Exception('sign_in_cancelled');
          case LoginStatus.failed:
            throw Exception(result.message ?? 'auth_error');
          case LoginStatus.success:
          case LoginStatus.operationInProgress:
            break;
        }

        final accessToken = result.accessToken;
        if (accessToken == null) throw Exception('sign_in_cancelled');

        final oauthCredential = FacebookAuthProvider.credential(
          accessToken.tokenString,
        );
        credential = await _auth.signInWithCredential(oauthCredential);
      }

      return _linkBackend(credential.user!);
    } on FirebaseAuthException catch (e) {
      throw Exception(e.message ?? 'auth_error');
    }
  }

  // TODO: LINEログイン未実装。バックエンドでLINEアクセストークンを検証し
  // Firebaseカスタムトークンを発行するAPIができたらsignInWithCustomTokenに置き換える。
  // それまでは動作確認用に匿名サインインで代用する。
  Future<AuthUser> signInWithLine() async {
    try {
      final credential = await _auth.signInAnonymously();
      return _linkBackend(credential.user!);
    } on FirebaseAuthException catch (e) {
      throw Exception(e.message ?? 'auth_error');
    }
  }

  // セッション復元: Firebaseのキャッシュにユーザーがいれば、バックエンドから
  // 最新の user_id を取り直す(取れなくてもFirebaseセッションのみで続行)
  Future<AuthUser?> getCurrentUser() async {
    final user = _auth.currentUser;
    if (user == null) return null;
    return _linkBackend(user);
  }

  Future<void> signOut() async {
    await _auth.signOut();
    if (!kIsWeb) {
      await _googleSignIn.signOut();
      await FacebookAuth.instance.logOut();
    }
  }
}

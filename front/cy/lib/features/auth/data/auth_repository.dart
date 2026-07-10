import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_facebook_auth/flutter_facebook_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';

class AuthUser {
  final String uid;
  final String name;
  final String email;
  final String? photoUrl;

  const AuthUser({
    required this.uid,
    required this.name,
    required this.email,
    this.photoUrl,
  });

  factory AuthUser.fromFirebase(User user) => AuthUser(
        uid: user.uid,
        name: user.displayName ?? '',
        email: user.email ?? '',
        photoUrl: user.photoURL,
      );
}

class AuthRepository {
  final _auth = FirebaseAuth.instance;
  final _googleSignIn = GoogleSignIn();

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

      return AuthUser.fromFirebase(credential.user!);
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

      return AuthUser.fromFirebase(credential.user!);
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
      return AuthUser.fromFirebase(credential.user!);
    } on FirebaseAuthException catch (e) {
      throw Exception(e.message ?? 'auth_error');
    }
  }

  // Firebase restores session synchronously from cache
  AuthUser? getCurrentUser() {
    final user = _auth.currentUser;
    return user != null ? AuthUser.fromFirebase(user) : null;
  }

  Future<void> signOut() async {
    await _auth.signOut();
    if (!kIsWeb) {
      await _googleSignIn.signOut();
      await FacebookAuth.instance.logOut();
    }
  }
}

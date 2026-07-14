import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/auth_repository.dart';
import '../../domain/auth_state.dart';

final authRepositoryProvider = Provider<AuthRepository>(
  (_) => AuthRepository(),
);

final authProvider = StateNotifierProvider<AuthNotifier, AuthState>(
  (ref) => AuthNotifier(ref.watch(authRepositoryProvider)),
);

class AuthNotifier extends StateNotifier<AuthState> {
  final AuthRepository _repo;

  AuthNotifier(this._repo) : super(const AuthInitial());

  Future<void> checkAuth() async {
    state = const AuthLoading();
    final user = await _repo.getCurrentUser();
    state = user != null
        ? AuthAuthenticated(user: user)
        : const AuthUnauthenticated();
  }

  /// ログイン: Googleサインイン → バックエンドの /api/auth/login
  Future<void> signInWithGoogle() => _authenticate(
        _repo.signInWithGoogle,
        failureMessage: 'ログインに失敗しました。もう一度お試しください。',
      );

  /// アカウント作成: Googleサインイン → バックエンドの /api/auth/register
  Future<void> registerWithGoogle() => _authenticate(
        _repo.registerWithGoogle,
        failureMessage: 'アカウント作成に失敗しました。もう一度お試しください。',
      );

  Future<void> _authenticate(
    Future<AuthUser> Function() action, {
    required String failureMessage,
  }) async {
    state = const AuthLoading();
    try {
      final user = await action();
      state = AuthAuthenticated(user: user);
    } on AccountNotRegisteredException {
      state = const AuthError('アカウントが未登録です。先にアカウント作成を行ってください。');
    } on DioException catch (e) {
      // バックエンドAPIの失敗: サーバーが返した error 文言があれば表示する
      debugPrint('auth api error: $e');
      final data = e.response?.data;
      final serverMessage =
          (data is Map && data['error'] is String) ? data['error'] as String : null;
      state = AuthError(
        serverMessage ??
            (e.response == null
                ? 'サーバーに接続できません。バックエンドが起動しているか確認してください。'
                : failureMessage),
      );
    } on Exception catch (e) {
      debugPrint('auth error: $e');
      final msg = e.toString();
      if (msg.contains('sign_in_cancelled')) {
        state = const AuthUnauthenticated();
      } else if (msg.contains('ポップアップがブロックされました')) {
        state = const AuthError(
            'ポップアップがブロックされました。ブラウザの設定でポップアップを許可してください。');
      } else {
        state = AuthError(failureMessage);
      }
    }
  }

  Future<void> signOut() async {
    await _repo.signOut();
    state = const AuthUnauthenticated();
  }
}

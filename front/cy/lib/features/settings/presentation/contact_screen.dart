import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/widgets/app_card.dart';
import '../../../core/widgets/app_screen_frame.dart';
import '../../../core/widgets/app_top_bar.dart';

class ContactScreen extends StatefulWidget {
  const ContactScreen({super.key});

  @override
  State<ContactScreen> createState() => _ContactScreenState();
}

class _ContactScreenState extends State<ContactScreen> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  final TextEditingController _nameController = TextEditingController();

  final TextEditingController _emailController = TextEditingController();

  final TextEditingController _subjectController = TextEditingController();

  final TextEditingController _messageController = TextEditingController();

  bool _isSending = false;

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _subjectController.dispose();
    _messageController.dispose();
    super.dispose();
  }

  String? _validateRequired(String? value, String fieldName) {
    if (value == null || value.trim().isEmpty) {
      return '$fieldNameを入力してください';
    }

    return null;
  }

  String? _validateEmail(String? value) {
    if (value == null || value.trim().isEmpty) {
      return '返信先メールアドレスを入力してください';
    }

    final RegExp emailPattern = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$');

    if (!emailPattern.hasMatch(value.trim())) {
      return '正しいメールアドレスを入力してください';
    }

    return null;
  }

  Future<void> _submitContact() async {
    FocusScope.of(context).unfocus();

    final bool isValid = _formKey.currentState?.validate() ?? false;

    if (!isValid || _isSending) {
      return;
    }

    HapticFeedback.mediumImpact();

    setState(() {
      _isSending = true;
    });

    // 現在は画面確認用の仮送信です。
    // バックエンドやメールサービスには送信しません。
    await Future<void>.delayed(const Duration(milliseconds: 1000));

    if (!mounted) {
      return;
    }

    setState(() {
      _isSending = false;
    });

    await _showCompletedDialog();

    if (!mounted) {
      return;
    }

    _nameController.clear();
    _emailController.clear();
    _subjectController.clear();
    _messageController.clear();

    _formKey.currentState?.reset();
  }

  Future<void> _showCompletedDialog() {
    return showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) {
        return AlertDialog(
          backgroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
          ),
          icon: Container(
            width: 64,
            height: 64,
            decoration: const BoxDecoration(
              color: AppColors.accentBg,
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.check_rounded,
              size: 34,
              color: AppColors.primary,
            ),
          ),
          title: const Text(
            '送信操作が完了しました',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontFamily: 'HankenGrotesk',
              fontFamilyFallback: ['NotoSansJP'],
              fontSize: 21,
              fontWeight: FontWeight.w700,
              color: AppColors.primary,
            ),
          ),
          content: const Text(
            '現在は画面確認用の試作版です。\n'
            '入力内容は保存・外部送信されません。',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontFamily: 'Inter',
              fontFamilyFallback: ['NotoSansJP'],
              fontSize: 14,
              color: AppColors.textSecondary,
              height: 1.6,
            ),
          ),
          actionsAlignment: MainAxisAlignment.center,
          actionsPadding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
          actions: [
            SizedBox(
              width: double.infinity,
              height: 48,
              child: FilledButton(
                onPressed: () {
                  Navigator.of(dialogContext).pop();
                },
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                child: const Text(
                  '閉じる',
                  style: TextStyle(
                    fontFamily: 'HankenGrotesk',
                    fontFamilyFallback: ['NotoSansJP'],
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  void _goBack() {
    if (context.canPop()) {
      context.pop();
      return;
    }

    context.go('/settings');
  }

  @override
  Widget build(BuildContext context) {
    // ContactScreenはHomeScreenのIndexedStackの中ではなく、go_routerの
    // トップレベルルートとして/homeの上に直接pushされる(RideFlow経由では
    // ない)ので、他のpush画面と違ってAppScreenFrameを自分で持つ必要がある
    return AppScreenFrame(
      child: Scaffold(
        backgroundColor: AppColors.bgCool,
        body: SafeArea(
          bottom: false,
          child: Column(
            children: [
              AppTopBar(title: 'お問い合わせ', onBack: _goBack),
              Expanded(
                child: SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  padding: const EdgeInsets.fromLTRB(
                    AppSpacing.xxl,
                    AppSpacing.xl,
                    AppSpacing.xxl,
                    40,
                  ),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'ご意見や不具合について、以下のフォームからお問い合わせください。',
                          style: AppTypography.pageSubtitle,
                        ),

                        const SizedBox(height: AppSpacing.xxl),

                        _buildFormCard(),

                        const SizedBox(height: AppSpacing.lg),

                        _buildNoticeCard(),

                        const SizedBox(height: AppSpacing.xxl),

                        SizedBox(
                          width: double.infinity,
                          height: 56,
                          child: ElevatedButton.icon(
                            onPressed: _isSending ? null : _submitContact,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.primary,
                              foregroundColor: Colors.white,
                              disabledBackgroundColor: AppColors.primary
                                  .withValues(alpha: 0.55),
                              disabledForegroundColor: Colors.white,
                              elevation: 0,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                              ),
                            ),
                            icon:
                                _isSending
                                    ? const SizedBox(
                                      width: 20,
                                      height: 20,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2.5,
                                        color: Colors.white,
                                      ),
                                    )
                                    : const Icon(Icons.send_rounded, size: 21),
                            label: Text(
                              _isSending ? '送信しています' : '送信する',
                              style: const TextStyle(
                                fontFamily: 'HankenGrotesk',
                                fontFamilyFallback: ['NotoSansJP'],
                                fontSize: 17,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFormCard() {
    return AppCard(
      borderRadius: 24,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _FieldLabel(icon: Icons.person_outline_rounded, text: 'お名前'),

          const SizedBox(height: 10),

          _ContactTextField(
            controller: _nameController,
            hintText: '例：山田 太郎',
            textInputAction: TextInputAction.next,
            validator: (value) {
              return _validateRequired(value, 'お名前');
            },
          ),

          const SizedBox(height: 20),

          const _FieldLabel(
            icon: Icons.mail_outline_rounded,
            text: '返信先メールアドレス',
          ),

          const SizedBox(height: 10),

          _ContactTextField(
            controller: _emailController,
            hintText: '例：example@gmail.com',
            keyboardType: TextInputType.emailAddress,
            textInputAction: TextInputAction.next,
            validator: _validateEmail,
          ),

          const SizedBox(height: 20),

          const _FieldLabel(icon: Icons.title_rounded, text: '件名'),

          const SizedBox(height: 10),

          _ContactTextField(
            controller: _subjectController,
            hintText: 'お問い合わせの件名',
            textInputAction: TextInputAction.next,
            validator: (value) {
              return _validateRequired(value, '件名');
            },
          ),

          const SizedBox(height: 20),

          const _FieldLabel(
            icon: Icons.chat_bubble_outline_rounded,
            text: 'お問い合わせ内容',
          ),

          const SizedBox(height: 10),

          _ContactTextField(
            controller: _messageController,
            hintText: 'ご意見や不具合の内容をご入力ください',
            keyboardType: TextInputType.multiline,
            textInputAction: TextInputAction.newline,
            minLines: 6,
            maxLines: 10,
            validator: (value) {
              return _validateRequired(value, 'お問い合わせ内容');
            },
          ),
        ],
      ),
    );
  }

  Widget _buildNoticeCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.accentBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppColors.primary.withValues(alpha: 0.12),
        ),
      ),
      child: const Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            Icons.info_outline_rounded,
            size: 20,
            color: AppColors.primary,
          ),
          SizedBox(width: 10),
          Expanded(
            child: Text(
              '現在は画面確認用の試作版です。'
              '送信ボタンを押しても、入力内容は保存・外部送信されません。',
              style: TextStyle(
                fontFamily: 'Inter',
                fontFamilyFallback: ['NotoSansJP'],
                fontSize: 13,
                color: AppColors.textSecondary,
                height: 1.6,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _FieldLabel extends StatelessWidget {
  const _FieldLabel({required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 19, color: AppColors.primary),
        const SizedBox(width: 8),
        Text(
          text,
          style: const TextStyle(
            fontFamily: 'HankenGrotesk',
            fontFamilyFallback: ['NotoSansJP'],
            fontSize: 15,
            fontWeight: FontWeight.w700,
            color: AppColors.primary,
          ),
        ),
      ],
    );
  }
}

class _ContactTextField extends StatelessWidget {
  const _ContactTextField({
    required this.controller,
    required this.hintText,
    required this.validator,
    this.keyboardType,
    this.textInputAction,
    this.minLines = 1,
    this.maxLines = 1,
  });

  final TextEditingController controller;
  final String hintText;
  final String? Function(String?) validator;
  final TextInputType? keyboardType;
  final TextInputAction? textInputAction;
  final int minLines;
  final int maxLines;

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      textInputAction: textInputAction,
      minLines: minLines,
      maxLines: maxLines,
      validator: validator,
      autovalidateMode: AutovalidateMode.onUserInteraction,
      style: const TextStyle(
        fontFamily: 'Inter',
        fontFamilyFallback: ['NotoSansJP'],
        fontSize: 15,
        color: AppColors.primary,
        height: 1.5,
      ),
      decoration: InputDecoration(
        hintText: hintText,
        hintStyle: TextStyle(
          fontFamily: 'Inter',
          fontFamilyFallback: const ['NotoSansJP'],
          fontSize: 14,
          color: AppColors.textSecondary.withValues(alpha: 0.55),
        ),
        filled: true,
        fillColor: AppColors.bgCool,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 15,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(
            color: AppColors.border.withValues(alpha: 0.45),
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(
            color: AppColors.primary,
            width: 1.5,
          ),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: AppColors.error),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(
            color: AppColors.error,
            width: 1.5,
          ),
        ),
      ),
    );
  }
}

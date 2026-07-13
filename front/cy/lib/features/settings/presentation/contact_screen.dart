import 'package:flutter/material.dart';
import 'package:cy/core/theme/app_colors.dart';
import 'package:cy/core/widgets/app_screen_frame.dart';
import 'package:cy/core/widgets/app_top_bar.dart';

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
    final emailPattern = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$');
    if (!emailPattern.hasMatch(value.trim())) {
      return '正しいメールアドレスを入力してください';
    }
    return null;
  }

  Future<void> _submitContact() async {
    FocusScope.of(context).unfocus();
    final isValid = _formKey.currentState?.validate() ?? false;
    if (!isValid || _isSending) return;

    setState(() => _isSending = true);

    // 現在は画面確認用の仮送信です。バックエンドやメールサービスには送信しません。
    await Future<void>.delayed(const Duration(milliseconds: 1000));
    if (!mounted) return;
    setState(() => _isSending = false);

    await _showCompletedDialog();
    if (!mounted) return;

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
      builder: (dialogContext) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        icon: Container(
          width: 64,
          height: 64,
          decoration: const BoxDecoration(
            color: AppColors.terracottaChipBg,
            shape: BoxShape.circle,
          ),
          child: const Icon(
            Icons.check_rounded,
            size: 34,
            color: AppColors.terracottaDeep,
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
            color: AppColors.terracottaDeep,
          ),
        ),
        content: const Text(
          '現在は画面確認用の試作版です。\n入力内容は保存・外部送信されません。',
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
              onPressed: () => Navigator.of(dialogContext).pop(),
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.terracottaDeep,
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
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    Widget content = Scaffold(
      backgroundColor: AppColors.bgCool,
      body: SafeArea(
        bottom: false,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const AppTopBar(title: 'Contact', fallbackRoute: '/settings'),
            Expanded(
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.fromLTRB(24, 20, 24, 40),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'ご意見や不具合について、以下のフォームからお問い合わせください。',
                        style: TextStyle(
                          fontFamily: 'Inter',
                          fontFamilyFallback: ['NotoSansJP'],
                          fontSize: 14,
                          color: AppColors.textSecondary,
                          height: 1.6,
                        ),
                      ),
                      const SizedBox(height: 24),
                      _buildFormCard(),
                      const SizedBox(height: 16),
                      _buildNoticeCard(),
                      const SizedBox(height: 24),
                      SizedBox(
                        width: double.infinity,
                        height: 56,
                        child: ElevatedButton.icon(
                          onPressed: _isSending ? null : _submitContact,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.terracottaDeep,
                            foregroundColor: Colors.white,
                            disabledBackgroundColor: AppColors.terracottaDeep
                                .withValues(alpha: 0.55),
                            disabledForegroundColor: Colors.white,
                            elevation: 0,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                          ),
                          icon: _isSending
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
    );

    return AppScreenFrame(child: content);
  }

  Widget _buildFormCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: AppColors.terracottaBorder.withValues(alpha: 0.35),
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.terracottaCardShadow.withValues(alpha: 0.04),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _FieldLabel(icon: Icons.person_outline_rounded, text: 'お名前'),
          const SizedBox(height: 10),
          _ContactTextField(
            controller: _nameController,
            hintText: '例：山田 太郎',
            textInputAction: TextInputAction.next,
            validator: (value) => _validateRequired(value, 'お名前'),
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
            validator: (value) => _validateRequired(value, '件名'),
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
            validator: (value) => _validateRequired(value, 'お問い合わせ内容'),
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
        color: AppColors.terracottaChipBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppColors.terracottaDeep.withValues(alpha: 0.12),
        ),
      ),
      child: const Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            Icons.info_outline_rounded,
            size: 20,
            color: AppColors.terracottaDeep,
          ),
          SizedBox(width: 10),
          Expanded(
            child: Text(
              '現在は画面確認用の試作版です。送信ボタンを押しても、入力内容は保存・外部送信されません。',
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
        Icon(icon, size: 19, color: AppColors.terracottaDeep),
        const SizedBox(width: 8),
        Text(
          text,
          style: const TextStyle(
            fontFamily: 'HankenGrotesk',
            fontFamilyFallback: ['NotoSansJP'],
            fontSize: 15,
            fontWeight: FontWeight.w700,
            color: AppColors.terracottaDeep,
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
        color: AppColors.terracottaDeep,
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
            color: AppColors.terracottaBorder.withValues(alpha: 0.45),
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(
            color: AppColors.terracottaDeep,
            width: 1.5,
          ),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: AppColors.danger),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: AppColors.danger, width: 1.5),
        ),
      ),
    );
  }
}

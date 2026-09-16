import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../core/network/api_exception.dart';
import '../../data/auth_repository.dart';
import '../../data/auth_error_message.dart';
import '../widgets/login_header.dart';
import '../widgets/password_field.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({
    super.key,
    required this.authRepository,
    required this.onLogin,
  });
  final AuthRepository authRepository;
  final FutureOr<void> Function(AuthSession) onLogin;

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _phoneController = TextEditingController();
  final _codeController = TextEditingController();
  final _passwordController = TextEditingController();
  Timer? _countdownTimer;
  int _countdownSeconds = 0;
  bool _passwordMode = false;
  bool _sendingCode = false;
  bool _submitting = false;
  String? _errorText;
  static const _teal = Color(0xFF4DBDBB);

  String? get _phone => RegExp(r'^1[3-9]\d{9}$').hasMatch(_phoneController.text)
      ? _phoneController.text
      : null;
  bool get _canSendCode =>
      _phone != null && !_sendingCode && !_submitting && _countdownSeconds == 0;
  bool get _canSubmit =>
      _phone != null &&
      !_submitting &&
      (_passwordMode
          ? _passwordController.text.isNotEmpty
          : RegExp(r'^\d{4,6}$').hasMatch(_codeController.text));

  @override
  void dispose() {
    _countdownTimer?.cancel();
    _phoneController.dispose();
    _codeController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _switchMode(bool passwordMode) {
    if (_submitting) return;
    setState(() {
      _passwordMode = passwordMode;
      _errorText = null;
    });
  }

  Future<void> _sendCode() async {
    if (!_canSendCode) return;
    setState(() {
      _sendingCode = true;
      _errorText = null;
    });
    try {
      await widget.authRepository.sendPhoneCode(_phone!);
      if (!mounted) return;
      setState(() => _countdownSeconds = 60);
      _countdownTimer?.cancel();
      _countdownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
        if (!mounted) {
          timer.cancel();
          return;
        }
        setState(() => _countdownSeconds--);
        if (_countdownSeconds == 0) timer.cancel();
      });
    } on ApiException catch (error) {
      if (mounted) setState(() => _errorText = authErrorMessage(error));
    } catch (_) {
      if (mounted) setState(() => _errorText = '验证码发送失败，请稍后重试');
    } finally {
      if (mounted) setState(() => _sendingCode = false);
    }
  }

  Future<void> _submit() async {
    if (!_canSubmit) return;
    FocusScope.of(context).unfocus();
    setState(() {
      _submitting = true;
      _errorText = null;
    });
    try {
      final session = _passwordMode
          ? await widget.authRepository.loginWithPassword(
              phone: _phone!,
              password: _passwordController.text,
            )
          : await widget.authRepository.loginWithPhone(
              phone: _phone!,
              code: _codeController.text,
            );
      if (!mounted) return;
      await widget.onLogin(session);
    } on ApiException catch (error) {
      if (!mounted) return;
      setState(
        () => _errorText = _passwordMode && error.statusCode == 401
            ? '手机号或密码错误，连续输错 5 次将锁定 15 分钟'
            : authErrorMessage(error),
      );
    } catch (_) {
      if (mounted) setState(() => _errorText = '登录失败，请检查网络后重试');
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) => AnnotatedRegion<SystemUiOverlayStyle>(
    value: SystemUiOverlayStyle.light,
    child: Scaffold(
      backgroundColor: Colors.white,
      body: LayoutBuilder(
        builder: (context, constraints) => SingleChildScrollView(
          child: ConstrainedBox(
            constraints: BoxConstraints(minHeight: constraints.maxHeight),
            child: Stack(
              children: [
                const LoginHeader(),
                Padding(
                  padding: const EdgeInsets.only(top: 273),
                  child: Container(
                    constraints: BoxConstraints(
                      minHeight: (constraints.maxHeight - 273).clamp(
                        0,
                        double.infinity,
                      ),
                    ),
                    padding: EdgeInsets.fromLTRB(
                      29,
                      32,
                      29,
                      28 + MediaQuery.paddingOf(context).bottom,
                    ),
                    decoration: const BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.vertical(
                        top: Radius.circular(31),
                      ),
                    ),
                    child: AutofillGroup(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            '登录',
                            style: TextStyle(
                              color: Color(0xFF173B3A),
                              fontSize: 27,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          const SizedBox(height: 18),
                          Row(
                            children: [
                              _tab('验证码登录', false),
                              const SizedBox(width: 20),
                              _tab('密码登录', true),
                            ],
                          ),
                          const SizedBox(height: 24),
                          TextField(
                            controller: _phoneController,
                            enabled: !_submitting,
                            keyboardType: TextInputType.phone,
                            textInputAction: TextInputAction.next,
                            autofillHints: const [
                              AutofillHints.telephoneNumberNational,
                            ],
                            inputFormatters: [
                              FilteringTextInputFormatter.digitsOnly,
                              LengthLimitingTextInputFormatter(11),
                            ],
                            onChanged: (_) => setState(() => _errorText = null),
                            decoration: _decoration('请输入手机号').copyWith(
                              prefixIcon: const Padding(
                                padding: EdgeInsets.only(left: 18, right: 8),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(
                                      Icons.phone_outlined,
                                      size: 18,
                                      color: Color(0xFF9CA4AE),
                                    ),
                                    SizedBox(width: 12),
                                    Text(
                                      '│  +86',
                                      style: TextStyle(
                                        color: Color(0xFF8C939D),
                                        fontSize: 14,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            style: const TextStyle(fontSize: 15),
                          ),
                          const SizedBox(height: 14),
                          if (_passwordMode) ...[
                            PasswordField(
                              controller: _passwordController,
                              hintText: '请输入密码',
                              enabled: !_submitting,
                              fillColor: const Color(0xFFF3F4F6),
                              radius: 26,
                              autofillHints: const [AutofillHints.password],
                              onChanged: (_) => setState(() {}),
                              onSubmitted: (_) => _submit(),
                            ),
                            Align(
                              alignment: Alignment.centerRight,
                              child: TextButton(
                                onPressed: _submitting
                                    ? null
                                    : () => _switchMode(false),
                                style: TextButton.styleFrom(
                                  minimumSize: const Size(0, 32),
                                  padding: EdgeInsets.zero,
                                  tapTargetSize:
                                      MaterialTapTargetSize.shrinkWrap,
                                ),
                                child: const Text(
                                  '忘记密码？',
                                  style: TextStyle(color: _teal, fontSize: 12),
                                ),
                              ),
                            ),
                          ] else
                            TextField(
                              controller: _codeController,
                              enabled: !_submitting,
                              keyboardType: TextInputType.number,
                              autofillHints: const [AutofillHints.oneTimeCode],
                              inputFormatters: [
                                FilteringTextInputFormatter.digitsOnly,
                                LengthLimitingTextInputFormatter(6),
                              ],
                              onChanged: (_) => setState(() {}),
                              onSubmitted: (_) => _submit(),
                              decoration: _decoration('验证码').copyWith(
                                prefixIcon: const Icon(
                                  Icons.lock_outline_rounded,
                                  size: 19,
                                  color: Color(0xFF9CA4AE),
                                ),
                                suffixIcon: Padding(
                                  padding: const EdgeInsets.all(6),
                                  child: FilledButton(
                                    onPressed: _canSendCode ? _sendCode : null,
                                    style: FilledButton.styleFrom(
                                      backgroundColor: _teal,
                                      disabledBackgroundColor: const Color(
                                        0xFFE4E6EB,
                                      ),
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 14,
                                      ),
                                    ),
                                    child: Text(
                                      _sendingCode
                                          ? '发送中'
                                          : _countdownSeconds > 0
                                          ? '${_countdownSeconds}s'
                                          : '获取验证码',
                                      style: const TextStyle(fontSize: 12),
                                    ),
                                  ),
                                ),
                              ),
                              style: const TextStyle(fontSize: 15),
                            ),
                          if (_errorText != null)
                            Padding(
                              padding: const EdgeInsets.only(top: 10),
                              child: Text(
                                _errorText!,
                                style: const TextStyle(
                                  color: Color(0xFFCF4444),
                                  fontSize: 13,
                                ),
                              ),
                            ),
                          SizedBox(height: _passwordMode ? 20 : 48),
                          SizedBox(
                            width: double.infinity,
                            height: 54,
                            child: FilledButton(
                              onPressed: _canSubmit ? _submit : null,
                              style: FilledButton.styleFrom(
                                backgroundColor: _teal,
                                disabledBackgroundColor: const Color(
                                  0xFFE4E6EB,
                                ),
                                disabledForegroundColor: const Color(
                                  0xFF9CA4AE,
                                ),
                              ),
                              child: _submitting
                                  ? const SizedBox(
                                      width: 20,
                                      height: 20,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        color: Colors.white,
                                      ),
                                    )
                                  : Text(
                                      _passwordMode ? '登录' : '登录 / 注册',
                                      style: const TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                            ),
                          ),
                          if (_passwordMode)
                            Padding(
                              padding: const EdgeInsets.only(top: 6),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  const Text(
                                    '没有账号？',
                                    style: TextStyle(
                                      color: Color(0xFF9CA4AE),
                                      fontSize: 12,
                                    ),
                                  ),
                                  TextButton(
                                    onPressed: _submitting
                                        ? null
                                        : () => _switchMode(false),
                                    child: const Text(
                                      '验证码注册',
                                      style: TextStyle(
                                        color: _teal,
                                        fontSize: 12,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          const SizedBox(height: 18),
                          const Center(
                            child: Text.rich(
                              TextSpan(
                                text: '登录即代表同意 ',
                                children: [
                                  TextSpan(
                                    text: '《用户协议》',
                                    style: TextStyle(color: _teal),
                                  ),
                                  TextSpan(text: ' 和 '),
                                  TextSpan(
                                    text: '《隐私政策》',
                                    style: TextStyle(color: _teal),
                                  ),
                                ],
                              ),
                              style: TextStyle(
                                color: Color(0xFF9CA4AE),
                                fontSize: 12,
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
      ),
    ),
  );

  Widget _tab(String title, bool passwordMode) {
    final selected = _passwordMode == passwordMode;
    return InkWell(
      onTap: _submitting ? null : () => _switchMode(passwordMode),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 6),
        decoration: BoxDecoration(
          border: Border(
            bottom: BorderSide(
              color: selected ? _teal : Colors.transparent,
              width: 2,
            ),
          ),
        ),
        child: Text(
          title,
          style: TextStyle(
            fontSize: 14,
            fontWeight: selected ? FontWeight.w700 : FontWeight.w400,
            color: selected ? const Color(0xFF173B3A) : const Color(0xFF9CA4AE),
          ),
        ),
      ),
    );
  }

  InputDecoration _decoration(String hint) => InputDecoration(
    hintText: hint,
    isDense: true,
    constraints: const BoxConstraints(minHeight: 52),
    suffixIconConstraints: const BoxConstraints(maxHeight: 52),
    filled: true,
    fillColor: const Color(0xFFF3F4F6),
    hintStyle: const TextStyle(color: Color(0xFFB7BBC3), fontSize: 14),
    contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(26),
      borderSide: BorderSide.none,
    ),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(26),
      borderSide: BorderSide.none,
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(26),
      borderSide: const BorderSide(color: _teal),
    ),
  );
}

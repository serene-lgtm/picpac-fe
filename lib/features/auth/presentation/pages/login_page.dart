import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../core/network/api_exception.dart';
import '../../data/auth_repository.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({
    super.key,
    required this.authRepository,
    required this.onLogin,
  });

  final AuthRepository authRepository;
  final ValueChanged<AuthSession> onLogin;

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _phoneController = TextEditingController();
  final _codeController = TextEditingController();
  Timer? _countdownTimer;
  int _countdownSeconds = 0;
  bool _sendingCode = false;
  bool _submitting = false;
  String? _errorText;

  bool get _canSendCode =>
      _normalizedPhone != null && !_sendingCode && _countdownSeconds == 0;
  bool get _canSubmit =>
      _normalizedPhone != null &&
      _codeController.text.trim().length == 6 &&
      !_submitting;

  String? get _normalizedPhone {
    final digits = _phoneController.text.replaceAll(RegExp(r'\D'), '');
    if (digits.length != 11) return null;
    return digits;
  }

  @override
  void dispose() {
    _countdownTimer?.cancel();
    _phoneController.dispose();
    _codeController.dispose();
    super.dispose();
  }

  Future<void> _sendCode() async {
    final phone = _normalizedPhone;
    if (phone == null || _sendingCode) return;

    setState(() {
      _sendingCode = true;
      _errorText = null;
    });
    try {
      await widget.authRepository.sendPhoneCode(phone);
      if (!mounted) return;
      _startCountdown();
    } on ApiException catch (error) {
      if (!mounted) return;
      setState(() {
        _errorText = error.message;
      });
    } finally {
      if (mounted) {
        setState(() {
          _sendingCode = false;
        });
      }
    }
  }

  void _startCountdown() {
    _countdownTimer?.cancel();
    setState(() {
      _countdownSeconds = 60;
    });
    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }
      if (_countdownSeconds <= 1) {
        timer.cancel();
        setState(() {
          _countdownSeconds = 0;
        });
        return;
      }
      setState(() {
        _countdownSeconds -= 1;
      });
    });
  }

  Future<void> _submit() async {
    final phone = _normalizedPhone;
    final code = _codeController.text.trim();
    if (phone == null || code.length != 6 || _submitting) return;

    setState(() {
      _submitting = true;
      _errorText = null;
    });
    try {
      final session = await widget.authRepository.loginWithPhone(
        phone: phone,
        code: code,
      );
      if (!mounted) return;
      widget.onLogin(session);
    } on ApiException catch (error) {
      if (!mounted) return;
      setState(() {
        _errorText = error.message;
      });
    } finally {
      if (mounted) {
        setState(() {
          _submitting = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light,
      child: Scaffold(
        backgroundColor: const Color(0xFF7ED1AD),
        body: Stack(
          children: [
            Positioned.fill(
              child: Column(
                children: [
                  Container(
                    height: 312,
                    decoration: const BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [Color(0xFF74CABD), Color(0xFF98E39D)],
                      ),
                    ),
                  ),
                  const Expanded(child: ColoredBox(color: Colors.white)),
                ],
              ),
            ),
            const _LoginBubble(left: -36, top: -2, size: 96, opacity: 0.15),
            const _LoginBubble(right: -9, top: 0, size: 78, opacity: 0.15),
            const _LoginBubble(right: 28, top: 70, size: 48, opacity: 0.13),
            Positioned(
              left: 34,
              top: 74,
              child: Text(
                '你好！',
                style: theme.textTheme.displaySmall?.copyWith(
                  color: Colors.white,
                  fontSize: 36,
                  fontWeight: FontWeight.w800,
                  height: 1,
                ),
              ),
            ),
            Positioned(
              left: 34,
              top: 126,
              child: Text(
                '欢迎使用picpac',
                style: theme.textTheme.bodyLarge?.copyWith(
                  color: Colors.white.withValues(alpha: 0.82),
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            Positioned(
              right: -27,
              top: 45,
              child: Image.asset(
                'assets/pages/login/login_cover.png',
                width: 280,
                height: 239,
                fit: BoxFit.contain,
              ),
            ),
            Positioned(
              left: 0,
              right: 0,
              top: 273,
              bottom: 0,
              child: Container(
                decoration: const BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.vertical(top: Radius.circular(31)),
                ),
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(29, 35, 29, 28),
                  children: [
                    Text(
                      '登录',
                      style: theme.textTheme.headlineSmall?.copyWith(
                        color: const Color(0xFF173B3A),
                        fontSize: 27,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 31),
                    _LoginInputShell(
                      child: TextField(
                        controller: _phoneController,
                        keyboardType: TextInputType.phone,
                        textInputAction: TextInputAction.next,
                        inputFormatters: [
                          FilteringTextInputFormatter.digitsOnly,
                          LengthLimitingTextInputFormatter(11),
                        ],
                        onChanged: (_) => setState(() {}),
                        decoration: const InputDecoration(
                          border: InputBorder.none,
                          enabledBorder: InputBorder.none,
                          focusedBorder: InputBorder.none,
                          isDense: true,
                          contentPadding: EdgeInsets.zero,
                          icon: Icon(
                            Icons.phone_outlined,
                            size: 19,
                            color: Color(0xFFAEB5BE),
                          ),
                          prefixIcon: _LoginCountryCode(),
                          prefixIconConstraints: BoxConstraints(
                            minWidth: 64,
                            maxWidth: 64,
                          ),
                          hintText: '17714485033',
                          hintStyle: TextStyle(
                            color: Color(0xFF26393D),
                            fontSize: 15,
                          ),
                        ),
                        style: const TextStyle(
                          color: Color(0xFF26393D),
                          fontSize: 15,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                    const SizedBox(height: 14),
                    _LoginInputShell(
                      child: Row(
                        children: [
                          Expanded(
                            child: TextField(
                              controller: _codeController,
                              keyboardType: TextInputType.number,
                              inputFormatters: [
                                FilteringTextInputFormatter.digitsOnly,
                                LengthLimitingTextInputFormatter(6),
                              ],
                              onChanged: (_) => setState(() {}),
                              decoration: const InputDecoration(
                                border: InputBorder.none,
                                enabledBorder: InputBorder.none,
                                focusedBorder: InputBorder.none,
                                isDense: true,
                                contentPadding: EdgeInsets.zero,
                                icon: Icon(
                                  Icons.lock_outline_rounded,
                                  size: 19,
                                  color: Color(0xFFAEB5BE),
                                ),
                                hintText: '验证码',
                                hintStyle: TextStyle(
                                  color: Color(0xFFB7BBC3),
                                  fontSize: 15,
                                ),
                              ),
                              style: const TextStyle(
                                color: Color(0xFF26393D),
                                fontSize: 15,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                          SizedBox(
                            height: 42,
                            child: FilledButton(
                              onPressed: _canSendCode ? _sendCode : null,
                              style: FilledButton.styleFrom(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 17,
                                ),
                                backgroundColor: const Color(0xFF4DBDBB),
                                foregroundColor: Colors.white,
                                disabledBackgroundColor: const Color(
                                  0xFFDDE1E6,
                                ),
                                disabledForegroundColor: const Color(
                                  0xFF9CA4AE,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(21),
                                ),
                                elevation: 0,
                              ),
                              child: Text(
                                _sendingCode
                                    ? '发送中'
                                    : _countdownSeconds > 0
                                    ? '${_countdownSeconds}s'
                                    : '获取验证码',
                                style: const TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (_errorText != null) ...[
                      const SizedBox(height: 10),
                      Text(
                        _errorText!,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.error,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                    const SizedBox(height: 47),
                    SizedBox(
                      height: 55,
                      child: FilledButton(
                        onPressed: _canSubmit ? _submit : null,
                        style: FilledButton.styleFrom(
                          backgroundColor: const Color(0xFF4DBDBB),
                          foregroundColor: Colors.white,
                          disabledBackgroundColor: const Color(0xFFE1E4EA),
                          disabledForegroundColor: const Color(0xFF9EA7B0),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(28),
                          ),
                          elevation: 0,
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
                            : const Text(
                                '登录',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                      ),
                    ),
                    const SizedBox(height: 18),
                    Text.rich(
                      TextSpan(
                        text: '登录即代表同意 ',
                        children: const [
                          TextSpan(
                            text: '《用户协议》',
                            style: TextStyle(color: Color(0xFF4DBDBB)),
                          ),
                          TextSpan(text: ' 和 '),
                          TextSpan(
                            text: '《隐私政策》',
                            style: TextStyle(color: Color(0xFF4DBDBB)),
                          ),
                        ],
                      ),
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        color: Color(0xFF8B94A0),
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _LoginBubble extends StatelessWidget {
  const _LoginBubble({
    this.left,
    this.right,
    required this.top,
    required this.size,
    required this.opacity,
  });

  final double? left;
  final double? right;
  final double top;
  final double size;
  final double opacity;

  @override
  Widget build(BuildContext context) {
    return Positioned(
      left: left,
      right: right,
      top: top,
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: opacity),
          shape: BoxShape.circle,
        ),
      ),
    );
  }
}

class _LoginInputShell extends StatelessWidget {
  const _LoginInputShell({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 52,
      padding: const EdgeInsets.symmetric(horizontal: 18),
      decoration: BoxDecoration(
        color: const Color(0xFFF0F1F5),
        borderRadius: BorderRadius.circular(26),
      ),
      alignment: Alignment.center,
      child: child,
    );
  }
}

class _LoginCountryCode extends StatelessWidget {
  const _LoginCountryCode();

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(width: 1, height: 18, color: const Color(0xFFD2D6DC)),
        const SizedBox(width: 13),
        const Text(
          '+86',
          style: TextStyle(color: Color(0xFF8C939D), fontSize: 14),
        ),
      ],
    );
  }
}

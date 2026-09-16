import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../core/network/api_exception.dart';
import '../../../../shared/widgets/module_top_bar.dart';
import '../../../auth/data/auth_error_message.dart';
import '../../../auth/data/auth_repository.dart';
import '../../../auth/data/password_rules.dart';
import '../../../auth/presentation/widgets/password_field.dart';
import '../../../auth/presentation/widgets/password_requirements.dart';
import '../../data/me_repository.dart';
import '../widgets/me_common_widgets.dart';
import 'me_session_scope.dart';

class MeResetPasswordPage extends StatefulWidget {
  const MeResetPasswordPage({
    super.key,
    required this.meRepository,
    required this.authRepository,
    required this.phone,
  });

  final MeRepository meRepository;
  final AuthRepository authRepository;
  final String phone;

  @override
  State<MeResetPasswordPage> createState() => _MeResetPasswordPageState();
}

class _MeResetPasswordPageState extends State<MeResetPasswordPage> {
  final _password = TextEditingController();
  final _confirmation = TextEditingController();
  final _code = TextEditingController();
  late final _phone = TextEditingController(
    text: _validPhone(widget.phone) ? widget.phone.trim() : '',
  );
  Timer? _countdownTimer;
  Timer? _toastTimer;
  int _seconds = 0;
  bool _sending = false;
  bool _saving = false;
  bool _reset = false;
  String? _toast;

  static bool _validPhone(String value) =>
      RegExp(r'^(\+86)?1[3-9][0-9]{9}$').hasMatch(value.trim());
  bool get _knownPhone => _validPhone(widget.phone);
  bool get _valid =>
      _validPhone(_phone.text) &&
      RegExp(r'^[0-9]{6}$').hasMatch(_code.text) &&
      PasswordRules(_password.text).isValid &&
      _password.text == _confirmation.text;

  @override
  void dispose() {
    _countdownTimer?.cancel();
    _toastTimer?.cancel();
    _password.dispose();
    _confirmation.dispose();
    _code.dispose();
    _phone.dispose();
    super.dispose();
  }

  void _showToast(String message) {
    _toastTimer?.cancel();
    setState(() => _toast = message);
    _toastTimer = Timer(const Duration(seconds: 2), () {
      if (mounted) setState(() => _toast = null);
    });
  }

  Future<void> _sendCode() async {
    if (_sending || _saving || _seconds > 0 || !_validPhone(_phone.text)) {
      return;
    }
    setState(() => _sending = true);
    try {
      await widget.authRepository.sendPhoneCode(_phone.text.trim());
      if (!mounted) return;
      setState(() => _seconds = 60);
      _countdownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
        if (!mounted) return timer.cancel();
        setState(() => _seconds--);
        if (_seconds == 0) timer.cancel();
      });
      _showToast('验证码已发送');
    } on ApiException catch (error) {
      if (mounted) _showToast(authErrorMessage(error));
    } catch (_) {
      if (mounted) _showToast('发送失败，请检查网络后重试');
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  Future<void> _save() async {
    if (!_valid || _saving || _sending) return;
    final session = MeSessionScope.of(context);
    final navigator = Navigator.of(context);
    FocusScope.of(context).unfocus();
    _toastTimer?.cancel();
    setState(() {
      _saving = true;
      _toast = null;
    });
    try {
      await widget.meRepository.resetPassword(
        phone: _phone.text.trim(),
        code: _code.text,
        newPassword: _password.text,
      );
    } on ApiException catch (error) {
      if (mounted) {
        setState(() => _saving = false);
        _showToast(_resetError(error));
      }
      return;
    } catch (_) {
      if (mounted) {
        setState(() => _saving = false);
        _showToast('重置失败，请检查网络后重试');
      }
      return;
    }
    if (!mounted) return;
    _countdownTimer?.cancel();
    _password.clear();
    _confirmation.clear();
    _code.clear();
    setState(() {
      _reset = true;
      _toast = '修改成功';
    });
    await Future<void>.delayed(const Duration(seconds: 2));
    // The reset endpoint already revoked refresh tokens; clear local credentials.
    await session.passwordChanged();
    if (navigator.mounted) navigator.popUntil((route) => route.isFirst);
  }

  String _resetError(ApiException error) => switch (error.statusCode) {
    400 => '重置失败，请检查手机号、验证码和密码，新密码不能与旧密码相同',
    403 => '请确认手机号属于当前账号，且账号未被禁用',
    404 => '账号不存在或尚未设置密码，请返回账号安全页检查',
    409 => '密码已发生变化，请重新获取验证码后重试',
    502 => '短信验证服务暂时不可用，请稍后重试',
    500 => '重置失败，请重新获取验证码后重试',
    _ => authErrorMessage(error),
  };

  @override
  Widget build(BuildContext context) => PopScope(
    canPop: !_saving,
    child: MeGradientScaffold(
      child: Stack(
        children: [
          Column(
            children: [
              ModuleTopBar(
                title: '重置密码',
                foregroundColor: Colors.white,
                leading: Icons.chevron_left_rounded,
                onLeadingTap: _saving
                    ? null
                    : () => Navigator.of(context).maybePop(),
              ),
              Expanded(
                child: ListView(
                  padding: EdgeInsets.fromLTRB(
                    16,
                    6,
                    16,
                    24 + MediaQuery.paddingOf(context).bottom,
                  ),
                  children: [
                    _panel([
                      _label('新密码'),
                      PasswordField(
                        controller: _password,
                        hintText: '请输入新密码',
                        enabled: !_saving,
                        onChanged: (_) => setState(() {}),
                      ),
                      PasswordRequirements(value: _password.text, panel: true),
                      const SizedBox(height: 18),
                      _label('确认新密码'),
                      PasswordField(
                        controller: _confirmation,
                        hintText: '请再次输入新密码',
                        enabled: !_saving,
                        onChanged: (_) => setState(() {}),
                      ),
                      if (_confirmation.text.isNotEmpty &&
                          _confirmation.text != _password.text)
                        const Padding(
                          padding: EdgeInsets.only(top: 8),
                          child: Text(
                            '两次输入的密码不一致',
                            style: TextStyle(color: meSubText, fontSize: 12),
                          ),
                        ),
                    ]),
                    const SizedBox(height: 16),
                    _panel([
                      const Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Icon(Icons.info_outline, color: meTeal, size: 20),
                          SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              '将向绑定手机号发送 6 位验证码以验证您的身份，验证通过后可直接设置新密码。',
                              style: TextStyle(fontSize: 13, height: 1.6),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 14),
                      if (_knownPhone)
                        InputDecorator(
                          decoration: _decoration(
                            '',
                            Icons.phone_iphone_rounded,
                          ),
                          child: Text(
                            _maskedPhone,
                            style: const TextStyle(fontSize: 15),
                          ),
                        )
                      else
                        TextField(
                          key: const ValueKey('reset-phone'),
                          controller: _phone,
                          enabled: !_saving && !_sending,
                          keyboardType: TextInputType.phone,
                          onChanged: (_) {
                            _code.clear();
                            setState(() {});
                          },
                          decoration: _decoration(
                            '请输入当前账号完整手机号',
                            Icons.phone_iphone_rounded,
                          ),
                        ),
                      const SizedBox(height: 12),
                      TextField(
                        key: const ValueKey('reset-code'),
                        controller: _code,
                        enabled: !_saving,
                        keyboardType: TextInputType.number,
                        autofillHints: const [AutofillHints.oneTimeCode],
                        inputFormatters: [
                          FilteringTextInputFormatter.digitsOnly,
                          LengthLimitingTextInputFormatter(6),
                        ],
                        onChanged: (_) => setState(() {}),
                        onSubmitted: (_) => _save(),
                        decoration:
                            _decoration(
                              '输入 6 位验证码',
                              Icons.lock_outline_rounded,
                            ).copyWith(
                              suffixIcon: TextButton(
                                onPressed:
                                    !_saving &&
                                        !_sending &&
                                        _seconds == 0 &&
                                        _validPhone(_phone.text)
                                    ? _sendCode
                                    : null,
                                child: Text(
                                  _sending
                                      ? '发送中…'
                                      : _seconds > 0
                                      ? '${_seconds}s 后重发'
                                      : '发送验证码',
                                  style: const TextStyle(fontSize: 12),
                                ),
                              ),
                            ),
                      ),
                    ]),
                    const SizedBox(height: 16),
                    MePrimaryButton(
                      label: '确认重置',
                      onPressed: _valid && !_sending && !_saving ? _save : null,
                      loading: _saving && !_reset,
                    ),
                  ],
                ),
              ),
            ],
          ),
          if (_toast != null)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: MeSuccessToast(message: _toast!),
            ),
        ],
      ),
    ),
  );

  String get _maskedPhone {
    final phone = _phone.text.trim().replaceFirst(RegExp(r'^\+86'), '');
    return '+86 ${phone.substring(0, 3)}****${phone.substring(7)}';
  }

  Widget _panel(List<Widget> children) => Container(
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(
      color: const Color(0xAFFFFFFF),
      borderRadius: BorderRadius.circular(20),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: children,
    ),
  );

  Widget _label(String text) => Padding(
    padding: const EdgeInsets.only(left: 4, bottom: 8),
    child: Text(text, style: const TextStyle(fontSize: 14, color: meText)),
  );

  InputDecoration _decoration(String hint, IconData icon) => InputDecoration(
    hintText: hint,
    hintStyle: const TextStyle(color: Color(0xFFB7BBC3), fontSize: 14),
    filled: true,
    fillColor: Colors.white,
    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
    prefixIcon: Icon(icon, size: 19, color: const Color(0xFF8D969C)),
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(14),
      borderSide: BorderSide.none,
    ),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(14),
      borderSide: BorderSide.none,
    ),
  );
}

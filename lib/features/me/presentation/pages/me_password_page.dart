import 'package:flutter/material.dart';

import '../../../../core/network/api_exception.dart';
import '../../../../shared/widgets/module_top_bar.dart';
import '../../../auth/data/password_rules.dart';
import '../../../auth/data/auth_error_message.dart';
import '../../../auth/presentation/widgets/password_field.dart';
import '../../../auth/presentation/widgets/password_requirements.dart';
import '../../data/me_repository.dart';
import '../widgets/me_common_widgets.dart';
import 'me_session_scope.dart';
import 'me_reset_password_page.dart';

class MePasswordPage extends StatefulWidget {
  const MePasswordPage({
    super.key,
    required this.meRepository,
    required this.isSetup,
    required this.phone,
  });
  final MeRepository meRepository;
  final bool isSetup;
  final String phone;

  @override
  State<MePasswordPage> createState() => _MePasswordPageState();
}

class _MePasswordPageState extends State<MePasswordPage> {
  final _oldPassword = TextEditingController();
  final _newPassword = TextEditingController();
  final _confirmation = TextEditingController();
  late final TextEditingController _phone = TextEditingController(
    text: widget.phone,
  );
  bool _saving = false;
  bool _success = false;
  String? _error;

  bool get _phoneValid =>
      RegExp(r'^(\+86)?1[3-9]\d{9}$').hasMatch(_phone.text.trim());
  bool get _valid =>
      PasswordRules(_newPassword.text).isValid &&
      _newPassword.text == _confirmation.text &&
      (widget.isSetup
          ? _phoneValid
          : _oldPassword.text.isNotEmpty &&
                _oldPassword.text != _newPassword.text);

  @override
  void dispose() {
    _oldPassword.dispose();
    _newPassword.dispose();
    _confirmation.dispose();
    _phone.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_valid || _saving) return;
    FocusScope.of(context).unfocus();
    setState(() {
      _saving = true;
      _error = null;
    });
    try {
      if (widget.isSetup) {
        await widget.meRepository.setupPassword(
          phone: _phone.text.trim(),
          password: _newPassword.text,
        );
      } else {
        await widget.meRepository.changePassword(
          oldPassword: _oldPassword.text,
          newPassword: _newPassword.text,
        );
      }
      if (!mounted) return;
      _oldPassword.clear();
      _newPassword.clear();
      _confirmation.clear();
      if (widget.isSetup) {
        setState(() => _success = true);
        await Future<void>.delayed(const Duration(seconds: 2));
        if (mounted) Navigator.of(context).pop(true);
      } else {
        final navigator = Navigator.of(context);
        await MeSessionScope.of(context).passwordChanged();
        if (navigator.mounted) navigator.popUntil((route) => route.isFirst);
      }
    } on ApiException catch (error) {
      if (!mounted) return;
      setState(
        () => _error = !widget.isSetup && error.statusCode == 401
            ? '当前密码错误或登录已过期，请检查后重试'
            : authErrorMessage(error),
      );
    } catch (_) {
      if (mounted) setState(() => _error = '操作失败，请检查网络后重试');
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) => PopScope(
    canPop: !_saving,
    child: MeGradientScaffold(
      child: Stack(
        children: [
          Column(
            children: [
              ModuleTopBar(
                title: widget.isSetup ? '设置密码' : '修改密码',
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
                    14,
                    16,
                    24 + MediaQuery.paddingOf(context).bottom,
                  ),
                  children: [
                    Container(
                      padding: const EdgeInsets.fromLTRB(16, 18, 16, 18),
                      decoration: BoxDecoration(
                        color: const Color(0xAFFFFFFF),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (widget.isSetup && widget.phone.isEmpty) ...[
                            _label('确认当前账号手机号'),
                            TextField(
                              controller: _phone,
                              enabled: !_saving,
                              keyboardType: TextInputType.phone,
                              onChanged: (_) => setState(() {}),
                              decoration: const InputDecoration(
                                hintText: '请输入当前账号手机号',
                              ),
                            ),
                            const SizedBox(height: 18),
                          ],
                          if (!widget.isSetup) ...[
                            _label('当前密码'),
                            PasswordField(
                              controller: _oldPassword,
                              hintText: '请输入当前密码',
                              enabled: !_saving,
                              autofillHints: const [AutofillHints.password],
                              onChanged: (_) => setState(() {}),
                            ),
                            const SizedBox(height: 18),
                          ],
                          _label('新密码'),
                          PasswordField(
                            controller: _newPassword,
                            hintText: '请输入新密码',
                            enabled: !_saving,
                            onChanged: (_) => setState(() {}),
                          ),
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 4),
                            child: PasswordRequirements(
                              value: _newPassword.text,
                            ),
                          ),
                          const SizedBox(height: 28),
                          _label('确认新密码'),
                          PasswordField(
                            controller: _confirmation,
                            hintText: '请再次输入新密码',
                            enabled: !_saving,
                            onChanged: (_) => setState(() {}),
                            onSubmitted: (_) => _save(),
                          ),
                          if (_confirmation.text.isNotEmpty &&
                              _confirmation.text != _newPassword.text)
                            const Padding(
                              padding: EdgeInsets.only(top: 8, left: 4),
                              child: Text(
                                '两次输入的密码不一致',
                                style: TextStyle(
                                  color: meSubText,
                                  fontSize: 12,
                                ),
                              ),
                            ),
                          if (!widget.isSetup &&
                              _newPassword.text.isNotEmpty &&
                              _newPassword.text == _oldPassword.text)
                            const Padding(
                              padding: EdgeInsets.only(top: 8),
                              child: Text(
                                '新密码不能与当前密码相同',
                                style: TextStyle(
                                  color: Color(0xFFCF4444),
                                  fontSize: 12,
                                ),
                              ),
                            ),
                          if (_error != null)
                            Padding(
                              padding: const EdgeInsets.only(top: 12),
                              child: Text(
                                _error!,
                                style: const TextStyle(
                                  color: Color(0xFFCF4444),
                                  fontSize: 13,
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                    SizedBox(
                      height: 52,
                      child: FilledButton(
                        onPressed: _valid && !_saving ? _save : null,
                        style: FilledButton.styleFrom(
                          backgroundColor: meTeal,
                          disabledBackgroundColor: meTeal.withValues(
                            alpha: .45,
                          ),
                          disabledForegroundColor: Colors.white70,
                        ),
                        child: _saving
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ),
                              )
                            : const Text(
                                '确认修改',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                      ),
                    ),
                    if (!widget.isSetup)
                      Padding(
                        padding: const EdgeInsets.only(top: 16),
                        child: TextButton(
                          onPressed:
                              _saving ||
                                  MeSessionScope.maybeOf(
                                        context,
                                      )?.authRepository ==
                                      null
                              ? null
                              : () => Navigator.of(context).push<void>(
                                  MaterialPageRoute(
                                    builder: (_) => MeResetPasswordPage(
                                      meRepository: widget.meRepository,
                                      authRepository: MeSessionScope.of(
                                        context,
                                      ).authRepository!,
                                      phone: widget.phone,
                                    ),
                                  ),
                                ),
                          child: const Text(
                            '忘记密码？通过手机验证码重置',
                            style: TextStyle(color: Colors.white, fontSize: 13),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
          if (_success) const MeSuccessToast(message: '密码设置成功'),
        ],
      ),
    ),
  );

  Widget _label(String text) => Padding(
    padding: const EdgeInsets.only(left: 4, bottom: 8),
    child: Text(text, style: const TextStyle(fontSize: 14, color: meText)),
  );
}

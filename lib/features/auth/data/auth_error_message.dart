import 'dart:convert';
import '../../../core/network/api_exception.dart';

String authErrorMessage(ApiException error) {
  var message = error.message;
  try {
    final body = jsonDecode(message);
    if (body is Map && body['error'] is String) {
      message = body['error'] as String;
    }
  } catch (_) {}
  if (message.contains('password is locked')) {
    return '密码登录已锁定，请在 15 分钟后重试，或使用验证码登录';
  }
  if (message.contains('phone or password is invalid')) {
    return '手机号或密码错误，连续输错 5 次将锁定 15 分钟';
  }
  if (message.contains('password already setup')) return '当前账号已设置密码，请返回修改密码';
  if (message.contains('password is invalid')) return '当前密码错误，请重新输入';
  if (error.statusCode == 429) return '操作过于频繁，请稍后重试';
  if (error.statusCode == 403) return '当前账号无法执行此操作，请确认账号状态';
  if (error.statusCode == 401) return '登录凭据无效或已过期，请重新登录';
  if ((error.statusCode ?? 0) >= 500) return '服务暂时不可用，请稍后重试';
  return message;
}

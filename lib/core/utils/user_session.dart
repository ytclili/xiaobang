import 'dart:convert';

class UserSession {
  static String? _userId;
  static String? _nickname;
  static String? _username;
  static String? _phone;

  static String? get userId => _userId;
  static String? get nickname => _nickname;
  static String? get username => _username;
  static String? get phone => _phone;
  static String? get displayName => _resolveDisplayName();

  static void setUserId(String? userId) {
    final trimmed = userId?.trim();
    if (trimmed == null || trimmed.isEmpty) {
      _userId = null;
      return;
    }
    _userId = trimmed;
  }

  static void updateFromLoginPayload(Map<String, dynamic> payload) {
    final direct = _extractUserId(payload);
    if (direct != null) {
      setUserId(direct);
    }
    final userInfo = payload['userInfo'];
    final nested = _extractUserId(userInfo);
    if (nested != null) {
      setUserId(nested);
    }
    _applyUserInfo(payload);
    if (userInfo is Map<String, dynamic>) {
      _applyUserInfo(userInfo);
    }
  }

  static void restoreFromUserInfoJson(String? raw) {
    if (raw == null || raw.trim().isEmpty) return;
    try {
      final decoded = jsonDecode(raw);
      final id = _extractUserId(decoded);
      if (id != null) {
        setUserId(id);
      }
      if (decoded is Map<String, dynamic>) {
        _applyUserInfo(decoded);
      }
    } catch (_) {
      // Ignore JSON parse errors.
    }
  }

  static String? _extractUserId(dynamic data) {
    if (data is Map<String, dynamic>) {
      const keys = ['userId', 'user_id', 'id', 'uid'];
      for (final key in keys) {
        final value = data[key];
        if (value == null) continue;
        final text = value.toString().trim();
        if (text.isNotEmpty) {
          return text;
        }
      }
    }
    return null;
  }

  static void _applyUserInfo(Map<String, dynamic> data) {
    final nextNickname = _extractString(data, const ['nickname', 'nickName', 'nick_name']);
    if (nextNickname != null) {
      _nickname = nextNickname;
    }
    final nextUsername = _extractString(data, const ['username', 'userName', 'name']);
    if (nextUsername != null) {
      _username = nextUsername;
    }
    final nextPhone = _extractString(data, const ['phone', 'phoneNumber', 'mobile', 'tel']);
    if (nextPhone != null) {
      _phone = nextPhone;
    }
  }

  static String? _extractString(Map<String, dynamic> data, List<String> keys) {
    for (final key in keys) {
      final value = data[key];
      if (value == null) continue;
      final text = value.toString().trim();
      if (text.isNotEmpty) {
        return text;
      }
    }
    return null;
  }

  static String? _resolveDisplayName() {
    final name = _nickname?.trim();
    if (name != null && name.isNotEmpty) return name;
    final user = _username?.trim();
    if (user != null && user.isNotEmpty) return user;
    final digits = _phone?.replaceAll(RegExp(r'\D'), '') ?? '';
    if (digits.length >= 4) {
      return digits.substring(digits.length - 4);
    }
    final fallback = _phone?.trim();
    if (fallback != null && fallback.isNotEmpty) return fallback;
    return null;
  }
}

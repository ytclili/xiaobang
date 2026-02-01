import 'dart:convert';

class UserSession {
  static String? _userId;

  static String? get userId => _userId;

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
      return;
    }
    final userInfo = payload['userInfo'];
    final nested = _extractUserId(userInfo);
    if (nested != null) {
      setUserId(nested);
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
}

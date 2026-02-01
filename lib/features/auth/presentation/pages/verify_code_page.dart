import 'dart:async';
import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:xiaobang/core/network/api_client.dart';
import 'package:xiaobang/core/theme/app_theme.dart';
import 'package:xiaobang/core/utils/user_session.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:xiaobang/features/chat/presentation/pages/chat_page.dart';

class VerifyCodePage extends StatefulWidget {
  const VerifyCodePage({super.key, required this.phoneNumber});

  final String phoneNumber;

  @override
  State<VerifyCodePage> createState() => _VerifyCodePageState();
}

class _VerifyCodePageState extends State<VerifyCodePage> {
  static const int _codeLength = 6;
  final List<TextEditingController> _controllers =
      List.generate(_codeLength, (_) => TextEditingController());
  final List<FocusNode> _focusNodes =
      List.generate(_codeLength, (_) => FocusNode());
  Timer? _resendTimer;
  int _resendSeconds = 60;
  bool _isVerifying = false;

  @override
  void initState() {
    super.initState();
    _startResendTimer();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        FocusScope.of(context).requestFocus(_focusNodes.first);
      }
    });
  }

  @override
  void dispose() {
    for (final controller in _controllers) {
      controller.dispose();
    }
    for (final node in _focusNodes) {
      node.dispose();
    }
    _resendTimer?.cancel();
    super.dispose();
  }

  void _startResendTimer() {
    _resendTimer?.cancel();
    setState(() {
      _resendSeconds = 60;
    });
    _resendTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) return;
      if (_resendSeconds <= 1) {
        timer.cancel();
        setState(() {
          _resendSeconds = 0;
        });
        return;
      }
      setState(() {
        _resendSeconds -= 1;
      });
    });
  }

  void _handleResend() {
    if (_resendSeconds > 0) return;
    _startResendTimer();
  }

  Future<void> _tryVerifyCode() async {
    if (_isVerifying) return;
    final code = _controllers.map((c) => c.text).join();
    if (code.length != _codeLength) return;
    setState(() {
      _isVerifying = true;
    });
    FocusScope.of(context).unfocus();
    try {
      final response = await ApiClient.instance.post(
        'https://api.aibmc.cn/api/users/login/h5',
        data: {
          'phone': widget.phoneNumber,
          'code': code,
        },
        options: Options(contentType: Headers.formUrlEncodedContentType),
      );
      debugPrint('users/login/h5 response: ${response.data}');

      final json = _normalizeResponse(response.data);
      if (json == null) {
        _showError('登录失败，请稍后重试');
        return;
      }
      if (json['code'] != 200) {
        final message = json['message']?.toString() ?? '登录失败';
        _showError(message);
        return;
      }

      final data = json['data'];
      if (data is Map<String, dynamic>) {
        await _persistAuth(data);
      }
      if (!mounted) return;
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const ChatPage()),
        (route) => false,
      );
    } on DioException catch (error, stackTrace) {
      debugPrint('users/login/h5 error: $error');
      debugPrint('$stackTrace');
      _showError('网络异常，请稍后重试');
    } catch (error, stackTrace) {
      debugPrint('users/login/h5 error: $error');
      debugPrint('$stackTrace');
      _showError('登录失败，请稍后重试');
    } finally {
      if (mounted) {
        setState(() {
          _isVerifying = false;
        });
      }
    }
  }

  Map<String, dynamic>? _normalizeResponse(dynamic payload) {
    if (payload is Map<String, dynamic>) {
      return payload;
    }
    if (payload is String) {
      final decoded = jsonDecode(payload);
      if (decoded is Map<String, dynamic>) {
        return decoded;
      }
    }
    return null;
  }

  Future<void> _persistAuth(Map<String, dynamic> data) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = data['token'];
      if (token is String) {
        await prefs.setString('auth_token', token);
      }
      final isNewUser = data['isNewUser'];
      if (isNewUser is bool) {
        await prefs.setBool('is_new_user', isNewUser);
      }
      final userInfo = data['userInfo'];
      if (userInfo != null) {
        await prefs.setString('user_info', jsonEncode(userInfo));
      }
      UserSession.updateFromLoginPayload(data);
    } catch (error, stackTrace) {
      debugPrint('persist auth error: $error');
      debugPrint('$stackTrace');
    }
  }

  void _showError(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  String _formatPhone(String phone) {
    final digits = phone.replaceAll(RegExp(r'\D'), '');
    if (digits.length < 11) {
      return digits;
    }
    return '${digits.substring(0, 3)} ${digits.substring(3, 7)} ${digits.substring(7, 11)}';
  }

  @override
  Widget build(BuildContext context) {
    final resendText = _resendSeconds > 0
        ? '重新获取(${_resendSeconds}s)'
        : '重新获取';
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: 24.w),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(height: 8.h),
              IconButton(
                icon: Icon(Icons.arrow_back_ios_new, size: 20.sp),
                onPressed: () => Navigator.of(context).maybePop(),
              ),
              SizedBox(height: 28.h),
              Text(
                '输入验证码',
                style: TextStyle(
                  color: XiaobangColors.textMain,
                  fontSize: 28.sp,
                  fontWeight: FontWeight.w700,
                ),
              ),
              SizedBox(height: 8.h),
              Text(
                '验证码已发送至 +86 ${_formatPhone(widget.phoneNumber)}',
                style: TextStyle(
                  color: XiaobangColors.textSecondary,
                  fontSize: 14.sp,
                ),
              ),
              SizedBox(height: 32.h),
              LayoutBuilder(
                builder: (context, constraints) {
                  final spacing = 12.w;
                  final totalSpacing = spacing * (_codeLength - 1);
                  final boxSize = ((constraints.maxWidth - totalSpacing) / _codeLength)
                      .clamp(44.w, 64.w);
                  return Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: List.generate(_codeLength, (index) {
                      return _buildCodeBox(index, boxSize);
                    }),
                  );
                },
              ),
              SizedBox(height: 16.h),
              TextButton(
                onPressed: _resendSeconds > 0 ? null : _handleResend,
                style: TextButton.styleFrom(
                  foregroundColor: XiaobangColors.textSecondary,
                  padding: EdgeInsets.zero,
                ),
                child: Text(
                  resendText,
                  style: TextStyle(
                    fontSize: 14.sp,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCodeBox(int index, double boxSize) {
    return Container(
      width: boxSize,
      height: boxSize,
      decoration: BoxDecoration(
        color: const Color(0xFFF4F4F4),
        borderRadius: BorderRadius.circular(14.r),
      ),
      alignment: Alignment.center,
      child: TextField(
        controller: _controllers[index],
        focusNode: _focusNodes[index],
        keyboardType: TextInputType.number,
        textAlign: TextAlign.center,
        style: TextStyle(
          fontSize: 22.sp,
          fontWeight: FontWeight.w600,
          color: XiaobangColors.textMain,
        ),
        inputFormatters: [
          FilteringTextInputFormatter.digitsOnly,
          LengthLimitingTextInputFormatter(1),
        ],
        decoration: const InputDecoration(
          border: InputBorder.none,
          counterText: '',
        ),
        onChanged: (value) {
          if (value.isNotEmpty) {
            if (index < _codeLength - 1) {
              _focusNodes[index + 1].requestFocus();
            } else {
              _focusNodes[index].unfocus();
            }
            _tryVerifyCode();
          } else if (index > 0) {
            _focusNodes[index - 1].requestFocus();
          }
        },
      ),
    );
  }
}

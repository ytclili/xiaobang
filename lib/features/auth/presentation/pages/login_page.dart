import 'dart:async';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:xiaobang/core/theme/app_theme.dart';
import 'package:xiaobang/core/network/api_client.dart';
import 'package:xiaobang/features/auth/presentation/pages/verify_code_page.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> with SingleTickerProviderStateMixin {
  final TextEditingController _phoneController = TextEditingController();
  bool _agreed = false;
  Timer? _cooldownTimer;
  int _cooldownSeconds = 0;
  bool _isSending = false;
  bool _isToastVisible = false;
  late final AnimationController _agreementController;
  late final Animation<double> _agreementOffset;

  @override
  void initState() {
    super.initState();
    _phoneController.addListener(_handlePhoneChanged);
    _agreementController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 420),
    );
    _agreementOffset = TweenSequence<double>([
      TweenSequenceItem(tween: Tween(begin: 0, end: -8), weight: 1),
      TweenSequenceItem(tween: Tween(begin: -8, end: 8), weight: 2),
      TweenSequenceItem(tween: Tween(begin: 8, end: -6), weight: 2),
      TweenSequenceItem(tween: Tween(begin: -6, end: 6), weight: 2),
      TweenSequenceItem(tween: Tween(begin: 6, end: 0), weight: 1),
    ]).animate(CurvedAnimation(
      parent: _agreementController,
      curve: Curves.easeInOut,
    ));
  }

  @override
  void dispose() {
    _phoneController.removeListener(_handlePhoneChanged);
    _phoneController.dispose();
    _cooldownTimer?.cancel();
    _agreementController.dispose();
    super.dispose();
  }

  void _handlePhoneChanged() {
    setState(() {});
  }

  bool get _isPhoneValid {
    final input = _phoneController.text.replaceAll(' ', '');
    return RegExp(r'^1\d{10}$').hasMatch(input);
  }

  bool get _canSendCode =>
      _isPhoneValid && _agreed && _cooldownSeconds == 0 && !_isSending;

  void _startCooldown() {
    _cooldownTimer?.cancel();
    setState(() {
      _cooldownSeconds = 60;
    });
    _cooldownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) return;
      if (_cooldownSeconds <= 1) {
        timer.cancel();
        setState(() {
          _cooldownSeconds = 0;
        });
        return;
      }
      setState(() {
        _cooldownSeconds -= 1;
      });
    });
  }

  Future<void> _handleSendCode() async {
    FocusScope.of(context).unfocus();
    if (!_canSendCode) {
      return;
    }
    final phone = _phoneController.text.replaceAll(' ', '');
    setState(() {
      _isSending = true;
    });
    try {
      final response = await ApiClient.instance.post(
        'https://api.aibmc.cn/api/sms/send',
        data: {'phoneNumber': phone},
        options: Options(contentType: Headers.formUrlEncodedContentType),
      );
      debugPrint('sms/send response: ${response.data}');
      if (!mounted) return;
      _startCooldown();
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => VerifyCodePage(phoneNumber: phone),
        ),
      );
    } catch (error, stackTrace) {
      debugPrint('sms/send error: $error');
      debugPrint('$stackTrace');
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('验证码发送失败，请稍后重试'),
          behavior: SnackBarBehavior.floating,
          duration: Duration(seconds: 2),
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isSending = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final hasPhone = _phoneController.text.isNotEmpty;
    final isKeyboardOpen = MediaQuery.of(context).viewInsets.bottom > 0;
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: GestureDetector(
          onTap: () => FocusScope.of(context).unfocus(),
          child: LayoutBuilder(
            builder: (context, constraints) {
              return SingleChildScrollView(
                padding: EdgeInsets.symmetric(horizontal: 24.w),
                child: ConstrainedBox(
                  constraints: BoxConstraints(minHeight: constraints.maxHeight),
                  child: IntrinsicHeight(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        SizedBox(height: 8.h),
                        _buildCloseButton(),
                        SizedBox(height: 32.h),
                        Text(
                          '欢迎登录小帮',
                          style: TextStyle(
                            color: XiaobangColors.textMain,
                            fontSize: 28.sp,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        SizedBox(height: 28.h),
                        _buildPhoneInput(hasPhone),
                        SizedBox(height: 12.h),
                        Text(
                          '未注册的手机号验证后自动创建新车帮买账号',
                          style: TextStyle(
                            color: XiaobangColors.textSecondary,
                            fontSize: 13.sp,
                          ),
                        ),
                        SizedBox(height: 28.h),
                        AnimatedBuilder(
                          animation: _agreementOffset,
                          builder: (context, child) {
                            return Transform.translate(
                              offset: Offset(_agreementOffset.value, 0),
                              child: child,
                            );
                          },
                          child: _buildAgreementRow(),
                        ),
                        SizedBox(height: 20.h),
                        _buildSmsButton(),
                        SizedBox(height: 16.h),
                        if (!isKeyboardOpen) ...[
                          const Spacer(),
                          _buildSocialIcons(),
                          SizedBox(height: 24.h),
                        ] else ...[
                          SizedBox(height: 12.h),
                        ],
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildCloseButton() {
    return Container(
      width: 40.w,
      height: 40.w,
      decoration: const BoxDecoration(
        color: Color(0xFFF2F2F2),
        shape: BoxShape.circle,
      ),
      child: IconButton(
        icon: Icon(Icons.close, size: 20.sp, color: XiaobangColors.textMain),
        onPressed: () => Navigator.of(context).maybePop(),
        padding: EdgeInsets.zero,
        splashRadius: 20.w,
      ),
    );
  }

  Widget _buildPhoneInput(bool hasPhone) {
    return Container(
      height: 56.h,
      padding: EdgeInsets.symmetric(horizontal: 16.w),
      decoration: BoxDecoration(
        color: const Color(0xFFF5F5F5),
        borderRadius: BorderRadius.circular(28.r),
      ),
      child: Row(
        children: [
          Row(
            children: [
              Text(
                '+86',
                style: TextStyle(
                  color: XiaobangColors.textMain,
                  fontSize: 16.sp,
                  fontWeight: FontWeight.w600,
                ),
              ),
              Icon(
                Icons.keyboard_arrow_down,
                color: XiaobangColors.textSecondary,
                size: 18.sp,
              ),
            ],
          ),
          SizedBox(width: 12.w),
          Container(
            width: 1,
            height: 22.h,
            color: const Color(0xFFE0E0E0),
          ),
          SizedBox(width: 12.w),
          Expanded(
            child: TextField(
              controller: _phoneController,
              keyboardType: TextInputType.phone,
              style: TextStyle(
                color: XiaobangColors.textMain,
                fontSize: 20.sp,
                fontWeight: FontWeight.w600,
              ),
              decoration: InputDecoration(
                border: InputBorder.none,
                hintText: '请输入手机号',
                hintStyle: TextStyle(
                  color: XiaobangColors.textSecondary,
                  fontSize: 16.sp,
                  fontWeight: FontWeight.w400,
                ),
              ),
            ),
          ),
          if (hasPhone)
            IconButton(
              onPressed: () => _phoneController.clear(),
              icon: Icon(
                Icons.cancel,
                color: XiaobangColors.textSecondary,
                size: 18.sp,
              ),
              splashRadius: 16.w,
            ),
        ],
      ),
    );
  }

  Widget _buildAgreementRow() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 20.w,
          height: 20.w,
          child: Checkbox(
            value: _agreed,
            onChanged: (value) {
              setState(() {
                _agreed = value ?? false;
              });
            },
            activeColor: XiaobangColors.textMain,
            checkColor: Colors.white,
            shape: const CircleBorder(),
            materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
          ),
        ),
        SizedBox(width: 10.w),
        Expanded(
          child: Text(
            '我已阅读并同意《小帮用户协议》和《隐私政策》，并授权小帮使用新车帮买账号信息（如订单信息）',
            style: TextStyle(
              color: XiaobangColors.textMain,
              fontSize: 13.sp,
              height: 1.4,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSmsButton() {
    final buttonText = _isSending
        ? '发送中...'
        : _cooldownSeconds > 0
            ? '已发送(${_cooldownSeconds}s)'
            : '获取短信验证码';
    final canSend = _canSendCode;
    final button = SizedBox(
      width: double.infinity,
      height: 54.h,
      child: ElevatedButton(
        onPressed: canSend ? _handleSendCode : null,
        style: ElevatedButton.styleFrom(
          backgroundColor: XiaobangColors.textMain,
          foregroundColor: Colors.white,
          disabledBackgroundColor: const Color(0xFFBDBDBD),
          disabledForegroundColor: Colors.white70,
          elevation: 0,
          shape: const StadiumBorder(),
        ),
        child: Text(
          buttonText,
          style: TextStyle(
            fontSize: 17.sp,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: !canSend && !_agreed
          ? () => _agreementController.forward(from: 0)
          : null,
      child: AbsorbPointer(
        absorbing: !canSend,
        child: button,
      ),
    );
  }

  Widget _buildSocialIcons() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        _buildSocialItem(
          icon: FontAwesomeIcons.weixin,
          backgroundColor: const Color(0xFF07C160),
          onTap: _showComingSoon,
        ),
        SizedBox(width: 20.w),
        _buildSocialItem(
          icon: FontAwesomeIcons.alipay,
          backgroundColor: const Color(0xFF1677FF),
          onTap: _showComingSoon,
        ),
        SizedBox(width: 20.w),
        _buildSocialItem(
          icon: FontAwesomeIcons.tiktok,
          backgroundColor: const Color(0xFF1A1A1A),
          onTap: _showComingSoon,
        ),
      ],
    );
  }

  void _showComingSoon() {
    if (_isToastVisible || !mounted) return;
    _isToastVisible = true;
    showGeneralDialog<void>(
      context: context,
      barrierDismissible: false,
      barrierLabel: 'coming-soon',
      barrierColor: Colors.transparent,
      transitionDuration: const Duration(milliseconds: 160),
      pageBuilder: (context, _, __) {
        return SafeArea(
          child: Center(
            child: Material(
              color: Colors.transparent,
              child: Container(
                padding: EdgeInsets.symmetric(horizontal: 24.w, vertical: 12.h),
                decoration: BoxDecoration(
                  color: const Color(0xCC000000),
                  borderRadius: BorderRadius.circular(24.r),
                ),
                child: Text(
                  '功能待开放',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 14.sp,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ),
          ),
        );
      },
      transitionBuilder: (context, animation, _, child) {
        return FadeTransition(
          opacity: animation,
          child: ScaleTransition(
            scale: Tween<double>(begin: 0.98, end: 1.0).animate(animation),
            child: child,
          ),
        );
      },
      useRootNavigator: true,
    ).whenComplete(() {
      _isToastVisible = false;
    });

    Future.delayed(const Duration(seconds: 2), () {
      if (!_isToastVisible || !mounted) return;
      Navigator.of(context, rootNavigator: true).pop();
    });
  }

  Widget _buildSocialItem({
    required IconData icon,
    required Color backgroundColor,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        customBorder: const CircleBorder(),
        child: Ink(
          width: 48.w,
          height: 48.w,
          decoration: BoxDecoration(
            color: backgroundColor,
            shape: BoxShape.circle,
          ),
          child: Center(
            child: FaIcon(
              icon,
              color: Colors.white,
              size: 22.sp,
            ),
          ),
        ),
      ),
    );
  }
}

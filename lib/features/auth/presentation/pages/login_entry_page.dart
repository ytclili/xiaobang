import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:xiaobang/core/theme/app_theme.dart';
import 'package:xiaobang/features/auth/presentation/pages/login_page.dart';

class LoginEntryPage extends StatefulWidget {
  const LoginEntryPage({super.key});

  @override
  State<LoginEntryPage> createState() => _LoginEntryPageState();
}

class _LoginEntryPageState extends State<LoginEntryPage> {
  static const List<String> _headlines = [
    '买新车，就上新车帮买',
    '新车选得准，用车更安心',
    '心动新车，一键帮你搞定',
    '买新车不踩坑，攻略在这',
    '新车挑对了，出行更轻松',
    '预算清晰，选车更聪明',
    '配置不纠结，我们来推荐',
    '省心选车，快乐提车',
    '买新车，先比再下手',
    '想买新车？交给我们',
    '靠谱新车，一眼就懂',
    '新车行情，一看就明白',
    '先试再买，体验更踏实',
    '新车推荐，精准到位',
    '省时省力，轻松选车',
    '好车不贵，推荐给你',
    '新车口碑，帮你把关',
    '新车参数，简单看懂',
    '买新车，先看这几招',
    '高配低价，优选好车',
    '新车搭配，适合才好',
    '有颜有料，新车在这',
    '新车优惠，一手掌握',
    '买新车，别只看价格',
    '新车热榜，一目了然',
    '家用新车，稳稳的幸福',
    '通勤新车，省心又省钱',
    '新车体验，真实不忽悠',
    '新车上手，快乐出发',
    '选新车，从需求开始',
    '新车推荐，懂你所需',
    '空间够大，出行更自在',
    '动力够用，驾感更顺滑',
    '舒适升级，路上更轻松',
    '安全配置，出行更放心',
    '颜值在线，开出去更亮眼',
    '油耗更低，用车更省',
    '配置更全，体验更好',
    '新手买车，也能选得稳',
    '置换新车，轻松又划算',
    '新车交付，流程更清晰',
    '买车攻略，一口气讲清',
    '试驾之后，答案更明朗',
    '优惠福利，别错过',
    '新车方案，量身推荐',
    '综合对比，选车更准',
    '多场景用车，一车搞定',
    '买新车，预算更透明',
    '提车更快，快乐更近',
    '新车趋势，提前掌握',
    '买车不迷路，选择更简单',
  ];
  static const String _headlineSuffix = '...';
  static const Duration _typingInterval = Duration(milliseconds: 120);
  static const Duration _holdDuration = Duration(seconds: 1);
  Timer? _typingTimer;
  Timer? _restartTimer;
  int _typedCount = 0;
  int _currentIndex = 0;

  @override
  void initState() {
    super.initState();
    _startTyping();
  }

  @override
  void dispose() {
    _typingTimer?.cancel();
    _restartTimer?.cancel();
    super.dispose();
  }

  void _startTyping() {
    _typingTimer?.cancel();
    _restartTimer?.cancel();
    _typedCount = 0;
    _typingTimer = Timer.periodic(_typingInterval, (timer) {
      if (!mounted) return;
      final headline = _currentHeadline;
      if (_typedCount >= headline.length) {
        timer.cancel();
        _restartTimer = Timer(_holdDuration, () {
          if (!mounted) return;
          setState(() {
            _typedCount = 0;
            _currentIndex = (_currentIndex + 1) % _headlines.length;
          });
          _startTyping();
        });
        return;
      }
      setState(() {
        _typedCount += 1;
      });
    });
  }

  String get _currentHeadline => '${_headlines[_currentIndex]}$_headlineSuffix';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: 32.w),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(height: 48.h),
              Center(
                child: Image.asset(
                  'assets/images/avatar.png',
                  width: 160.w,
                  height: 160.w,
                  fit: BoxFit.contain,
                ),
              ),
              SizedBox(height: 36.h),
              Text(
                _currentHeadline.substring(0, _typedCount),
                style: TextStyle(
                  color: XiaobangColors.textMain,
                  fontSize: 22.sp,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const Spacer(),
              SizedBox(
                width: double.infinity,
                height: 54.h,
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(builder: (_) => const LoginPage()),
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: XiaobangColors.textMain,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shape: const StadiumBorder(),
                  ),
                  child: Text(
                    '登录',
                    style: TextStyle(
                      fontSize: 18.sp,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
              SizedBox(height: 32.h),
            ],
          ),
        ),
      ),
    );
  }
}

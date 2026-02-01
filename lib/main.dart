import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:xiaobang/core/theme/app_theme.dart';
import 'package:xiaobang/core/utils/user_session.dart';
import 'package:xiaobang/features/auth/presentation/pages/login_entry_page.dart';
import 'package:xiaobang/features/chat/presentation/pages/chat_page.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const XiaobangApp());
}

class XiaobangApp extends StatelessWidget {
  const XiaobangApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ScreenUtilInit(
      designSize: const Size(375, 812),
      minTextAdapt: true,
      splitScreenMode: true,
      builder: (context, child) {
        return MaterialApp(
          title: '小帮',
          debugShowCheckedModeBanner: false,
          theme: XiaobangTheme.light,
          home: const _AppBootstrap(),
        );
      },
    );
  }
}

class _AppBootstrap extends StatefulWidget {
  const _AppBootstrap();

  @override
  State<_AppBootstrap> createState() => _AppBootstrapState();
}

class _AppBootstrapState extends State<_AppBootstrap> {
  bool _isReady = false;
  bool _hasToken = false;

  @override
  void initState() {
    super.initState();
    _loadSession();
  }

  Future<void> _loadSession() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('auth_token');
      final userInfo = prefs.getString('user_info');
      UserSession.restoreFromUserInfoJson(userInfo);
      if (!mounted) return;
      setState(() {
        _isReady = true;
        _hasToken = token != null && token.isNotEmpty;
      });
    } catch (error, stackTrace) {
      debugPrint('load session error: $error');
      debugPrint('$stackTrace');
      if (!mounted) return;
      setState(() {
        _isReady = true;
        _hasToken = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!_isReady) {
      return const Scaffold(
        backgroundColor: Colors.white,
        body: SizedBox.shrink(),
      );
    }
    return _hasToken ? const ChatPage() : const LoginEntryPage();
  }
}

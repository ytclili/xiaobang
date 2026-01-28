import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:xiaobang/core/theme/app_theme.dart';
import 'package:xiaobang/features/chat/presentation/pages/chat_page.dart';

void main() {
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
          home: const ChatPage(),
        );
      },
    );
  }
}

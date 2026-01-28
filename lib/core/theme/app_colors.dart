import 'package:flutter/material.dart';

class XiaobangColors {
  // 小帮主色调 (美团绿风格)
  static const Color primary = Color(0xFF00D280);
  
  // 背景颜色
  static const Color background = Color(0xFFF7F8FA);
  
  // 文字颜色
  static const Color textMain = Color(0xFF222222);
  static const Color textSecondary = Color(0xFF999999);
  
  // 卡片与气泡颜色
  static const Color cardWhite = Colors.white;
  static const Color bubbleUser = Color(0xFFC7F5E1);
  static const Color divider = Color(0xFFEEEEEE);
  
  // 输入框背景
  static const Color inputBg = Color(0xFFF5F5F5);
}

class XiaobangTheme {
  static ThemeData get light => ThemeData(
    primaryColor: XiaobangColors.primary,
    scaffoldBackgroundColor: XiaobangColors.background,
    useMaterial3: true,
    colorScheme: ColorScheme.fromSeed(seedColor: XiaobangColors.primary),
  );
}
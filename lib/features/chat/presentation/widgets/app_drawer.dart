import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:xiaobang/core/theme/app_theme.dart';

class AppDrawer extends StatelessWidget {
  const AppDrawer({super.key});

  @override
  Widget build(BuildContext context) {
    return Drawer(
      backgroundColor: XiaobangColors.background,
      child: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 用户信息区域
            SizedBox(
              width: double.infinity,
              child: Stack(
                children: [
                  Padding(
                    padding: EdgeInsets.all(24.w),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // 用户头像
                        Container(
                          width: 70.w,
                          height: 70.w,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(color: XiaobangColors.primary, width: 2),
                            image: const DecorationImage(
                              image: AssetImage('assets/images/avatar.png'),
                              fit: BoxFit.cover,
                            ),
                          ),
                        ),
                        SizedBox(height: 16.h),
                        Text(
                          'Hi，用户',
                          style: TextStyle(
                            fontSize: 20.sp,
                            fontWeight: FontWeight.bold,
                            color: XiaobangColors.textMain,
                          ),
                        ),
                        SizedBox(height: 4.h),
                        Text(
                          '小帮今天也在努力工作～',
                          style: TextStyle(
                            fontSize: 14.sp,
                            color: XiaobangColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Positioned(
                    top: 16.h,
                    right: 16.w,
                    child: IconButton(
                      onPressed: () {},
                      icon: const Icon(
                        Icons.settings_outlined,
                        color: XiaobangColors.textMain,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Divider(color: XiaobangColors.divider, height: 1),
            SizedBox(height: 8.h),

            // 菜单项
            _buildConversationItem(
              title: '\u4f1a\u8bdd1',
              onTap: () {},
            ),
            _buildConversationItem(
              title: '\u4f1a\u8bdd2',
              onTap: () {},
            ),

            const Spacer(),

            // 底部版本信息
            Padding(
              padding: EdgeInsets.all(24.w),
              child: Text(
                'Xiaobang v1.0.0',
                style: TextStyle(
                  fontSize: 12.sp,
                  color: XiaobangColors.textSecondary,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildConversationItem({
    required String title,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: 24.w, vertical: 16.h),
          child: Text(
            title,
            style: TextStyle(
              fontSize: 16.sp,
              color: XiaobangColors.textMain,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildMenuItem({
    required IconData icon,
    required String title,
    int? badge,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: 24.w, vertical: 16.h),
          child: Row(
            children: [
              Icon(icon, color: XiaobangColors.textMain, size: 24),
              SizedBox(width: 16.w),
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(
                    fontSize: 16.sp,
                    color: XiaobangColors.textMain,
                  ),
                ),
              ),
              if (badge != null)
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 2.h),
                  decoration: BoxDecoration(
                    color: XiaobangColors.primary,
                    borderRadius: BorderRadius.circular(10.r),
                  ),
                  child: Text(
                    badge.toString(),
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 12.sp,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

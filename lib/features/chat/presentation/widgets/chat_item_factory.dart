import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:xiaobang/core/theme/app_theme.dart';
import 'package:xiaobang/features/chat/domain/entities/message.dart';

class ChatItemFactory {
  static Widget build(MessageEntity message) {
    switch (message.type) {
      case MessageType.header:
        return _buildHeader(message.content);
      case MessageType.quickAction:
        return _buildQuickAction(message);
      case MessageType.todo:
        return _buildTodoCard(message);
      case MessageType.richText:
        return _buildRichText(message.content);
      case MessageType.text:
      default:
        return _buildTextBubble(message);
    }
  }

  static Widget _buildHeader(String greeting) {
    return Container(
      margin: EdgeInsets.symmetric(vertical: 24.h),
      child: Column(
        children: [
          // AI 头像 - 使用图片
          Container(
            width: 70.w,
            height: 70.w,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: XiaobangColors.primary, width: 3),
              image: const DecorationImage(
                image: AssetImage('assets/images/avatar.png'),
                fit: BoxFit.cover,
              ),
            ),
          ),
          SizedBox(height: 16.h),
          Text(
            '"$greeting"',
            style: TextStyle(
              fontSize: 20.sp,
              fontWeight: FontWeight.bold,
              color: XiaobangColors.textMain,
            ),
          ),
        ],
      ),
    );
  }

  static Widget _buildQuickAction(MessageEntity msg) {
    return Container(
      margin: EdgeInsets.only(bottom: 12.h),
      child: Align(
        alignment: Alignment.centerLeft,
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: () {
              // TODO: 处理快速操作点击
              debugPrint('Quick action tapped: ${msg.content}');
            },
            borderRadius: BorderRadius.circular(20.r),
            child: Ink(
              decoration: BoxDecoration(
                color: XiaobangColors.cardWhite,
                borderRadius: BorderRadius.circular(20.r),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Container(
                constraints: BoxConstraints(maxWidth: 320.w),
                padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 10.h),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Flexible(
                      child: Text(
                        msg.content,
                        style: TextStyle(
                          fontSize: 15.sp,
                          color: XiaobangColors.textMain,
                          height: 1.3,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  static Widget _buildTodoCard(MessageEntity msg) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () {
          // TODO: 处理待办卡片点击
          debugPrint('Todo card tapped: ${msg.content}');
        },
        borderRadius: BorderRadius.circular(16.r),
        child: Ink(
          decoration: BoxDecoration(
            color: XiaobangColors.cardWhite,
            borderRadius: BorderRadius.circular(16.r),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 10,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Container(
            margin: EdgeInsets.symmetric(vertical: 8.h),
            padding: EdgeInsets.all(20.w),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(
                      Icons.chat_bubble_outline,
                      color: XiaobangColors.primary,
                      size: 18,
                    ),
                    SizedBox(width: 8.w),
                    Text(
                      msg.extra?['tag'] ?? "动态",
                      style: TextStyle(
                        color: XiaobangColors.textSecondary,
                        fontSize: 13.sp,
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 14.h),
                Text(
                  msg.content,
                  style: TextStyle(
                    fontSize: 17.sp,
                    fontWeight: FontWeight.bold,
                    color: XiaobangColors.textMain,
                  ),
                ),
                SizedBox(height: 8.h),
                Text(
                  msg.extra?['date'] ?? "",
                  style: TextStyle(
                    color: XiaobangColors.textSecondary,
                    fontSize: 13.sp,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  static Widget _buildRichText(String content) {
    return Container(
      width: double.infinity,
      margin: EdgeInsets.symmetric(vertical: 8.h),
      padding: EdgeInsets.all(18.w),
      decoration: BoxDecoration(
        color: XiaobangColors.cardWhite,
        borderRadius: BorderRadius.circular(16.r),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Text(
        content,
        style: TextStyle(
          fontSize: 15.sp,
          height: 1.6,
          color: XiaobangColors.textMain,
        ),
      ),
    );
  }

  static Widget _buildTextBubble(MessageEntity msg) {
    return Align(
      alignment: msg.isFromUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: EdgeInsets.only(
          bottom: 12.h,
          left: msg.isFromUser ? 60.w : 0,
          right: msg.isFromUser ? 0 : 60.w,
        ),
        padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
        decoration: BoxDecoration(
          color: msg.isFromUser ? XiaobangColors.bubbleUser : XiaobangColors.cardWhite,
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(16.r),
            topRight: Radius.circular(16.r),
            bottomLeft: Radius.circular(msg.isFromUser ? 16.r : 4.r),
            bottomRight: Radius.circular(msg.isFromUser ? 4.r : 16.r),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Text(
          msg.content,
          style: TextStyle(
            fontSize: 15.sp,
            color: XiaobangColors.textMain,
          ),
        ),
      ),
    );
  }
}

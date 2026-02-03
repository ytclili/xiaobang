import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:loading_animation_widget/loading_animation_widget.dart';
import 'package:shimmer/shimmer.dart';
import 'package:xiaobang/core/theme/app_theme.dart';
import 'package:xiaobang/features/chat/domain/entities/message.dart';

class ChatItemFactory {
  static Widget build(
    MessageEntity message, {
    void Function(String message)? onQuickActionTap,
    void Function(Map<String, dynamic> item)? onSubsidyTap,
  }) {
    switch (message.type) {
      case MessageType.header:
        return _buildHeader(message.content);
      case MessageType.quickAction:
        return _buildQuickAction(message, onQuickActionTap);
      case MessageType.todo:
        return _buildTodoCard(message);
      case MessageType.richText:
        return _buildRichText(message.content);
      case MessageType.component:
        return _buildComponentCard(message, onSubsidyTap: onSubsidyTap);
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

  static Widget _buildQuickAction(
    MessageEntity msg,
    void Function(String message)? onQuickActionTap,
  ) {
    if (msg.extra?['loading'] == true) {
      return _buildQuickActionSkeleton(msg);
    }
    return Container(
      margin: EdgeInsets.only(bottom: 12.h),
      child: Align(
        alignment: Alignment.centerLeft,
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: () {
              if (onQuickActionTap != null) {
                onQuickActionTap(msg.content);
                return;
              }
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

  static Widget _buildQuickActionSkeleton(MessageEntity msg) {
    final width = (msg.extra?['width'] as num?)?.toDouble() ?? 220;
    const baseColor = Color(0xFFE9EBEF);
    const highlightColor = Color(0xFFF7F8FA);
    return Container(
      margin: EdgeInsets.only(bottom: 12.h),
      child: Align(
        alignment: Alignment.centerLeft,
        child: Shimmer.fromColors(
          baseColor: baseColor,
          highlightColor: highlightColor,
          period: const Duration(milliseconds: 1200),
          child: Container(
            constraints: BoxConstraints(maxWidth: 320.w),
            padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 10.h),
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
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: width.w,
                  height: 14.h,
                  decoration: BoxDecoration(
                    color: baseColor,
                    borderRadius: BorderRadius.circular(8.r),
                  ),
                ),
                SizedBox(width: 8.w),
                Container(
                  width: 24.w,
                  height: 14.h,
                  decoration: BoxDecoration(
                    color: baseColor,
                    borderRadius: BorderRadius.circular(8.r),
                  ),
                ),
              ],
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
    if (!msg.isFromUser && msg.extra?['streaming'] == true && msg.content.isEmpty) {
      final statusText = msg.extra?['statusText'];
      return _buildTypingBubble(
        statusText: statusText is String ? statusText : null,
      );
    }
    return Align(
      alignment: msg.isFromUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: EdgeInsets.only(
          bottom: 12.h,
          left: msg.isFromUser ? 60.w : 0,
          right: msg.isFromUser ? 0 : 20.w,
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

  static Widget _buildTypingBubble({String? statusText}) {
    const dotColor = Color(0xFFBFC5D2);
    const bubbleColor = Color(0xFFF2F3F5);
    final hasStatus = statusText != null && statusText.trim().isNotEmpty;

    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        margin: EdgeInsets.only(bottom: 12.h, right: 60.w),
        padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 10.h),
        decoration: BoxDecoration(
          color: bubbleColor,
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(16.r),
            topRight: Radius.circular(16.r),
            bottomLeft: Radius.circular(4.r),
            bottomRight: Radius.circular(16.r),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: hasStatus
            ? Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  LoadingAnimationWidget.dotsTriangle(
                    color: dotColor,
                    size: 18.w,
                  ),
                  SizedBox(width: 8.w),
                  Flexible(
                    child: Text(
                      statusText!,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 13.sp,
                        color: XiaobangColors.textSecondary,
                        height: 1.3,
                      ),
                    ),
                  ),
                ],
              )
            : LoadingAnimationWidget.dotsTriangle(
                color: dotColor,
                size: 18.w,
              ),
      ),
    );
  }

  static Widget _buildComponentCard(
    MessageEntity msg, {
    void Function(Map<String, dynamic> item)? onSubsidyTap,
  }) {
    final rawItems = msg.extra?['items'];
    final items = rawItems is List
        ? rawItems.whereType<Map>().map((item) => Map<String, dynamic>.from(item)).toList()
        : const <Map<String, dynamic>>[];
    if (items.isEmpty) {
      return const SizedBox.shrink();
    }
    final componentType = msg.extra?['componentType'];
    if (componentType == 'order_list' || componentType == 'claim_result') {
      return _buildOrderListCard(items);
    }
    if (componentType == null || componentType == 'subsidy_card') {
      return _buildSubsidyListCard(items, onSubsidyTap: onSubsidyTap);
    }
    return const SizedBox.shrink();
  }

  static Widget _buildSubsidyListCard(
    List<Map<String, dynamic>> items, {
    void Function(Map<String, dynamic> item)? onSubsidyTap,
  }) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        margin: EdgeInsets.only(bottom: 12.h, right: 20.w),
        padding: EdgeInsets.all(16.w),
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
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            for (var i = 0; i < items.length; i++) ...[
              _buildSubsidyItem(items[i], onSubsidyTap: onSubsidyTap),
              if (i != items.length - 1) SizedBox(height: 12.h),
            ],
          ],
        ),
      ),
    );
  }

  static Widget _buildOrderListCard(List<Map<String, dynamic>> items) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          for (var i = 0; i < items.length; i++) _buildOrderCard(items[i]),
        ],
      ),
    );
  }

  static Widget _buildOrderCard(Map<String, dynamic> item) {
    final skuName = item['skuName']?.toString() ??
        item['name']?.toString() ??
        item['snapshotSkuName']?.toString() ??
        '';
    final imageUrl = item['skuImage']?.toString() ??
        item['imageUrl']?.toString() ??
        item['snapshotSkuImage']?.toString() ??
        item['snapshotSkuImg']?.toString() ??
        item['skuImageUrl']?.toString() ??
        item['image']?.toString();
    final subsidyAmount =
        item['subsidyAmount']?.toString() ?? item['snapshotSubsidyAmount']?.toString() ?? '';
    final statusCode = item['orderStatusText']?.toString() ?? item['orderStatus']?.toString() ?? '';
    final statusText = _mapOrderStatusText(statusCode);
    final orderNo = item['orderNo']?.toString() ?? '';
    final expiryDate = _toDateOnly(item['voucherExpiryDate']?.toString());
    final createdAt = _toDateOnly(item['createdAt']?.toString());
    return Container(
      margin: EdgeInsets.only(bottom: 12.h, right: 20.w),
      constraints: BoxConstraints(maxWidth: 340.w),
      padding: EdgeInsets.all(14.w),
      decoration: BoxDecoration(
        color: XiaobangColors.cardWhite,
        borderRadius: BorderRadius.circular(14.r),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
        border: Border.all(color: XiaobangColors.divider),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildOrderImage(imageUrl),
              SizedBox(width: 12.w),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (skuName.isNotEmpty)
                      Text(
                        skuName,
                        style: TextStyle(
                          fontSize: 15.sp,
                          color: XiaobangColors.textMain,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    if (orderNo.isNotEmpty) ...[
                      SizedBox(height: 4.h),
                      Text(
                        '订单号 $orderNo',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        softWrap: false,
                        style: TextStyle(
                          fontSize: 12.sp,
                          color: XiaobangColors.textSecondary,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              if (statusText.isNotEmpty) _buildStatusChip(statusText, statusCode),
            ],
          ),
          if (subsidyAmount.isNotEmpty || expiryDate.isNotEmpty || createdAt.isNotEmpty) ...[
            SizedBox(height: 10.h),
            if (subsidyAmount.isNotEmpty)
              Text(
                '补贴 ¥$subsidyAmount',
                style: TextStyle(
                  fontSize: 13.sp,
                  color: XiaobangColors.textSecondary,
                ),
              ),
            if (expiryDate.isNotEmpty) ...[
              SizedBox(height: 4.h),
              Text(
                '有效期至 $expiryDate',
                style: TextStyle(
                  fontSize: 12.sp,
                  color: XiaobangColors.textSecondary,
                ),
              ),
            ],
            if (createdAt.isNotEmpty) ...[
              SizedBox(height: 4.h),
              Text(
                '创建时间 $createdAt',
                style: TextStyle(
                  fontSize: 12.sp,
                  color: XiaobangColors.textSecondary,
                ),
              ),
            ],
          ],
        ],
      ),
    );
  }

  static Widget _buildOrderImage(String? url) {
    final size = 56.w;
    if (url == null || url.isEmpty) {
      return Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          color: const Color(0xFFE9EBEF),
          borderRadius: BorderRadius.circular(10.r),
        ),
        child: Icon(
          Icons.image_not_supported_outlined,
          size: 22.w,
          color: XiaobangColors.textSecondary,
        ),
      );
    }
    return ClipRRect(
      borderRadius: BorderRadius.circular(10.r),
      child: Image.network(
        url,
        width: size,
        height: size,
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) {
          return Container(
            width: size,
            height: size,
            decoration: BoxDecoration(
              color: const Color(0xFFE9EBEF),
              borderRadius: BorderRadius.circular(10.r),
            ),
            child: Icon(
              Icons.broken_image_outlined,
              size: 22.w,
              color: XiaobangColors.textSecondary,
            ),
          );
        },
      ),
    );
  }

  static Widget _buildStatusChip(String statusText, String statusCode) {
    final normalized = statusCode.toUpperCase();
    Color background;
    Color foreground;
    if (normalized.contains('IN_VERIFICATION') || normalized.contains('PENDING')) {
      background = const Color(0xFFFFF3E5);
      foreground = const Color(0xFFE07A00);
    } else if (normalized.contains('APPROVED') ||
        normalized.contains('SUCCESS') ||
        normalized.contains('COMPLETED')) {
      background = const Color(0xFFE7F8F0);
      foreground = XiaobangColors.primary;
    } else if (normalized.contains('REJECT') || normalized.contains('FAIL') || normalized.contains('CANCEL')) {
      background = const Color(0xFFFFE9E9);
      foreground = const Color(0xFFE24A4A);
    } else {
      background = const Color(0xFFF2F3F5);
      foreground = XiaobangColors.textSecondary;
    }
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(10.r),
      ),
      child: Text(
        statusText,
        style: TextStyle(
          fontSize: 11.sp,
          color: foreground,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  static String _mapOrderStatusText(String statusCode) {
    switch (statusCode) {
      case 'PENDING_PUSH':
        return '待推送';
      case 'IN_VERIFICATION':
        return '核验中';
      case 'VERIFICATION_FAILED':
        return '核验失败';
      case 'PENDING_PURCHASE':
        return '待购车';
      case 'IN_EXTENSION':
        return '延期中';
      case 'CERTIFICATE_REVIEW':
        return '凭证审核';
      case 'CERTIFICATE_INVALID':
        return '凭证无效';
      case 'PENDING_PAYMENT':
        return '待打款';
      case 'COMPLETED':
        return '已完成';
      case 'EXPIRED':
        return '已失效';
      default:
        return statusCode;
    }
  }

  static String _toDateOnly(String? value) {
    if (value == null) return '';
    final trimmed = value.trim();
    if (trimmed.isEmpty) return '';
    final index = trimmed.indexOf('T');
    if (index > 0) {
      return trimmed.substring(0, index);
    }
    return trimmed;
  }

  static Widget _buildSubsidyItem(
    Map<String, dynamic> item, {
    void Function(Map<String, dynamic> item)? onSubsidyTap,
  }) {
    final name = item['name']?.toString() ?? '';
    final imageUrl = item['imageUrl']?.toString();
    final subsidyAmount = item['subsidyAmount']?.toString() ?? '';
    final skuCode = item['skuCode']?.toString() ?? '';
    final actionEnabled = onSubsidyTap != null;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        _buildSubsidyImage(imageUrl),
        SizedBox(width: 12.w),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (name.isNotEmpty)
                Text(
                  name,
                  style: TextStyle(
                    fontSize: 15.sp,
                    color: XiaobangColors.textMain,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              if (subsidyAmount.isNotEmpty) ...[
                SizedBox(height: 6.h),
                Text(
                  '补贴 $subsidyAmount',
                  style: TextStyle(
                    fontSize: 13.sp,
                    color: XiaobangColors.textSecondary,
                  ),
                ),
              ],
            ],
          ),
        ),
        SizedBox(width: 12.w),
        _buildSubsidyActionButton(
          onTap: () {
            if (onSubsidyTap != null) {
              onSubsidyTap(item);
              return;
            }
            debugPrint('subsidy claim tapped: $skuCode');
          },
          enabled: actionEnabled,
        ),
      ],
    );
  }

  static Widget _buildSubsidyActionButton({
    required VoidCallback onTap,
    bool enabled = true,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: enabled ? onTap : null,
        borderRadius: BorderRadius.circular(14.r),
        child: Ink(
          padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 6.h),
          decoration: BoxDecoration(
            color: XiaobangColors.primary.withOpacity(enabled ? 0.12 : 0.06),
            borderRadius: BorderRadius.circular(14.r),
            border: Border.all(color: XiaobangColors.primary.withOpacity(enabled ? 0.4 : 0.2)),
          ),
          child: Text(
            '领取补贴',
            style: TextStyle(
              fontSize: 12.sp,
              color: XiaobangColors.primary.withOpacity(enabled ? 1 : 0.5),
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ),
    );
  }

  static Widget _buildSubsidyImage(String? url) {
    final size = 48.w;
    if (url == null || url.isEmpty) {
      return Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          color: const Color(0xFFE9EBEF),
          borderRadius: BorderRadius.circular(8.r),
        ),
        child: Icon(
          Icons.image_not_supported_outlined,
          size: 20.w,
          color: XiaobangColors.textSecondary,
        ),
      );
    }
    return ClipRRect(
      borderRadius: BorderRadius.circular(8.r),
      child: Image.network(
        url,
        width: size,
        height: size,
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) {
          return Container(
            width: size,
            height: size,
            decoration: BoxDecoration(
              color: const Color(0xFFE9EBEF),
              borderRadius: BorderRadius.circular(8.r),
            ),
            child: Icon(
              Icons.broken_image_outlined,
              size: 20.w,
              color: XiaobangColors.textSecondary,
            ),
          );
        },
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:xiaobang/core/theme/app_theme.dart';

class BottomInputBar extends StatefulWidget {
  final Function(String)? onSendMessage;

  const BottomInputBar({
    super.key,
    this.onSendMessage,
  });

  @override
  State<BottomInputBar> createState() => _BottomInputBarState();
}

class _BottomInputBarState extends State<BottomInputBar> {
  final TextEditingController _textController = TextEditingController();
  final FocusNode _focusNode = FocusNode();
  bool _isVoiceMode = false; // false=键盘模式, true=语音模式
  bool _isRecording = false;
  bool _hasText = false;

  @override
  void initState() {
    super.initState();
    _textController.addListener(() {
      setState(() {
        _hasText = _textController.text.trim().isNotEmpty;
      });
    });
  }

  @override
  void dispose() {
    _textController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _toggleInputMode() {
    setState(() {
      _isVoiceMode = !_isVoiceMode;
      if (!_isVoiceMode) {
        // 切换到键盘模式时，自动弹起键盘
        Future.delayed(const Duration(milliseconds: 100), () {
          _focusNode.requestFocus();
        });
      } else {
        // 切换到语音模式时，关闭键盘
        _focusNode.unfocus();
      }
    });
  }

  void _sendMessage() {
    if (_hasText) {
      final text = _textController.text.trim();
      widget.onSendMessage?.call(text);
      _textController.clear();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.fromLTRB(16.w, 6.h, 16.w, 16.h),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: XiaobangColors.divider)),
      ),
      child: Row(
        children: [
          // 左侧：语音/键盘切换按钮
          GestureDetector(
            onTap: _toggleInputMode,
            child: Container(
              width: 32.w,
              height: 32.w,
              decoration: BoxDecoration(
                color: Colors.transparent,
                borderRadius: BorderRadius.circular(4.r),
              ),
              child: Image.asset(
                _isVoiceMode
                    ? 'assets/images/keyboard.png'
                    : 'assets/images/voice.png',
                width: 28.w,
                height: 28.w,
                color: XiaobangColors.textMain,
              ),
            ),
          ),
          SizedBox(width: 12.w),

          // 中间：输入框或语音按钮
          Expanded(
            child: _isVoiceMode ? _buildVoiceButton() : _buildTextField(),
          ),

          SizedBox(width: 12.w),

          // 右侧：发送按钮
          GestureDetector(
            onTap: _hasText ? _sendMessage : null,
            child: Container(
              width: 32.w,
              height: 32.w,
              decoration: BoxDecoration(
                color: _hasText ? XiaobangColors.primary : Colors.transparent,
                shape: BoxShape.circle,
              ),
              child: Center(
                child: Text(
                  'OK',
                  style: TextStyle(
                    color: _hasText ? Colors.white : XiaobangColors.primary,
                    fontSize: 13.sp,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // 键盘输入模式的文本框
  Widget _buildTextField() {
    return Container(
      constraints: BoxConstraints(
        minHeight: 40.h,
        maxHeight: 120.h,
      ),
      decoration: BoxDecoration(
        color: XiaobangColors.inputBg,
        borderRadius: BorderRadius.circular(20.h),
      ),
      padding: EdgeInsets.symmetric(horizontal: 16.w),
      child: TextField(
        controller: _textController,
        focusNode: _focusNode,
        textAlignVertical: TextAlignVertical.top,
        keyboardType: TextInputType.multiline,
        textInputAction: TextInputAction.newline,
        decoration: InputDecoration(
          hintText: "发消息",
          hintStyle: TextStyle(color: XiaobangColors.textSecondary),
          border: InputBorder.none,
          contentPadding: EdgeInsets.symmetric(vertical: 10.h),
        ),
        style: TextStyle(
          fontSize: 15.sp,
          color: XiaobangColors.textMain,
          height: 1.4,
        ),
        minLines: 1,
        maxLines: 5,
      ),
    );
  }

  // 语音输入模式的按钮
  Widget _buildVoiceButton() {
    return GestureDetector(
      onLongPressStart: (_) {
        setState(() {
          _isRecording = true;
        });
        // TODO: 开始录音
        debugPrint('开始录音');
      },
      onLongPressEnd: (_) {
        setState(() {
          _isRecording = false;
        });
        // TODO: 结束录音并发送
        debugPrint('结束录音');
      },
      onLongPressCancel: () {
        setState(() {
          _isRecording = false;
        });
        // TODO: 取消录音
        debugPrint('取消录音');
      },
      child: Container(
        height: 40.h,
        decoration: BoxDecoration(
          color: _isRecording ? XiaobangColors.primary.withOpacity(0.2) : XiaobangColors.inputBg,
          borderRadius: BorderRadius.circular(20.h),
        ),
        alignment: Alignment.center,
        child: Text(
          _isRecording ? "松开发送" : "按住说话",
          style: TextStyle(
            fontSize: 15.sp,
            color: _isRecording ? XiaobangColors.primary : XiaobangColors.textSecondary,
            fontWeight: _isRecording ? FontWeight.bold : FontWeight.normal,
          ),
        ),
      ),
    );
  }
}

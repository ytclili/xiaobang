import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../../core/theme/app_theme.dart';
import '../../domain/entities/message.dart';
import '../widgets/chat_item_factory.dart';
import '../widgets/bottom_input_bar.dart';
import '../widgets/app_drawer.dart';

class ChatPage extends StatefulWidget {
  const ChatPage({super.key});

  @override
  State<ChatPage> createState() => _ChatPageState();
}

class _ChatPageState extends State<ChatPage> {
  // 模拟聊天消息数据（改为可变列表）
  final List<MessageEntity> _messages = [
    MessageEntity(
      id: '1',
      type: MessageType.header,
      content: '晚上好，hi！',
    ),
    MessageEntity(
      id: '2',
      type: MessageType.quickAction,
      content: '听说你对"小帮专属券"有疑问？',
      extra: {'icon': '😋'},
    ),
    MessageEntity(
      id: '3',
      type: MessageType.quickAction,
      content: '「睡前冥想」能提升创造力哦～',
      extra: {'icon': '🧘'},
    ),
    MessageEntity(
      id: '4',
      type: MessageType.quickAction,
      content: '冬季滋补养生建议',
      extra: {'icon': '🥘🍵'},
    ),
  ];

  final ScrollController _scrollController = ScrollController();
  final FocusNode _drawerFocusNode = FocusNode();

  @override
  void dispose() {
    _scrollController.dispose();
    _drawerFocusNode.dispose();
    super.dispose();
  }

  // 发送消息
  void _handleSendMessage(String text) {
    if (text.trim().isEmpty) return;

    setState(() {
      // 添加用户消息
      _messages.add(MessageEntity(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        type: MessageType.text,
        content: text,
        isFromUser: true,
      ));
    });

    // 滚动到底部
    Future.delayed(const Duration(milliseconds: 100), () {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });

    // 模拟AI回复
    Future.delayed(const Duration(milliseconds: 1000), () {
      setState(() {
        _messages.add(MessageEntity(
          id: DateTime.now().millisecondsSinceEpoch.toString(),
          type: MessageType.text,
          content: '收到您的消息："$text"。我是小帮AI助手，正在为您处理...',
          isFromUser: false,
        ));
      });

      // 再次滚动到底部
      Future.delayed(const Duration(milliseconds: 100), () {
        if (_scrollController.hasClients) {
          _scrollController.animateTo(
            _scrollController.position.maxScrollExtent,
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeOut,
          );
        }
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: _scaffoldKey,
      backgroundColor: XiaobangColors.background,
      onDrawerChanged: (_) {
        // Keep the keyboard closed when the drawer changes state.
        FocusScope.of(context).requestFocus(_drawerFocusNode);
      },
      drawer: const AppDrawer(),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        automaticallyImplyLeading: false,
        leading: _buildMenuButton(),
        centerTitle: true,
        title: _buildLogo(),
        actions: [
          IconButton(
            icon: const Icon(Icons.add_circle_outline, color: XiaobangColors.textMain, size: 28),
            onPressed: () {
              // TODO: 打开新对话
            },
          ).animate()
            .scale(delay: 200.ms, duration: 300.ms),
          SizedBox(width: 8.w),
        ],
      ),
      body: Focus(
        focusNode: _drawerFocusNode,
        child: GestureDetector(
          onTap: () {
            // 点击空白区域，收起键盘
            FocusScope.of(context).unfocus();
          },
          child: Column(
            children: [
              Expanded(
                child: ListView.builder(
                  controller: _scrollController,
                  padding: EdgeInsets.symmetric(horizontal: 16.w),
                  itemCount: _messages.length + 1, // +1 for timestamp
                  itemBuilder: (context, index) {
                    if (index == 0) {
                      // 时间戳
                      return Column(
                        children: [
                          SizedBox(height: 20.h),
                          Center(
                            child: Text(
                              "20:41",
                              style: TextStyle(
                                color: XiaobangColors.textSecondary,
                                fontSize: 12.sp,
                              ),
                            ),
                          ).animate()
                            .fadeIn(duration: 400.ms),
                          SizedBox(height: 30.h),
                        ],
                      );
                    }
                    return ChatItemFactory.build(_messages[index - 1])
                      .animate()
                      .fadeIn(delay: (100 * index).ms, duration: 400.ms)
                      .slideX(begin: -0.1, end: 0, delay: (100 * index).ms, duration: 400.ms);
                  },
                ),
              ),
              BottomInputBar(
                onSendMessage: _handleSendMessage,
              ),
            ],
          ),
        ),
      ),
    );
  }

  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  // 左侧菜单按钮（带徽章）
  Widget _buildMenuButton() {
    return InkWell(
      onTap: () {
        _scaffoldKey.currentState?.openDrawer();
      },
      borderRadius: BorderRadius.circular(24.r),
      child: Stack(
        children: [
          const Center(
            child: Icon(Icons.menu, color: XiaobangColors.textMain, size: 28),
          ),
          Positioned(
            right: 8,
            top: 12,
            child: Container(
              padding: EdgeInsets.all(4.w),
              decoration: const BoxDecoration(
                color: XiaobangColors.background,
                shape: BoxShape.circle,
              ),
              child: Text(
                '1',
                style: TextStyle(
                  color: XiaobangColors.textMain,
                  fontSize: 10.sp,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ).animate(
              onPlay: (controller) => controller.repeat(reverse: true),
            )
            .scale(duration: 1500.ms, begin: const Offset(1.0, 1.0), end: const Offset(1.1, 1.1)),
          ),
        ],
      ),
    ).animate()
      .scale(delay: 100.ms, duration: 300.ms);
  }

  // Logo 头像
  Widget _buildLogo() {
    return Container(
      width: 48.w,
      height: 48.w,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(color: XiaobangColors.primary, width: 2),
        image: const DecorationImage(
          image: AssetImage('assets/images/avatar.png'),
          fit: BoxFit.cover,
        ),
      ),
    ).animate()
      .scale(delay: 150.ms, duration: 400.ms, curve: Curves.elasticOut);
  }
}

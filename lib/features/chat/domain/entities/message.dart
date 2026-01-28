enum MessageType {
  header,       // 头像+欢迎语
  quickAction,  // 快速操作气泡
  todo,         // 待办/话题卡片
  richText,     // 富文本回复
  text,         // 普通文本消息
  status,       // 状态提示（如：已通过全网收集17条参考信息）
}

class MessageEntity {
  final String id;
  final MessageType type;
  final String content;
  final bool isFromUser;
  final Map<String, dynamic>? extra; // 用于存储额外信息（icon, date, tag等）
  final DateTime timestamp;

  MessageEntity({
    required this.id,
    required this.type,
    required this.content,
    this.isFromUser = false,
    this.extra,
    DateTime? timestamp,
  }) : timestamp = timestamp ?? DateTime.now();
}

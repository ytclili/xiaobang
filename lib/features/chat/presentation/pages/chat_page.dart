import 'dart:async';
import 'dart:collection';
import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:loading_animation_widget/loading_animation_widget.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/network/api_client.dart';
import '../../../../core/utils/user_session.dart';
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
  static const int _recommendPlaceholderCount = 3;
  static const List<double> _recommendPlaceholderWidths = [220, 260, 200];
  static const double _scrollToBottomThreshold = 80.0;
  // 妯℃嫙鑱婂ぉ娑堟伅鏁版嵁锛堟敼涓哄彲鍙樺垪琛級
  final List<MessageEntity> _messages = [
    MessageEntity(
      id: '1',
      type: MessageType.header,
      content: '\u665a\u4e0a\u597d\uff0chi\uff01',
    ),
  ];

  final ScrollController _scrollController = ScrollController();
  final FocusNode _drawerFocusNode = FocusNode();
  late final VoidCallback _sessionSelectionListener;
  CancelToken? _streamCancelToken;
  StreamSubscription<String>? _streamSubscription;
  String _sseBuffer = '';
  String _utf16Carry = '';
  String _currentSessionId = '1521ae70c4bf4b6c9fbd4fb5ecdd7e20';
  String? _skipHistoryForSessionId;
  bool _pendingSessionTitleRefresh = false;
  bool _isHistoryLoading = false;
  bool _skipNextMessageAnimation = false;
  final Queue<String> _pendingDeltas = Queue<String>();
  Timer? _streamFlushTimer;
  String? _activeAiMessageId;
  bool _streamDone = false;
  static const int _maxCharsPerTick = 4;
  int _lastAutoScrollMs = 0;
  bool _showScrollToBottom = false;
  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_handleScrollPositionChanged);
    _sessionSelectionListener = () {
      final id = SessionSelectionBus.selectedSessionId.value;
      if (id == null || id.isEmpty) return;
      _currentSessionId = id;
      if (_skipHistoryForSessionId == id) {
        _skipHistoryForSessionId = null;
        return;
      }
      _fetchSessionHistory(id);
    };
    SessionSelectionBus.selectedSessionId.addListener(_sessionSelectionListener);
    final existingSelection = SessionSelectionBus.selectedSessionId.value;
    if (existingSelection != null && existingSelection.isNotEmpty) {
      _currentSessionId = existingSelection;
      _fetchSessionHistory(existingSelection);
    } else {
      _bootstrapInitialSession();
    }
    if (!_hasChatHistory) {
      _insertRecommendPlaceholders();
      _fetchRecommendQuestions();
    }
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _handleScrollPositionChanged();
    });
  }

  @override
  void dispose() {
    _cancelAiStream();
    _scrollController.removeListener(_handleScrollPositionChanged);
    _scrollController.dispose();
    _drawerFocusNode.dispose();
    SessionSelectionBus.selectedSessionId.removeListener(_sessionSelectionListener);
    super.dispose();
  }

  Future<void> _fetchRecommendQuestions() async {
    try {
      final response = await ApiClient.instance.post('/recommend/questions');
      debugPrint('recommend/questions response: ${response.data}');
      final data = response.data;
      if (data is Map<String, dynamic>) {
        final payload = data['data'];
        if (payload is Map<String, dynamic>) {
          final questions = payload['questions'];
          if (questions is List) {
            final now = DateTime.now().millisecondsSinceEpoch;
            if (_hasChatHistory) {
              if (mounted) {
                setState(_removeWelcomeItems);
              }
              return;
            }
            setState(() {
              _messages.removeWhere((item) => item.type == MessageType.quickAction);
              for (var i = 0; i < questions.length; i++) {
                final question = questions[i];
                if (question is String && question.trim().isNotEmpty) {
                  _messages.add(MessageEntity(
                    id: '${now}_$i',
                    type: MessageType.quickAction,
                    content: question,
                  ));
                }
              }
            });
          }
        }
      }
    } catch (error, stackTrace) {
      if (mounted) {
        setState(() {
          _messages.removeWhere(
            (item) => item.type == MessageType.quickAction && (item.extra?['loading'] == true),
          );
        });
      }
      debugPrint('recommend/questions error: $error');
      debugPrint('$stackTrace');
    }
  }

  bool get _hasChatHistory {
    return _messages.any((item) => item.type == MessageType.text);
  }

  void _removeWelcomeItems() {
    _messages.removeWhere((item) => item.type == MessageType.header);
    _messages.removeWhere((item) => item.type == MessageType.quickAction);
  }

  void _cancelAiStream() {
    _streamSubscription?.cancel();
    _streamSubscription = null;
    _streamCancelToken?.cancel();
    _streamCancelToken = null;
    _sseBuffer = '';
    _utf16Carry = '';
    _pendingDeltas.clear();
    _streamFlushTimer?.cancel();
    _streamFlushTimer = null;
    _activeAiMessageId = null;
    _streamDone = false;
  }

  Future<void> _startAiStream(String userMessage, String aiMessageId) async {
    _cancelAiStream();
    final userId = UserSession.userId;
    if (userId == null || userId.isEmpty) {
      _failAiStream(aiMessageId, '登录信息失效，请重新登录');
      return;
    }
    _streamCancelToken = CancelToken();
    _sseBuffer = '';
    _utf16Carry = '';
    _activeAiMessageId = aiMessageId;
    _streamDone = false;
    try {
      final response = await ApiClient.instance.postStream(
        'https://ai.xcbm.cc/api/chat/stream',
        data: {
          'message': userMessage,
          'userId': userId,
          'sessionId': _currentSessionId,
        },
        options: Options(receiveTimeout: const Duration(minutes: 1)),
        cancelToken: _streamCancelToken,
      );
      final responseBody = response.data;
      if (responseBody == null) return;
      final Stream<String> stream = responseBody.stream
          .cast<List<int>>()
          .transform(utf8.decoder);
      _streamSubscription = stream.listen(
        (chunk) => _handleSseChunk(chunk, aiMessageId),
        onError: (error, stackTrace) {
          debugPrint('ai stream error: $error');
          debugPrint('$stackTrace');
          _failAiStream(aiMessageId, '请求超时，请重试');
        },
        onDone: () => _markStreamDone(aiMessageId),
        cancelOnError: true,
      );
    } catch (error, stackTrace) {
      debugPrint('ai stream request error: $error');
      debugPrint('$stackTrace');
      _failAiStream(aiMessageId, '请求超时，请重试');
    }
  }

  void _handleSseChunk(String chunk, String aiMessageId) {
    _sseBuffer += chunk;
    while (true) {
      final newLineIndex = _sseBuffer.indexOf('\n');
      if (newLineIndex == -1) break;
      final line = _sseBuffer.substring(0, newLineIndex).trim();
      _sseBuffer = _sseBuffer.substring(newLineIndex + 1);
      if (line.isEmpty) continue;
      if (line.startsWith('data:')) {
        final data = line.substring(5).trim();
        debugPrint('sse data: $data');
        if (data == '[DONE]') {
          _markStreamDone(aiMessageId);
          continue;
        }
        dynamic decoded;
        try {
          decoded = jsonDecode(data);
        } catch (_) {
          decoded = null;
        }
        if (decoded is Map<String, dynamic>) {
          final type = decoded['type'];
          if (type == 'status') {
            final status = decoded['content'];
            if (status is String && status.trim().isNotEmpty) {
              _updateStreamingStatus(aiMessageId, status.trim());
            }
            continue;
          }
        }
        final text = _extractStreamText(decoded, data);
        if (text != null && text.isNotEmpty) {
          _enqueueDelta(text);
        }
      }
    }
  }

  String? _extractStreamText(dynamic decoded, String raw) {
    if (decoded is String) {
      return decoded;
    }
    if (decoded is Map<String, dynamic>) {
      final type = decoded['type'];
      if (type == 'text') {
        final content = decoded['content'];
        if (content is String && content.trim().isNotEmpty) {
          return content;
        }
      }
      final candidates = ['content', 'message', 'text', 'delta', 'answer', 'result'];
      for (final key in candidates) {
        final value = decoded[key];
        if (value is String && value.trim().isNotEmpty) {
          return value;
        }
      }
      return raw;
    }
    return raw;
  }

  void _updateStreamingStatus(String aiMessageId, String status) {
    if (!mounted) return;
    final index = _messages.indexWhere((item) => item.id == aiMessageId);
    if (index == -1) return;
    final current = _messages[index];
    final extra = current.extra == null ? <String, dynamic>{} : Map<String, dynamic>.from(current.extra!);
    if (extra['statusText'] == status) return;
    extra['statusText'] = status;
    final updated = MessageEntity(
      id: current.id,
      type: current.type,
      content: current.content,
      isFromUser: current.isFromUser,
      extra: extra,
      timestamp: current.timestamp,
    );
    setState(() {
      _messages[index] = updated;
    });
  }

  void _enqueueDelta(String text) {
    if (text.isEmpty) return;
    final normalized = _normalizeDelta(text);
    if (normalized.isEmpty) return;
    _pendingDeltas.add(normalized);
    _startFlushTimer();
  }

  void _startFlushTimer() {
    if (_streamFlushTimer != null) return;
    _streamFlushTimer = Timer.periodic(const Duration(milliseconds: 30), (timer) {
      if (!mounted) {
        timer.cancel();
        _streamFlushTimer = null;
        return;
      }
      if (_pendingDeltas.isEmpty) {
        timer.cancel();
        _streamFlushTimer = null;
        if (_streamDone && _activeAiMessageId != null) {
          _finishAiStream(_activeAiMessageId!);
        }
        return;
      }
      var chunk = _pendingDeltas.removeFirst();
      if (chunk.length > _maxCharsPerTick) {
        final splitIndex = _safeSplitIndex(chunk, _maxCharsPerTick);
        final head = chunk.substring(0, splitIndex);
        final tail = chunk.substring(splitIndex);
        if (tail.isNotEmpty) {
          _pendingDeltas.addFirst(tail);
        }
        chunk = head;
      }
      final id = _activeAiMessageId;
      if (id != null) {
        _appendAiText(id, chunk);
      }
    });
  }

  String _normalizeDelta(String text) {
    var combined = _utf16Carry + text;
    _utf16Carry = '';
    if (combined.isEmpty) return '';
    if (_isLowSurrogate(combined.codeUnitAt(0))) {
      combined = combined.substring(1);
      if (combined.isEmpty) return '';
    }
    final lastUnit = combined.codeUnitAt(combined.length - 1);
    if (_isHighSurrogate(lastUnit)) {
      _utf16Carry = String.fromCharCode(lastUnit);
      combined = combined.substring(0, combined.length - 1);
    }
    return combined;
  }

  int _safeSplitIndex(String text, int maxUnits) {
    if (text.length <= maxUnits) return text.length;
    var idx = maxUnits;
    if (idx > 0 && idx < text.length) {
      final prev = text.codeUnitAt(idx - 1);
      final next = text.codeUnitAt(idx);
      if (_isHighSurrogate(prev) && _isLowSurrogate(next)) {
        idx -= 1;
      }
    }
    if (idx <= 0) idx = maxUnits;
    return idx;
  }

  bool _isHighSurrogate(int unit) => unit >= 0xD800 && unit <= 0xDBFF;
  bool _isLowSurrogate(int unit) => unit >= 0xDC00 && unit <= 0xDFFF;

  void _appendAiText(String aiMessageId, String delta) {
    if (!mounted) return;
    final index = _messages.indexWhere((item) => item.id == aiMessageId);
    if (index == -1) return;
    final current = _messages[index];
    final updated = MessageEntity(
      id: current.id,
      type: current.type,
      content: current.content + delta,
      isFromUser: current.isFromUser,
      extra: current.extra,
      timestamp: current.timestamp,
    );
    setState(() {
      _messages[index] = updated;
    });
    _scrollToBottom(smooth: true);
  }

  void _finishAiStream(String aiMessageId) {
    if (!mounted) return;
    final index = _messages.indexWhere((item) => item.id == aiMessageId);
    if (index == -1) return;
    final current = _messages[index];
    final extra = current.extra == null ? null : Map<String, dynamic>.from(current.extra!);
    extra?.remove('streaming');
    final updated = MessageEntity(
      id: current.id,
      type: current.type,
      content: current.content,
      isFromUser: current.isFromUser,
      extra: extra,
      timestamp: current.timestamp,
    );
    setState(() {
      _messages[index] = updated;
    });
    _scrollToBottom(smooth: true, force: true);
    _maybeRefreshSessionListAfterFirstRound();
  }

  void _markStreamDone(String aiMessageId) {
    _streamDone = true;
    if (_pendingDeltas.isEmpty) {
      _finishAiStream(aiMessageId);
    }
  }

  void _failAiStream(String aiMessageId, String message) {
    if (!mounted) return;
    _pendingDeltas.clear();
    _streamFlushTimer?.cancel();
    _streamFlushTimer = null;
    _streamDone = true;
    _activeAiMessageId = aiMessageId;
    final index = _messages.indexWhere((item) => item.id == aiMessageId);
    if (index == -1) return;
    final current = _messages[index];
    final extra = current.extra == null ? null : Map<String, dynamic>.from(current.extra!);
    extra?.remove('streaming');
    final updated = MessageEntity(
      id: current.id,
      type: current.type,
      content: current.content.isEmpty ? message : current.content,
      isFromUser: current.isFromUser,
      extra: extra,
      timestamp: current.timestamp,
    );
    setState(() {
      _messages[index] = updated;
    });
    _scrollToBottom(smooth: true);
    _maybeRefreshSessionListAfterFirstRound();
  }

  void _scrollToBottom({bool smooth = false, bool force = false}) {
    if (!_scrollController.hasClients) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_scrollController.hasClients) return;
      final position = _scrollController.position;
      final max = position.maxScrollExtent;
      final current = position.pixels;
      final distance = max - current;
      if (!force) {
        if (distance > _scrollToBottomThreshold) return;
      }
      if (distance <= 0) return;
      if (smooth) {
        final nowMs = DateTime.now().millisecondsSinceEpoch;
        if (!force && nowMs - _lastAutoScrollMs < 80) return;
        _lastAutoScrollMs = nowMs;
      }
      final target = smooth && !force ? (current + 120).clamp(0.0, max) : max;
      final distanceForDuration = force ? distance : (target - current);
      final duration = smooth
          ? Duration(milliseconds: (distanceForDuration * 0.6).clamp(120.0, 900.0).round())
          : const Duration(milliseconds: 200);
      if ((target - current).abs() < 1) return;
      _scrollController.animateTo(
        target,
        duration: duration,
        curve: Curves.easeOut,
      );
    });
  }

  void _handleScrollPositionChanged() {
    if (!mounted || !_scrollController.hasClients) return;
    final position = _scrollController.position;
    final max = position.maxScrollExtent;
    final current = position.pixels;
    final shouldShow = max > 0 && (max - current) > _scrollToBottomThreshold;
    if (shouldShow == _showScrollToBottom) return;
    setState(() {
      _showScrollToBottom = shouldShow;
    });
  }

  void _insertRecommendPlaceholders() {
    _messages.removeWhere((item) => item.type == MessageType.quickAction);
    final now = DateTime.now().millisecondsSinceEpoch;
    for (var i = 0; i < _recommendPlaceholderCount; i++) {
      _messages.add(MessageEntity(
        id: 'placeholder_${now}_$i',
        type: MessageType.quickAction,
        content: '',
        extra: {
          'loading': true,
          'width': _recommendPlaceholderWidths[i % _recommendPlaceholderWidths.length],
        },
      ));
    }
  }

  Future<void> _startNewSession() async {
    _cancelAiStream();
    final userId = UserSession.userId;
    if (userId == null || userId.isEmpty) {
      debugPrint('start session skipped: missing userId');
      return;
    }
    String? newSessionId;
    try {
      final response = await ApiClient.instance.post(
        '/session/start',
        data: {
          'userId': userId,
        },
      );
      debugPrint('session/start response: ${response.data}');
      final data = response.data;
      if (data is Map<String, dynamic>) {
        final sessionId = data['sessionId'] ?? data['data']?['sessionId'];
        if (sessionId != null) {
          newSessionId = sessionId.toString();
        }
      }
      if (newSessionId != null && newSessionId.isNotEmpty) {
        _currentSessionId = newSessionId;
      }
    } catch (error, stackTrace) {
      debugPrint('session/start error: $error');
      debugPrint('$stackTrace');
    }
    if (newSessionId != null && newSessionId.isNotEmpty) {
      _pendingSessionTitleRefresh = true;
      _skipHistoryForSessionId = newSessionId;
      SessionListRefreshBus.upsert(newSessionId, '未命名会话');
      SessionSelectionBus.select(newSessionId);
    } else {
      _pendingSessionTitleRefresh = false;
    }
    _resetForNewSession();
  }

  void _resetForNewSession() {
    setState(() {
      _messages
        ..clear()
        ..add(
          MessageEntity(
            id: '1',
            type: MessageType.header,
            content: '晚上好，hi！',
          ),
        );
      _insertRecommendPlaceholders();
    });
    _fetchRecommendQuestions();
    _scrollToTop();
  }

  void _scrollToTop() {
    if (!_scrollController.hasClients) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_scrollController.hasClients) return;
      _scrollController.jumpTo(0);
    });
  }

  void _handleSendMessage(String text) {
    if (text.trim().isEmpty) return;

    FocusScope.of(context).unfocus();
    setState(() {
      _removeWelcomeItems();
      // 娣诲姞鐢ㄦ埛娑堟伅
      _messages.add(MessageEntity(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        type: MessageType.text,
        content: text,
        isFromUser: true,
      ));
    });

    // 婊氬姩鍒到簳閮?
    Future.delayed(const Duration(milliseconds: 100), () {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });

    final aiMessageId = 'ai_${DateTime.now().millisecondsSinceEpoch}';
    setState(() {
      _messages.add(MessageEntity(
        id: aiMessageId,
        type: MessageType.text,
        content: '',
        isFromUser: false,
        extra: const {'streaming': true},
      ));
    });
    _scrollToBottom(smooth: true);
    _startAiStream(text, aiMessageId);
  }

  List<Widget> _buildMessageWidgets() {
    final widgets = <Widget>[];
    for (var i = 0; i < _messages.length; i++) {
      final messageWidget = ChatItemFactory.build(
        _messages[i],
        onQuickActionTap: _handleSendMessage,
      );
      if (_skipNextMessageAnimation) {
        widgets.add(messageWidget);
        continue;
      }
      final delayMs = ((i + 1) * 30).clamp(0, 300);
      widgets.add(
        messageWidget
          .animate()
          .fadeIn(delay: delayMs.ms, duration: 300.ms)
          .slideX(begin: -0.06, end: 0, delay: delayMs.ms, duration: 300.ms),
      );
    }
    return widgets;
  }

  Future<void> _bootstrapInitialSession() async {
    final userId = UserSession.userId;
    if (userId == null || userId.isEmpty) {
      debugPrint('bootstrap session skipped: missing userId');
      return;
    }
    try {
      final response = await ApiClient.instance.get(
        '/session/list',
        queryParameters: {
          'userId': userId,
          'limit': 50,
          'offset': 0,
        },
      );
      final sessionId = _extractFirstSessionId(response.data);
      if (sessionId == null || sessionId.isEmpty) return;
      _currentSessionId = sessionId;
      SessionSelectionBus.select(sessionId);
    } catch (error, stackTrace) {
      debugPrint('session list bootstrap error: $error');
      debugPrint('$stackTrace');
    }
  }

  String? _extractFirstSessionId(dynamic data) {
    if (data is String) {
      try {
        data = jsonDecode(data);
      } catch (_) {
        return null;
      }
    }
    List<dynamic>? list;
    if (data is Map<String, dynamic>) {
      final payload = data['data'];
      if (payload is Map<String, dynamic>) {
        if (payload['list'] is List) {
          list = payload['list'] as List;
        } else if (payload['sessions'] is List) {
          list = payload['sessions'] as List;
        }
      } else if (payload is List) {
        list = payload;
      } else if (data['list'] is List) {
        list = data['list'] as List;
      } else if (data['sessions'] is List) {
        list = data['sessions'] as List;
      }
    } else if (data is List) {
      list = data;
    }
    if (list == null || list.isEmpty) return null;
    final first = list.first;
    if (first is Map<String, dynamic>) {
      final id = first['id'] ?? first['sessionId'];
      return id?.toString();
    }
    if (first is String) return first;
    return null;
  }

  Future<void> _fetchSessionHistory(String sessionId) async {
    final userId = UserSession.userId;
    if (userId == null || userId.isEmpty) {
      debugPrint('fetch history skipped: missing userId');
      return;
    }
    _cancelAiStream();
    setState(() {
      _isHistoryLoading = true;
      _skipNextMessageAnimation = true;
    });
    try {
      final response = await ApiClient.instance.get(
        '/session/history',
        queryParameters: {
          'userId': userId,
          'sessionId': sessionId,
          'limit': 200,
          'offset': 0,
        },
      );
      debugPrint('session/history response: ${response.data}');
      final items = _parseHistoryMessages(response.data, sessionId);
      if (!mounted) return;
      setState(() {
        _messages
          ..clear()
          ..addAll(items);
      });
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        if (_scrollController.hasClients) {
          _scrollController.jumpTo(_scrollController.position.maxScrollExtent);
        }
        setState(() {
          _isHistoryLoading = false;
          _skipNextMessageAnimation = false;
        });
      });
    } catch (error, stackTrace) {
      debugPrint('session/history error: $error');
      debugPrint('$stackTrace');
      if (!mounted) return;
      setState(() {
        _isHistoryLoading = false;
        _skipNextMessageAnimation = false;
      });
    }
  }

  List<MessageEntity> _parseHistoryMessages(dynamic data, String sessionId) {
    if (data is String) {
      try {
        data = jsonDecode(data);
      } catch (_) {
        return [];
      }
    }
    List<dynamic>? list;
    if (data is Map<String, dynamic>) {
      final payload = data['data'];
      if (payload is Map<String, dynamic>) {
        if (payload['history'] is List) {
          list = payload['history'] as List;
        } else if (payload['messages'] is List) {
          list = payload['messages'] as List;
        } else if (payload['list'] is List) {
          list = payload['list'] as List;
        }
      } else if (payload is List) {
        list = payload;
      } else if (data['history'] is List) {
        list = data['history'] as List;
      } else if (data['messages'] is List) {
        list = data['messages'] as List;
      } else if (data['list'] is List) {
        list = data['list'] as List;
      }
    } else if (data is List) {
      list = data;
    }
    if (list == null) return [];

    final List<MessageEntity> results = [];
    for (var i = 0; i < list.length; i++) {
      final item = list[i];
      if (item is Map<String, dynamic>) {
        final question = _readText(item, const ['question', 'q']);
        final answer = _readText(item, const ['answer', 'a', 'reply', 'response']);
        if (question != null && question.isNotEmpty) {
          results.add(_historyMessage(
            sessionId: sessionId,
            index: results.length,
            content: question,
            isFromUser: true,
          ));
        }
        if (answer != null && answer.isNotEmpty) {
          results.add(_historyMessage(
            sessionId: sessionId,
            index: results.length,
            content: answer,
            isFromUser: false,
          ));
        }
        if ((question != null && question.isNotEmpty) || (answer != null && answer.isNotEmpty)) {
          continue;
        }
        final content = _readText(item, const ['content', 'message', 'text', 'delta', 'result']);
        if (content == null || content.isEmpty) continue;
        final isFromUser = _inferIsFromUser(item);
        results.add(_historyMessage(
          sessionId: sessionId,
          index: results.length,
          content: content,
          isFromUser: isFromUser,
        ));
      } else if (item is String && item.trim().isNotEmpty) {
        results.add(_historyMessage(
          sessionId: sessionId,
          index: results.length,
          content: item,
          isFromUser: false,
        ));
      }
    }
    return results;
  }

  MessageEntity _historyMessage({
    required String sessionId,
    required int index,
    required String content,
    required bool isFromUser,
  }) {
    return MessageEntity(
      id: 'history_${sessionId}_$index',
      type: MessageType.text,
      content: content,
      isFromUser: isFromUser,
    );
  }

  String? _readText(Map<String, dynamic> item, List<String> keys) {
    for (final key in keys) {
      final value = item[key];
      if (value is String && value.trim().isNotEmpty) {
        return value;
      }
    }
    return null;
  }

  bool _inferIsFromUser(Map<String, dynamic> item) {
    final isFromUser = item['isFromUser'] ?? item['fromUser'] ?? item['isUser'];
    if (isFromUser is bool) return isFromUser;
    final role = (item['role'] ?? item['sender'] ?? item['type']).toString().toLowerCase();
    if (role.contains('user') || role.contains('human') || role.contains('client')) return true;
    if (role.contains('assistant') || role.contains('bot') || role.contains('ai')) return false;
    return false;
  }

  void _maybeRefreshSessionListAfterFirstRound() {
    if (!_pendingSessionTitleRefresh) return;
    _pendingSessionTitleRefresh = false;
    SessionListRefreshBus.notifyRefresh();
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
            icon: Image.asset(
              'assets/images/chat.png',
              width: 28.w,
              height: 28.w,
              color: XiaobangColors.textMain,
            ),
            onPressed: () {
              _startNewSession();
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
            // 鐐瑰嚮绌虹櫧鍖哄煙锛屾敹璧烽敭鐩?
            FocusScope.of(context).unfocus();
          },
          child: Stack(
            children: [
              Column(
                children: [
                  Expanded(
                    child: SingleChildScrollView(
                      controller: _scrollController,
                      padding: EdgeInsets.symmetric(horizontal: 16.w),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: _buildMessageWidgets(),
                      ),
                    ),
                  ),
                  BottomInputBar(
                    onSendMessage: _handleSendMessage,
                  ),
                ],
              ),
              if (_showScrollToBottom)
                Positioned(
                  right: 16.w,
                  bottom: 88.h,
                  child: _buildScrollToBottomButton(),
                ),
              if (_isHistoryLoading)
                Positioned.fill(
                  child: Container(
                    color: XiaobangColors.background,
                    child: Center(
                      child: Container(
                        padding: EdgeInsets.symmetric(horizontal: 24.w, vertical: 16.h),
                        decoration: BoxDecoration(
                          color: XiaobangColors.cardWhite,
                          borderRadius: BorderRadius.circular(16.r),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.08),
                              blurRadius: 12,
                              offset: const Offset(0, 6),
                            ),
                          ],
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            LoadingAnimationWidget.dotsTriangle(
                              color: XiaobangColors.primary,
                              size: 20.w,
                            ),
                            SizedBox(width: 12.w),
                            Text(
                              '加载历史记录…',
                              style: TextStyle(
                                fontSize: 14.sp,
                                color: XiaobangColors.textSecondary,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  // 宸︿晶鑿滃崟鎸夐挳锛堝甫寰界珷锛?
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

  // Logo 澶村儚
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

  Widget _buildScrollToBottomButton() {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => _scrollToBottom(smooth: true, force: true),
        borderRadius: BorderRadius.circular(20.r),
        child: Container(
          width: 40.w,
          height: 40.w,
          decoration: BoxDecoration(
            color: XiaobangColors.cardWhite,
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.12),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Icon(
            Icons.arrow_downward_rounded,
            color: XiaobangColors.primary,
            size: 22.w,
          ),
        ),
      ),
    ).animate()
      .fadeIn(duration: 160.ms)
      .scale(begin: const Offset(0.9, 0.9), end: const Offset(1, 1), duration: 180.ms);
  }
}

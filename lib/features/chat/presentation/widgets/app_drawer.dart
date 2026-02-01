import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:xiaobang/core/network/api_client.dart';
import 'package:xiaobang/core/theme/app_theme.dart';

class AppDrawer extends StatefulWidget {
  const AppDrawer({super.key});

  @override
  State<AppDrawer> createState() => _AppDrawerState();
}

class _AppDrawerState extends State<AppDrawer> {
  final List<_SessionItem> _sessions = [];
  bool _isLoading = true;
  bool _hasError = false;
  String? _selectedSessionId;
  late final VoidCallback _eventListener;
  late final VoidCallback _selectionListener;

  @override
  void initState() {
    super.initState();
    _selectedSessionId = SessionSelectionBus.selectedSessionId.value;
    _eventListener = () {
      if (!mounted) return;
      final event = SessionListRefreshBus.event.value;
      if (event == null) return;
      switch (event.type) {
        case SessionListEventType.refresh:
          _fetchSessions();
          break;
        case SessionListEventType.upsert:
          if (event.sessionId != null && event.title != null) {
            _upsertSession(event.sessionId!, event.title!);
          }
          break;
      }
    };
    _selectionListener = () {
      if (!mounted) return;
      final id = SessionSelectionBus.selectedSessionId.value;
      if (id == null || id.isEmpty) return;
      if (_selectedSessionId != id) {
        setState(() {
          _selectedSessionId = id;
        });
      }
    };
    SessionListRefreshBus.event.addListener(_eventListener);
    SessionSelectionBus.selectedSessionId.addListener(_selectionListener);
    _fetchSessions();
  }

  @override
  void dispose() {
    SessionListRefreshBus.event.removeListener(_eventListener);
    SessionSelectionBus.selectedSessionId.removeListener(_selectionListener);
    super.dispose();
  }

  Future<void> _fetchSessions() async {
    setState(() {
      _isLoading = true;
      _hasError = false;
    });
    try {
      final response = await ApiClient.instance.get(
        '/session/list',
        queryParameters: const {
          'userId': '1234567',
          'limit': 50,
          'offset': 0,
        },
      );
      final items = _parseSessions(response.data);
      _applyPendingUpserts(items);
      if (!mounted) return;
      setState(() {
        _sessions
          ..clear()
          ..addAll(items);
        _isLoading = false;
        _ensureSelection(items);
      });
    } catch (error, stackTrace) {
      debugPrint('session list error: $error');
      debugPrint('$stackTrace');
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _hasError = true;
      });
    }
  }

  List<_SessionItem> _parseSessions(dynamic data) {
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
    if (list == null) return [];
    return list
        .whereType<Map<String, dynamic>>()
        .map((item) {
          final id = (item['id'] ?? item['sessionId'] ?? '').toString();
          final title = (item['title'] ??
                  item['name'] ??
                  item['topic'] ??
                  item['lastMessage'] ??
                  '\u65b0\u4f1a\u8bdd')
              .toString();
          return _SessionItem(id: id, title: title);
        })
        .toList();
  }

  void _upsertSession(String sessionId, String title) {
    setState(() {
      _isLoading = false;
      _hasError = false;
      final index = _sessions.indexWhere((item) => item.id == sessionId);
      if (index == -1) {
        _sessions.insert(0, _SessionItem(id: sessionId, title: title));
      } else {
        _sessions[index] = _SessionItem(id: sessionId, title: title);
      }
      _selectedSessionId = sessionId;
    });
    SessionSelectionBus.select(sessionId);
  }

  void _applyPendingUpserts(List<_SessionItem> items) {
    final pending = SessionListRefreshBus.pendingUpserts;
    if (pending.isEmpty) return;
    for (final entry in pending.entries) {
      final index = items.indexWhere((item) => item.id == entry.key);
      if (index == -1) {
        items.insert(0, _SessionItem(id: entry.key, title: entry.value));
      } else {
        SessionListRefreshBus.resolvePending(entry.key);
      }
    }
  }

  void _ensureSelection(List<_SessionItem> items) {
    if (items.isEmpty) return;
    final desired = SessionSelectionBus.selectedSessionId.value ?? _selectedSessionId;
    if (desired != null && items.any((item) => item.id == desired)) {
      _selectedSessionId = desired;
      return;
    }
    final firstId = items.first.id;
    _selectedSessionId = firstId;
    SessionSelectionBus.select(firstId);
  }

  @override
  Widget build(BuildContext context) {
    return Drawer(
      backgroundColor: XiaobangColors.background,
      child: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ?????????
            SizedBox(
              width: double.infinity,
              child: Stack(
                children: [
                  Padding(
                    padding: EdgeInsets.all(24.w),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // ??????
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
                          'Hi, \u7528\u6237',
                          style: TextStyle(
                            fontSize: 20.sp,
                            fontWeight: FontWeight.bold,
                            color: XiaobangColors.textMain,
                          ),
                        ),
                        SizedBox(height: 4.h),
                        Text(
                          '\u5c0f\u5e2e\u4eca\u5929\u4e5f\u5728\u52aa\u529b\u5de5\u4f5c~',
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
            Expanded(
              child: _buildSessionList(),
            ),

            // ?????????
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

  Widget _buildSessionList() {
    if (_isLoading) {
      return Center(
        child: SizedBox(
          width: 20.w,
          height: 20.w,
          child: const CircularProgressIndicator(strokeWidth: 2),
        ),
      );
    }
    if (_hasError) {
      return Center(
        child: TextButton(
          onPressed: _fetchSessions,
          child: Text(
            '\u52a0\u8f7d\u5931\u8d25\uff0c\u70b9\u51fb\u91cd\u8bd5',
            style: TextStyle(fontSize: 14.sp),
          ),
        ),
      );
    }
    if (_sessions.isEmpty) {
      return Center(
        child: Text(
          '\u6682\u65e0\u4f1a\u8bdd',
          style: TextStyle(fontSize: 14.sp, color: XiaobangColors.textSecondary),
        ),
      );
    }
    return ListView.builder(
      padding: EdgeInsets.zero,
      itemCount: _sessions.length,
      itemBuilder: (context, index) {
        final session = _sessions[index];
        return _buildConversationItem(
          title: session.title,
          isSelected: session.id == _selectedSessionId,
          onTap: () {
            _selectSession(session);
          },
        );
      },
    );
  }

  Widget _buildConversationItem({
    required String title,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12.r),
        child: Container(
          margin: EdgeInsets.symmetric(horizontal: 12.w, vertical: 4.h),
          padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 14.h),
          decoration: BoxDecoration(
            color: isSelected ? XiaobangColors.primary.withOpacity(0.12) : Colors.transparent,
            borderRadius: BorderRadius.circular(12.r),
            border: Border.all(
              color: isSelected ? XiaobangColors.primary.withOpacity(0.4) : Colors.transparent,
              width: 1,
            ),
          ),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(
                    fontSize: 16.sp,
                    color: isSelected ? XiaobangColors.primary : XiaobangColors.textMain,
                    fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                  ),
                ),
              ),
              if (isSelected)
                Icon(
                  Icons.check_circle,
                  size: 16.sp,
                  color: XiaobangColors.primary,
                ),
            ],
          ),
        ),
      ),
    );
  }

  void _selectSession(_SessionItem session) {
    if (session.id == _selectedSessionId) {
      Navigator.of(context).maybePop();
      return;
    }
    setState(() {
      _selectedSessionId = session.id;
    });
    SessionSelectionBus.select(session.id);
    Navigator.of(context).maybePop();
  }
}

class _SessionItem {
  final String id;
  final String title;

  const _SessionItem({
    required this.id,
    required this.title,
  });
}

class SessionListRefreshBus {
  static final ValueNotifier<SessionListEvent?> event = ValueNotifier<SessionListEvent?>(null);
  static final Map<String, String> _pendingUpserts = {};

  static Map<String, String> get pendingUpserts => Map.unmodifiable(_pendingUpserts);

  static void notifyRefresh() {
    event.value = const SessionListEvent.refresh();
  }

  static void upsert(String sessionId, String title) {
    _pendingUpserts[sessionId] = title;
    event.value = SessionListEvent.upsert(sessionId, title);
  }

  static void resolvePending(String sessionId) {
    _pendingUpserts.remove(sessionId);
  }
}

class SessionSelectionBus {
  static final ValueNotifier<String?> selectedSessionId = ValueNotifier<String?>(null);

  static void select(String sessionId) {
    if (selectedSessionId.value == sessionId) {
      return;
    }
    selectedSessionId.value = sessionId;
  }
}

enum SessionListEventType { refresh, upsert }

@immutable
class SessionListEvent {
  final SessionListEventType type;
  final String? sessionId;
  final String? title;

  const SessionListEvent.refresh()
      : type = SessionListEventType.refresh,
        sessionId = null,
        title = null;

  const SessionListEvent.upsert(this.sessionId, this.title)
      : type = SessionListEventType.upsert;
}

// lib/pages/comment_page.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../services/post_services.dart';
import '../services/user_service.dart';
import '../services/theme_notifier.dart';

class CommentPage extends StatefulWidget {
  final Map<String, dynamic> post;
  const CommentPage({required this.post, Key? key}) : super(key: key);

  @override
  State<CommentPage> createState() => _CommentPageState();
}

class _CommentPageState extends State<CommentPage> {
  final _postSvc = PostService();
  final _userSvc = UserService();
  final _ctrl = TextEditingController();
  final _user = Supabase.instance.client.auth.currentUser!;
  final ScrollController _scrollCtrl = ScrollController();
  final Map<String, Future<Map<String, dynamic>>> _userFutures = {};

  String _timeAgo(String iso) {
    final dt = DateTime.parse(iso).toLocal();
    final diff = DateTime.now().difference(dt);
    if (diff.inSeconds < 60) return '${diff.inSeconds}s';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m';
    if (diff.inHours < 24) return '${diff.inHours}h';
    return '${diff.inDays}d';
  }

  Future<Map<String, dynamic>> _getUserDetails(String userId) {
    if (!_userFutures.containsKey(userId)) {
      _userFutures[userId] = _userSvc.detailsStream(userId).first.then((list) => list.isNotEmpty ? list.first : {});
    }
    return _userFutures[userId]!;
  }

  @override
  void dispose() {
    _ctrl.dispose();
    _scrollCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final postId = widget.post['id'] as String;
    return Consumer<ThemeNotifier>(
      builder: (context, themeNotifier, child) {
        final primaryColor = themeNotifier.primaryColor;
        final isDarkMode = themeNotifier.themeMode == ThemeMode.dark;

        return Scaffold(
          appBar: AppBar(
            title: Text(widget.post['title'] as String),
            elevation: 0,
            shadowColor: Colors.transparent,
          ),
          body: Column(
            children: [
              Expanded(
                child: StreamBuilder<List<Map<String, dynamic>>>(
                  stream: _postSvc.streamComments(postId),
                  builder: (_, snap) {
                    final comments = snap.data ?? [];
                    WidgetsBinding.instance.addPostFrameCallback((_) {
                      if (_scrollCtrl.hasClients) {
                        _scrollCtrl.jumpTo(_scrollCtrl.position.maxScrollExtent);
                      }
                    });

                    if (snap.connectionState != ConnectionState.active && 
                        snap.connectionState != ConnectionState.done) {
                      return const Center(child: CircularProgressIndicator());
                    }
                    if (comments.isEmpty) {
                      return Center(
                        child: Text(
                          'No comments yet',
                          style: TextStyle(color: isDarkMode ? Colors.white70 : Colors.grey),
                        ),
                      );
                    }
                    return ListView.builder(
                      controller: _scrollCtrl,
                      physics: const BouncingScrollPhysics(),
                      itemCount: comments.length,
                      itemBuilder: (_, i) {
                        final c = comments[i];
                        final commenterId = c['user_id'] as String;
                        return TweenAnimationBuilder<double>(
                          tween: Tween(begin: 0.8, end: 1.0),
                          duration: const Duration(milliseconds: 300),
                          curve: Curves.easeOutBack,
                          builder: (context, scale, child) {
                            return Transform.scale(
                              scale: scale,
                              child: child,
                            );
                          },
                          child: Padding(
                            padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
                            child: FutureBuilder<Map<String, dynamic>>(
                              future: _getUserDetails(commenterId),
                              builder: (ctx, userSnap) {
                                String avatarUrl = '';
                                String fullName = 'Unknown';
                                if (userSnap.connectionState == ConnectionState.done && userSnap.hasData) {
                                  final u = userSnap.data!;
                                  avatarUrl = u['avatar_url'] as String? ?? '';
                                  fullName = u['full_name'] as String? ?? 'No Name';
                                }

                                return ListTile(
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  leading: CircleAvatar(
                                    backgroundImage: 
                                      avatarUrl.isNotEmpty 
                                        ? NetworkImage(avatarUrl) 
                                        : null,
                                    child: avatarUrl.isEmpty
                                        ? const Icon(Icons.person, color: Colors.grey)
                                        : null,
                                  ),
                                  title: Row(
                                    children: [
                                      Expanded(
                                        child: Text(
                                          fullName,
                                          style: TextStyle(
                                            fontSize: 14,
                                            fontWeight: FontWeight.w600,
                                            color: isDarkMode ? Colors.white : Colors.black,
                                          ),
                                        ),
                                      ),
                                      Text(
                                        _timeAgo(c['created_at'] as String),
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: isDarkMode ? Colors.white54 : Colors.grey[600],
                                        ),
                                      ),
                                    ],
                                  ),
                                  subtitle: Padding(
                                    padding: const EdgeInsets.only(top: 4),
                                    child: Text(
                                      c['comment'] as String,
                                      style: TextStyle(
                                        fontSize: 14,
                                        color: isDarkMode ? Colors.white70 : Colors.black87,
                                      ),
                                    ),
                                  ),
                                );
                              },
                            ),
                          ),
                        );
                      },
                    );
                  },
                ),
              ),
              const Divider(height: 1),
              Container(
                padding: const EdgeInsets.symmetric(
                  vertical: 8, 
                  horizontal: 16,
                ),
                child: Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(28),
                    boxShadow: [
                      BoxShadow(
                        color: isDarkMode 
                          ? Colors.white.withOpacity(0.05)
                          : Colors.black.withOpacity(0.1),
                        offset: const Offset(0, 8),
                        blurRadius: 24,
                        spreadRadius: 0,
                      ),
                      BoxShadow(
                        color: isDarkMode 
                          ? Colors.white.withOpacity(0.02)
                          : Colors.black.withOpacity(0.05),
                        offset: const Offset(0, 2),
                        blurRadius: 8,
                        spreadRadius: 0,
                      ),
                    ],
                    color: isDarkMode ? Colors.grey[900] : Colors.grey[50],
                    border: Border.all(
                      color: isDarkMode ? Colors.grey[800]! : Colors.grey[200]!,
                      width: 1,
                    ),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _ctrl,
                          style: TextStyle(
                            color: isDarkMode ? Colors.white : Colors.black,
                          ),
                          decoration: InputDecoration(
                            hintText: 'Add a comment…',
                            hintStyle: TextStyle(
                              color: isDarkMode ? Colors.white54 : Colors.grey[600],
                            ),
                            border: InputBorder.none,
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 20, 
                              vertical: 12,
                            ),
                          ),
                        ),
                      ),
                      Container(
                        margin: const EdgeInsets.only(right: 8),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [
                              primaryColor.withOpacity(0.8),
                              primaryColor,
                            ],
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: primaryColor.withOpacity(0.3),
                              offset: const Offset(0, 4),
                              blurRadius: 12,
                              spreadRadius: 0,
                            ),
                          ],
                        ),
                        child: IconButton(
                          icon: const Icon(Icons.send, 
                            color: Colors.white, 
                            size: 20,
                          ),
                          padding: EdgeInsets.zero,
                          onPressed: () async {
                            final txt = _ctrl.text.trim();
                            if (txt.isEmpty) return;
                            await _postSvc.addComment(
                              postId: postId,
                              userId: _user.id,
                              comment: txt,
                            );
                            _ctrl.clear();
                          },
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
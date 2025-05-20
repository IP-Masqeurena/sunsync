// lib/pages/comment_page.dart

import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../services/post_services.dart';
import '../services/user_service.dart';

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

  String _timeAgo(String iso) {
    final dt = DateTime.parse(iso).toLocal();
    final diff = DateTime.now().difference(dt);
    if (diff.inSeconds < 60) return '${diff.inSeconds}s';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m';
    if (diff.inHours < 24)   return '${diff.inHours}h';
    return '${diff.inDays}d';
  }

  @override
  Widget build(BuildContext context) {
    final post = widget.post;
    return Scaffold(
      appBar: AppBar(title: Text(post['title'] as String)),
      body: Column(
        children: [
          Expanded(
            child: FutureBuilder<List<Map<String, dynamic>>>(
              future: _postSvc.fetchComments(post['id'] as String),
              builder: (_, snap) {
                if (snap.connectionState != ConnectionState.done) {
                  return const Center(child: CircularProgressIndicator());
                }
                final comments = snap.data ?? [];
                if (comments.isEmpty) {
                  return const Center(child: Text('No comments yet'));
                }
                return ListView.builder(
                  itemCount: comments.length,
                  itemBuilder: (_, i) {
                    final c = comments[i];
                    final commenterId = c['user_id'] as String;
                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 4),
                      child: StreamBuilder<List<Map<String, dynamic>>>(
                        stream: _userSvc.detailsStream(commenterId),
                        builder: (ctx, userSnap) {
                          String avatarUrl = '';
                          String fullName = 'Unknown';
                          if (userSnap.hasData && userSnap.data!.isNotEmpty) {
                            final u = userSnap.data!.first;
                            avatarUrl = u['avatar_url'] as String? ?? '';
                            fullName = u['full_name'] as String? ?? 'No Name';
                          }

                          return ListTile(
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
                                    style: const TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                                Text(
                                  _timeAgo(c['created_at'] as String),
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.grey[600],
                                  ),
                                ),
                              ],
                            ),
                            subtitle: Padding(
                              padding: const EdgeInsets.only(top: 4),
                              child: Text(
                                c['comment'] as String,
                                style: const TextStyle(fontSize: 14),
                              ),
                            ),
                          );
                        },
                      ),
                    );
                  },
                );
              },
            ),
          ),

          const Divider(height: 1),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _ctrl,
                    decoration: const InputDecoration(hintText: 'Add a comment…'),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.send),
                  onPressed: () async {
                    final txt = _ctrl.text.trim();
                    if (txt.isEmpty) return;
                    await _postSvc.addComment(
                      postId: post['id'] as String,
                      userId: _user.id,
                      comment: txt,
                    );
                    _ctrl.clear();
                    setState(() {}); // reload comments
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

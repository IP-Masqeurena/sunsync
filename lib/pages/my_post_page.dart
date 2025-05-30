// lib/pages/my_posts_page.dart

import 'package:flutter/material.dart';
import '../services/post_services.dart';
import 'edit_post_page.dart';

class MyPostsPage extends StatefulWidget {
  final String userId;
  const MyPostsPage({required this.userId, Key? key}) : super(key: key);

  @override
  State<MyPostsPage> createState() => _MyPostsPageState();
}

class _MyPostsPageState extends State<MyPostsPage> {
  final _postSvc = PostService();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('My Posts')),
      body: StreamBuilder<List<Map<String, dynamic>>>(
        stream: _postSvc
            .streamPosts()
            .map((all) =>
                all.where((p) => p['user_id'] == widget.userId).toList()),
        builder: (ctx, snap) {
          if (snap.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          final posts = snap.data ?? [];
          if (posts.isEmpty) {
            return const Center(child: Text('No posts yet'));
          }
          return ListView.builder(
            itemCount: posts.length,
            itemBuilder: (_, i) {
              final p = posts[i];
              final images = List<String>.from(p['image_urls'] ?? []);
              final thumbnailUrl =
                  images.isNotEmpty ? images.first : null;

              return Card(
                margin:
                    const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
                child: ListTile(
                  // Show first image as a 48×48 thumbnail, or a placeholder icon
                  leading: thumbnailUrl != null
                      ? ClipRRect(
                          borderRadius: BorderRadius.circular(4),
                          child: Image.network(
                            thumbnailUrl,
                            width: 48,
                            height: 48,
                            fit: BoxFit.cover,
                          ),
                        )
                      : const Icon(
                          Icons.image_not_supported,
                          size: 48,
                          color: Colors.grey,
                        ),

                  // Only the title now
                  title: Text(p['title'] as String),

                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.edit),
                        onPressed: () => Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => EditPostPage(post: p),
                          ),
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.delete),
                        onPressed: () async {
                          final ok = await showDialog<bool>(
                            context: context,
                            builder: (dialogContext) => AlertDialog(
                              title: const Text('Delete post?'),
                              content: const Text(
                                  'This action cannot be undone.'),
                              actions: [
                                TextButton(
                                  onPressed: () =>
                                      Navigator.pop(dialogContext, false),
                                  child: const Text('Cancel'),
                                ),
                                TextButton(
                                  onPressed: () =>
                                      Navigator.pop(dialogContext, true),
                                  child: const Text('Delete'),
                                ),
                              ],
                            ),
                          );
                          if (ok == true) {
                            await _postSvc
                                .deletePost(p['id'] as String);
                          }
                        },
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}

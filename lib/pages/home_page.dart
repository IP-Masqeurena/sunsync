import 'package:flutter/material.dart';
import 'package:carousel_slider/carousel_slider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../services/post_services.dart';
import '../services/user_service.dart';
import 'comment_page.dart';
import 'posting_page.dart';
import 'login_page.dart';

class HomePage extends StatefulWidget {
  const HomePage({Key? key}) : super(key: key);
  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final _postSvc = PostService();
  final _userSvc = UserService();
  final _supabase = Supabase.instance.client;
  late final String _currentUserId;

  @override
  void initState() {
    super.initState();
    _currentUserId = _supabase.auth.currentUser?.id ?? '';
  }

  void _redirectToLogin() {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const LoginPage()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Home'),
        elevation: 2,
      ),
      body: StreamBuilder<List<Map<String, dynamic>>>(
        stream: _postSvc.streamPosts(),
        builder: (ctx, snap) {
          if (snap.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          final posts = snap.data ?? [];
          return ScrollConfiguration(
            // Custom scroll behavior with physics that allow overscroll (rubber band effect)
            behavior: const ScrollBehavior().copyWith(
              physics: const BouncingScrollPhysics(
                parent: AlwaysScrollableScrollPhysics(),
              ),
              overscroll: true,
            ),
            child: RefreshIndicator(
              onRefresh: () async {
                // This gives visual feedback when pulling down
                // Wait a moment to simulate refresh
                await Future.delayed(const Duration(milliseconds: 800));
                // The stream will automatically update with new data
              },
              child: ListView.builder(
                padding: const EdgeInsets.only(bottom: 80),
                itemCount: posts.length,
                itemBuilder: (_, i) {
                  final p = posts[i];
                  return _PostCard(
                    post: p,
                    currentUserId: _currentUserId,
                    postSvc: _postSvc,
                    userSvc: _userSvc,
                    onRequireLogin: _redirectToLogin,
                  );
                },
              ),
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        child: const Icon(Icons.add),
        onPressed: () {
          if (_currentUserId.isEmpty) {
            _redirectToLogin();
          } else {
            Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) => PostingPage(userId: _currentUserId),
              ),
            );
          }
        },
      ),
    );
  }
}

class _PostCard extends StatefulWidget {
  final Map<String, dynamic> post;
  final String currentUserId;
  final PostService postSvc;
  final UserService userSvc;
  final VoidCallback onRequireLogin;

  const _PostCard({
    required this.post,
    required this.currentUserId,
    required this.postSvc,
    required this.userSvc,
    required this.onRequireLogin,
    Key? key,
  }) : super(key: key);

  @override
  State<_PostCard> createState() => _PostCardState();
}

class _PostCardState extends State<_PostCard> {
  Map<String, dynamic>? userData;
  bool isLoading = true;
  int _currentImageIndex = 0;

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    final userId = widget.post['user_id'] as String;
    final data = await widget.userSvc.getUserDetails(userId);
    if (mounted) {
      setState(() {
        userData = data;
        isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final images = List<String>.from(widget.post['image_urls'] as List);
    final orientation = widget.post['orientation'] as String? ?? 'landscape';
    final isLandscape = orientation == 'landscape';

    // Calculate dimensions based on orientation
    final screenWidth = MediaQuery.of(context).size.width;
    final cardWidth = screenWidth - 24; // Accounting for horizontal margins
    
    // For landscape: 16:9 aspect ratio
    // For portrait: 4:5 aspect ratio (Instagram style)
    final imageHeight = isLandscape 
      ? (cardWidth * 9 / 16) // 16:9 ratio
      : (cardWidth * 5 / 4);  // 4:5 ratio for portrait

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildUserHeader(),

          if (images.isNotEmpty) ...[
            CarouselSlider(
              items: images.map((url) {
                // Whether the current image has landscape or portrait orientation
                return Container(
                  width: double.infinity,
                  color: Colors.white,
                  child: Center(
                    child: Image.network(
                      url,
                      fit: BoxFit.contain,
                      loadingBuilder: (context, child, loadingProgress) {
                        if (loadingProgress == null) return child;
                        return Center(
                          child: CircularProgressIndicator(
                            value: loadingProgress.expectedTotalBytes != null
                                ? loadingProgress.cumulativeBytesLoaded /
                                    loadingProgress.expectedTotalBytes!
                                : null,
                          ),
                        );
                      },
                    ),
                  ),
                );
              }).toList(),
              options: CarouselOptions(
                height: imageHeight,
                enableInfiniteScroll: images.length > 1, 
                viewportFraction: 1.0,
                onPageChanged: (idx, reason) {
                  setState(() => _currentImageIndex = idx);
                },
              ),
            ),

            // Dot Indicators (only if >1 image)
            if (images.length > 1)
              SizedBox(
                height: 16,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(images.length, (idx) {
                    final isActive = idx == _currentImageIndex;
                    return AnimatedContainer(
                      duration: const Duration(milliseconds: 300),
                      curve: Curves.easeInOut,
                      width: isActive ? 12 : 8,
                      height: isActive ? 12 : 8,
                      margin: const EdgeInsets.symmetric(horizontal: 4),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: isActive ? Colors.blueAccent : Colors.grey,
                      ),
                    );
                  }),
                ),
              ),
          ],

          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.post['title'] as String? ?? '',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                if ((widget.post['subtitle'] as String?)?.isNotEmpty ?? false)
                  Text(
                    widget.post['subtitle'] as String,
                    style: const TextStyle(fontSize: 14, color: Colors.grey),
                  ),
              ],
            ),
          ),

          if ((widget.post['content'] as String?)?.isNotEmpty ?? false)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Text(widget.post['content'] as String),
            ),

          Padding(
            padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                Text('${widget.post['likes']}', style: const TextStyle(fontSize: 14)),
                IconButton(
                  icon: const Icon(Icons.thumb_up_alt_outlined),
                  onPressed: () {
                    if (widget.currentUserId.isEmpty) {
                      widget.onRequireLogin();
                    } else {
                      widget.postSvc.likePost(
                        widget.post['id'] as String,
                        widget.post['likes'] as int,
                      );
                    }
                  },
                ),
                IconButton(
                  icon: const Icon(Icons.comment_outlined),
                  onPressed: () {
                    if (widget.currentUserId.isEmpty) {
                      widget.onRequireLogin();
                    } else {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => CommentPage(post: widget.post),
                        ),
                      );
                    }
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildUserHeader() {
    if (isLoading) {
      return const ListTile(
        leading: CircleAvatar(
          child: CircularProgressIndicator(strokeWidth: 2),
        ),
        title: Text('Loading...'),
      );
    }

    final avatarUrl = userData?['avatar_url'] as String? ?? '';
    final fullName  = userData?['full_name']  as String? ?? 'No Name';
    final status    = userData?['is_undergrad'] == true ? 'Undergraduate' : 'Postgraduate';

    return ListTile(
      leading: CircleAvatar(
        backgroundImage: avatarUrl.isNotEmpty ? NetworkImage(avatarUrl) : null,
        child: avatarUrl.isEmpty ? const Icon(Icons.person, color: Colors.grey) : null,
      ),
      title: Text(fullName),
      subtitle: Text(status, style: const TextStyle(fontSize: 12)),
    );
  }
}
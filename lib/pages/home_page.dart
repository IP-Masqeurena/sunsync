import 'dart:async';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:carousel_slider/carousel_slider.dart';
import 'package:google_fonts/google_fonts.dart';
import '../services/post_services.dart';
import '../services/user_service.dart';
import 'posting_page.dart';
import 'login_page.dart';
import 'comment_page.dart';
import 'stats_page.dart';

class NoGlowScrollBehavior extends ScrollBehavior {
  @override
  Widget buildOverscrollIndicator(
      BuildContext context, Widget child, ScrollableDetails details) {
    return child;
  }
}

enum SortBy { Newest, Oldest, Likes, Tags }
enum _TagMenu { filter, back }

class HomePage extends StatefulWidget {
  const HomePage({Key? key}) : super(key: key);
  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage>
    with AutomaticKeepAliveClientMixin {
  final PostService _postSvc = PostService();
  final UserService _userSvc = UserService();
  final TextEditingController _searchCtrl = TextEditingController();
  final FocusNode _searchFocusNode = FocusNode();
  Timer? _debounce;

  final ValueNotifier<String> _searchQuery = ValueNotifier('');
  final ValueNotifier<SortBy> _sortBy = ValueNotifier(SortBy.Newest);
  final ValueNotifier<List<String>> _activeTags = ValueNotifier([]);

  String _userId = '';
  static const List<String> _allTags = [
    'examtips','tutoring','food','study','sports','clubs',
    'campuslife','accommodation','emergency','donations',
    'needhelp','events','schorlarships','others',
  ];

  @override
  void initState() {
    super.initState();
    _loadUser();
    _searchCtrl.addListener(_onSearchChanged);
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _searchCtrl.dispose();
    _searchFocusNode.dispose();
    _searchQuery.dispose();
    _sortBy.dispose();
    _activeTags.dispose();
    super.dispose();
  }

  void _loadUser() {
    final u = Supabase.instance.client.auth.currentUser;
    setState(() => _userId = u?.id ?? '');
  }

  void _onSearchChanged() {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 300), () {
      _searchQuery.value = _searchCtrl.text.trim();
    });
  }

  @override
  bool get wantKeepAlive => true;

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final scaffoldBackgroundColor = Theme.of(context).scaffoldBackgroundColor;
    
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'SUNSYNC',
          style: GoogleFonts.shareTech(
            fontSize: 40,
            fontWeight: FontWeight.normal,
          ),
        ),
        centerTitle: true,
        elevation: 0,
        backgroundColor: scaffoldBackgroundColor,
        surfaceTintColor: scaffoldBackgroundColor, // Fix applied here
        actions: [
          IconButton(
            icon: const Icon(Icons.bar_chart),
            onPressed: () {
              Navigator.of(context).push(
                PageRouteBuilder(
                  opaque: false,
                  transitionDuration: const Duration(milliseconds: 100),
                  pageBuilder: (ctx, anim1, anim2) => const StatsPage(),
                  transitionsBuilder: (ctx, animation, secAnim, child) {
                    return FadeTransition(
                      opacity: animation,
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          color: Theme.of(ctx).scaffoldBackgroundColor,
                        ),
                        child: child,
                      ),
                    );
                  },
                ),
              );
            },
          ),
        ],
      ),
      body: Column(
        children: [
          _buildSearchAndMenu(context),
          ValueListenableBuilder<List<String>>(
            valueListenable: _activeTags,
            builder: (context, tags, _) {
              return tags.isNotEmpty
                  ? _buildTagChips(tags)
                  : const SizedBox();
            },
          ),
          Expanded(child: _buildPostList()),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        child: const Icon(Icons.add),
        onPressed: () {
          if (_userId.isEmpty) {
            _redirectToLogin();
          } else {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => PostingPage(userId: _userId),
              ),
            );
          }
        },
      ),
    );
  }

  Widget _buildSearchAndMenu(BuildContext ctx) {
    final isDark = Theme.of(ctx).brightness == Brightness.dark;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                color: isDark ? Colors.grey[800] : Colors.grey[200],
                borderRadius: BorderRadius.circular(30),
              ),
              child: ValueListenableBuilder<String>(
                valueListenable: _searchQuery,
                builder: (context, query, _) {
                  return TextField(
                    focusNode: _searchFocusNode,
                    controller: _searchCtrl,
                    decoration: InputDecoration(
                      hintText: 'Search posts...',
                      prefixIcon: Icon(Icons.search, color: Theme.of(context).iconTheme.color),
                      suffixIcon: query.isEmpty
                          ? null
                          : IconButton(
                              icon: const Icon(Icons.clear, size: 20),
                              onPressed: () {
                                _searchCtrl.clear();
                                _searchQuery.value = '';
                              },
                            ),
                      border: InputBorder.none,
                      contentPadding: const EdgeInsets.symmetric(vertical: 15),
                    ),
                    style: TextStyle(color: Theme.of(context).textTheme.bodyLarge?.color),
                  );
                },
              ),
            ),
          ),

          const SizedBox(width: 12),

          ValueListenableBuilder<SortBy>(
            valueListenable: _sortBy,
            builder: (context, sort, _) {
              return Container(
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.primary,
                  borderRadius: BorderRadius.circular(30),
                ),
                child: PopupMenuButton<Object>(
                  offset: const Offset(0, 45),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    child: Row(
                      children: [
                        Icon(Icons.sort, color: Theme.of(context).colorScheme.onPrimary),
                        const SizedBox(width: 4),
                        Text('Sort', style: TextStyle(
                          color: Theme.of(context).colorScheme.onPrimary,
                          fontWeight: FontWeight.w500
                        )),
                      ],
                    ),
                  ),
                  onSelected: (v) async {
                    _searchFocusNode.unfocus();
                    if (v is SortBy) {
                      _sortBy.value = v;
                      if (v != SortBy.Tags) {
                        _activeTags.value = [];
                      }
                    } else if (v == _TagMenu.filter) {
                      final sel = await showMenu<Object>(
                        context: ctx,
                        position: _popupPosition(ctx),
                        items: [
                          PopupMenuItem<Object>(
                            value: _TagMenu.back,
                            child: const Text('← Back'),
                          ),
                          ..._allTags.map((t) => PopupMenuItem<Object>(
                                value: t,
                                child: Text(t),
                              )),
                        ],
                      );
                      if (sel is String) {
                        final newTags = List<String>.from(_activeTags.value);
                        if (!newTags.contains(sel) && newTags.length < 3) {
                          newTags.add(sel);
                          _activeTags.value = newTags;
                          _sortBy.value = SortBy.Tags;
                        }
                      }
                    }
                  },
                  itemBuilder: (_) => [
                    PopupMenuItem<Object>(
                      value: SortBy.Newest,
                      child: Row(
                        children: [
                          if (sort == SortBy.Newest) 
                            Icon(Icons.check, size: 20, color: Theme.of(context).iconTheme.color),
                          const SizedBox(width: 12),
                          const Text('Newest'),
                        ],
                      ),
                    ),
                    PopupMenuItem<Object>(
                      value: SortBy.Oldest,
                      child: Row(
                        children: [
                          if (sort == SortBy.Oldest) 
                            Icon(Icons.check, size: 20, color: Theme.of(context).iconTheme.color),
                          const SizedBox(width: 12),
                          const Text('Oldest'),
                        ],
                      ),
                    ),
                    PopupMenuItem<Object>(
                      value: SortBy.Likes,
                      child: Row(
                        children: [
                          if (sort == SortBy.Likes) 
                            Icon(Icons.check, size: 20, color: Theme.of(context).iconTheme.color),
                          const SizedBox(width: 12),
                          const Text('Likes'),
                        ],
                      ),
                    ),
                    const PopupMenuItem<Object>(
                      value: _TagMenu.filter,
                      child: Text('By Tags'),
                    ),
                  ],
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  RelativeRect _popupPosition(BuildContext ctx) {
    final box = ctx.findRenderObject() as RenderBox;
    final offset = box.localToGlobal(Offset.zero);
    return RelativeRect.fromLTRB(
      offset.dx,
      offset.dy + box.size.height,
      offset.dx + box.size.width,
      0,
    );
  }

  Widget _buildTagChips(List<String> tags) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Wrap(
        spacing: 8,
        children: tags.map((t) {
          return Chip(
            label: Text(t),
            onDeleted: () {
              final newTags = List<String>.from(tags)..remove(t);
              _activeTags.value = newTags;
              if (newTags.isEmpty) _sortBy.value = SortBy.Newest;
            },
          );
        }).toList(),
      ),
    );
  }

  bool _matchesSearch(String text, String query) {
    if (query.isEmpty) return false;
    String normalize(String input) => input
        .toLowerCase()
        .replaceAll(RegExp(r'[^\w]'), '')
        .replaceAll(' ', '');
    return normalize(text).contains(normalize(query));
  }

  Widget _buildPostList() {
    return GestureDetector(
      onTap: () => _searchFocusNode.unfocus(),
      behavior: HitTestBehavior.opaque,
      child: StreamBuilder<List<Map<String, dynamic>>>(
        stream: _postSvc.streamPosts(),
        builder: (ctx, snap) {
          if (snap.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          final posts = snap.data ?? [];

          return ListenableBuilder(
            listenable: Listenable.merge([
              _searchQuery,
              _sortBy,
              _activeTags,
            ]),
            builder: (context, _) {
              var filteredPosts = List<Map<String, dynamic>>.from(posts);

              final query = _searchQuery.value;
              if (query.isNotEmpty) {
                filteredPosts = filteredPosts.where((p) {
                  final t = p['title'] as String? ?? '';
                  final c = p['content'] as String? ?? '';
                  return _matchesSearch(t, query) || _matchesSearch(c, query);
                }).toList();
              }

              final tags = _activeTags.value;
              if (tags.isNotEmpty && _sortBy.value == SortBy.Tags) {
                filteredPosts = filteredPosts.where((p) {
                  final postTags = List<String>.from(p['tags'] ?? []);
                  return tags.every((t) => postTags.contains(t));
                }).toList();
              }

              filteredPosts.sort((a, b) {
                switch (_sortBy.value) {
                  case SortBy.Oldest:
                    return DateTime.parse(a['created_at'])
                        .compareTo(DateTime.parse(b['created_at']));
                  case SortBy.Likes:
                    return (b['likes'] as int).compareTo(a['likes'] as int);
                  case SortBy.Newest:
                  case SortBy.Tags:
                    return DateTime.parse(b['created_at'])
                        .compareTo(DateTime.parse(a['created_at']));
                }
              });

              if (filteredPosts.isEmpty) {
                return const Center(child: Text('No posts found.'));
              }

              return RefreshIndicator(
                onRefresh: () async => Future.delayed(const Duration(milliseconds: 500)),
                child: ListView.builder(
                  padding: const EdgeInsets.only(bottom: 80),
                  physics: const BouncingScrollPhysics(),
                  itemCount: filteredPosts.length,
                  itemBuilder: (_, i) {
                    final p = filteredPosts[i];
                    return _PostCard(
                      post: p,
                      currentUserId: _userId,
                      postSvc: _postSvc,
                      userSvc: _userSvc,
                      onRequireLogin: _redirectToLogin,
                      key: ValueKey<String>(p['id']),
                    );
                  },
                ),
              );
            },
          );
        },
      ),
    );
  }

  void _redirectToLogin() {
    Navigator.push(context, MaterialPageRoute(builder: (_) => const LoginPage()));
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

class _PostCardState extends State<_PostCard> with AutomaticKeepAliveClientMixin {
  Map<String, dynamic>? userData;
  bool isLoading = true;
  int _currentImageIndex = 0;

  @override
  void initState() {
    super.initState();
    _loadUser();
  }

  @override
  bool get wantKeepAlive => true;

  Future<void> _loadUser() async {
    final data = await widget.userSvc.getUserDetails(widget.post['user_id'] as String);
    if (mounted) {
      setState(() {
        userData = data;
        isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final images = List<String>.from(widget.post['image_urls'] as List);
    final orientation = widget.post['orientation'] as String? ?? 'landscape';
    final isLandscape = orientation == 'landscape';
    final screenWidth = MediaQuery.of(context).size.width;
    final height = isLandscape
        ? (screenWidth - 24) * 9 / 16
        : (screenWidth - 24) * 5 / 4;

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      elevation: 2,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          isLoading
              ? const ListTile(
                  leading: CircleAvatar(child: CircularProgressIndicator()),
                  title: Text('Loading...'),
                )
              : ListTile(
                  leading: CircleAvatar(
                    backgroundImage: (userData?['avatar_url'] as String?)?.isNotEmpty == true
                        ? NetworkImage(userData!['avatar_url'])
                        : null,
                    child: (userData?['avatar_url'] as String?)?.isNotEmpty != true
                        ? const Icon(Icons.person, color: Colors.grey)
                        : null,
                  ),
                  title: Text(userData?['full_name'] as String? ?? 'No Name'),
                  subtitle: Text(
                    (userData?['is_undergrad'] == true) ? 'Undergraduate' : 'Postgraduate',
                    style: const TextStyle(fontSize: 12),
                  ),
                ),
          if (images.isNotEmpty) ...[
            CarouselSlider(
              items: images
                  .map((url) => Container(
                        width: double.infinity,
                        color: Theme.of(context).colorScheme.surface,
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
                      ))
                  .toList(),
              options: CarouselOptions(
                height: height,
                viewportFraction: 1.0,
                enableInfiniteScroll: images.length > 1,
                onPageChanged: (i, _) => setState(() => _currentImageIndex = i),
              ),
            ),
            if (images.length > 1)
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: images.asMap().entries.map((e) {
                  final idx = e.key;
                  return AnimatedContainer(
                    duration: const Duration(milliseconds: 300),
                    width: idx == _currentImageIndex ? 12 : 8,
                    height: idx == _currentImageIndex ? 12 : 8,
                    margin: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Theme.of(context).colorScheme.primary
                          .withOpacity(idx == _currentImageIndex ? 1 : 0.4),
                    ),
                  );
                }).toList(),
              ),
          ],
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(widget.post['title'] as String? ?? '',
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                if ((widget.post['content'] as String?)?.isNotEmpty ?? false)
                  Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Text(widget.post['content'] as String),
                  ),
              ],
            ),
          ),
          if (widget.post['tags'] != null && (widget.post['tags'] as List).isNotEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Wrap(
                spacing: 6,
                children: (widget.post['tags'] as List).map<Widget>((tag) {
                  return Chip(
                    label: Text(tag.toString()),
                    visualDensity: VisualDensity.compact,
                    materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  );
                }).toList(),
              ),
            ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8),
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
                      Navigator.of(context).push(MaterialPageRoute(
                          builder: (_) => CommentPage(post: widget.post)));
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
}
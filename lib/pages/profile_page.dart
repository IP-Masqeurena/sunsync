import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:provider/provider.dart';
import 'package:sunsync/pages/my_post_page.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../services/theme_notifier.dart';
import '../services/user_service.dart';
import 'login_page.dart';
import 'edit_profile_page.dart';
import 'change_password_page.dart';
import 'settings_page.dart';
import 'view_detail_page.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({Key? key}) : super(key: key);

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage>
    with AutomaticKeepAliveClientMixin<ProfilePage> {
  @override
  bool get wantKeepAlive => true;

  late final SupabaseClient _supabase;
  late final Stream<AuthState> _authStream;
  late final UserService _userService;
  String? _localBannerChoice;

  @override
  void initState() {
    super.initState();
    _supabase = Supabase.instance.client;
    _authStream = _supabase.auth.onAuthStateChange;
    _userService = UserService();

    // Optional: Precache your banners for zero-lag display
    WidgetsBinding.instance.addPostFrameCallback((_) {
      for (final asset in [
        'lib/assets/banners/soulhunter.jpg',
        'lib/assets/banners/firefull_flyshine.jpg',
      ]) {
        precacheImage(AssetImage(asset), context);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return Scaffold(
      extendBodyBehindAppBar: true,
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.transparent,
        actions: [
          StreamBuilder<AuthState>(
            stream: _authStream,
            builder: (context, snap) {
              final user = snap.data?.session?.user;
              return IconButton(
                icon: Icon(
                  user == null ? Icons.login : Icons.logout,
                  color: Theme.of(context).iconTheme.color,
                ),
                onPressed: () async {
                  if (user == null) {
                    Navigator.of(context).push(
                      MaterialPageRoute(builder: (_) => const LoginPage()),
                    );
                  } else {
                    await _supabase.auth.signOut();
                  }
                },
              );
            },
          ),
        ],
      ),
      body: StreamBuilder<AuthState>(
        stream: _authStream,
        builder: (context, authSnap) {
          final user = authSnap.data?.session?.user;
          if (user == null) return _notLoggedInView(context);
          return StreamBuilder<List<Map<String, dynamic>>>(
            stream: _userService.detailsStream(user.id),
            builder: (context, dataSnap) {
              if (dataSnap.connectionState == ConnectionState.waiting &&
                  !dataSnap.hasData) {
                return const Center(child: CircularProgressIndicator());
              }
              if (dataSnap.hasError) {
                return Center(child: Text('Error: ${dataSnap.error}'));
              }
              final list = dataSnap.data;
              if (list == null || list.isEmpty) {
                return const Center(child: Text('Profile data not found.'));
              }
              _localBannerChoice = list.first['banner_choice'] as String?;
              return _buildProfile(context, user.id, list.first);
            },
          );
        },
      ),
    );
  }

  Widget _notLoggedInView(BuildContext context) => Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text('Not logged in', style: TextStyle(fontSize: 18)),
            const SizedBox(height: 24),
            InkWell(
              onTap: () => Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const LoginPage()),
              ),
              child: Container(
                width: 250,
                height: 60,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF5B75CF), Color(0xFF9C5ECF)],
                    begin: Alignment.centerLeft,
                    end: Alignment.centerRight,
                  ),
                  borderRadius: BorderRadius.circular(50),
                  border: Border.all(color: Colors.white, width: 2),
                ),
                child: const Center(
                  child: Text(
                    'LOGIN',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 2,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      );

  Widget _buildSettingsDivider() => Divider(
        height: 0.5,
        thickness: 0.5,
        indent: 56,
        endIndent: 16,
        color: Theme.of(context).dividerColor.withOpacity(0.5),
      );

  Widget _buildAppleSettingsItem({
    required IconData icon,
    required Color iconBackgroundColor,
    required String title,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
          child: Row(
            children: [
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: iconBackgroundColor,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Icon(icon, color: Colors.white, size: 18),
              ),
              const SizedBox(width: 12),
              Expanded(child: Text(title, style: const TextStyle(fontSize: 17))),
              const SizedBox(width: 8),
              Icon(Icons.arrow_forward_ios, size: 14, color: Colors.grey[500]),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildProfile(
      BuildContext context, String uid, Map<String, dynamic> data) {
    final avatarUrl = data['avatar_url'] as String?;
    final bannerChoice = _localBannerChoice;
    final topPadding = MediaQuery.of(context).padding.top;
    final headerHeight = topPadding + 130;

    String? bannerAsset;
    switch (bannerChoice) {
      case 'soulhunter':
        bannerAsset = 'lib/assets/banners/soulhunter.jpg';
        break;
      case 'firefull_flyshine':
        bannerAsset = 'lib/assets/banners/firefull_flyshine.jpg';
        break;
      default:
        bannerAsset = null;
    }

    final textTheme = Theme.of(context).textTheme;
    final settingsItemsData = [
      {
        'icon': Icons.person_search_outlined,
        'title': 'Profile details',
        'color': Colors.blueGrey.shade400,
        'onTap': () => Navigator.of(context).push(
            MaterialPageRoute(
                builder: (_) =>
                    ViewDetailPage(data: data, avatarUrl: avatarUrl)))
      },
      {
        'icon': Icons.edit_outlined,
        'title': 'Edit Profile',
        'color': Colors.blue.shade400,
        'onTap': () => Navigator.of(context).push(MaterialPageRoute(
            builder: (_) =>
                EditProfilePage(uid: uid, existingData: data)))
      },
      {
        'icon': Icons.image_outlined,
        'title': 'Banner decorate',
        'color': Colors.purpleAccent.shade200,
        'onTap': () => _showBannerDecorate(context, uid)
      },
      {
        'icon': Icons.article_outlined,
        'title': 'My Posts',
        'color': Colors.orange.shade400,
        'onTap': () {
          final currentUserId = _supabase.auth.currentUser?.id;
          if (currentUserId != null) {
            Navigator.of(context).push(MaterialPageRoute(
                builder: (_) => MyPostsPage(userId: currentUserId)));
          }
        }
      },
      {
        'icon': Icons.lock_outline,
        'title': 'Change Password',
        'color': Colors.teal.shade400,
        'onTap': () => Navigator.of(context).push(MaterialPageRoute(
            builder: (_) => const ChangePasswordPage()))
      },
      {
        'icon': Icons.settings_outlined,
        'title': 'Settings',
        'color': Colors.grey.shade500,
        'onTap': () => Navigator.of(context).push(
            MaterialPageRoute(builder: (_) => SettingsPage()))
      },
      {
        'icon': Icons.logout,
        'title': 'Log out',
        'color': Colors.redAccent.shade200,
        'onTap': () async => await _supabase.auth.signOut()
      },
    ];

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Stack(
            alignment: Alignment.topCenter,
            children: [
              Container(
                height: headerHeight,
                decoration: BoxDecoration(
                  image: bannerAsset != null
                      ? DecorationImage(
                          image: AssetImage(bannerAsset),
                          fit: BoxFit.cover,
                          colorFilter: ColorFilter.mode(
                              Colors.black.withOpacity(0.4), BlendMode.darken),
                        )
                      : null,
                ),
              ),
              Padding(
                padding: EdgeInsets.only(top: topPadding + 45),
                child: Column(
                  children: [
                    CircleAvatar(
                      radius: 67,
                      backgroundColor: Theme.of(context).colorScheme.surface,
                      backgroundImage:
                          avatarUrl != null ? NetworkImage(avatarUrl) : null,
                      child: avatarUrl == null
                          ? Icon(Icons.person,
                              size: 67, color: Colors.grey[400])
                          : null,
                    ),
                    const SizedBox(height: 8),
                    Text(data['full_name'] ?? 'User Name',
                        style: textTheme.headlineLarge
                            ?.copyWith(
                                fontWeight: FontWeight.bold, fontSize: 34),
                        textAlign: TextAlign.center),
                    const SizedBox(height: 4),
                    Text(
                        data['is_undergrad'] == true
                            ? 'Undergraduate'
                            : 'Postgraduate',
                        style: textTheme.bodyMedium
                            ?.copyWith(fontSize: 16)),
                  ],
                ),
              ),
            ],
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
            child: Container(
              decoration: BoxDecoration(
                color: Theme.of(context).cardColor,
                borderRadius: BorderRadius.circular(12.0),
                boxShadow: [
                  BoxShadow(
                      color: Colors.black.withOpacity(0.04),
                      blurRadius: 10,
                      offset: const Offset(0, 3))
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(12.0),
                child: Column(
                  children: [
                    for (var i = 0; i < settingsItemsData.length; i++) ...[
                      _buildAppleSettingsItem(
                        icon: settingsItemsData[i]['icon'] as IconData,
                        iconBackgroundColor:
                            settingsItemsData[i]['color'] as Color,
                        title: settingsItemsData[i]['title'] as String,
                        onTap: settingsItemsData[i]['onTap'] as VoidCallback,
                      ),
                      if (i < settingsItemsData.length - 1)
                        _buildSettingsDivider(),
                    ],
                    const SizedBox(height: 8),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _showBannerDecorate(
      BuildContext context, String uid) async {
    final choices = [
      {'label': 'None', 'value': null},
      {'label': 'SoulHunter', 'value': 'soulhunter'},
      {
        'label': 'Firefull Flyshine',
        'value': 'firefull_flyshine'
      },
    ];
    String? tempChoice = _localBannerChoice;

    final result = await showModalBottomSheet<String?>(
      context: context,
      isDismissible: false,
      enableDrag: false,
      backgroundColor: Theme.of(context).canvasColor,
      shape: const RoundedRectangleBorder(
        borderRadius:
            BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) {
        return SizedBox(
          height: 300,
          child: Column(
            children: [
              SizedBox(
                height: 200,
                child: CupertinoPicker(
                  scrollController:
                      FixedExtentScrollController(
                    initialItem: choices.indexWhere(
                        (c) => c['value'] == tempChoice),
                  ),
                  itemExtent: 40,
                  onSelectedItemChanged: (i) {
                    tempChoice = choices[i]['value'];
                  },
                  children: choices.map((c) {
                    final color = c['value'] == 'soulhunter'
                        ? const Color(0xFFEE6E6D)
                        : c['value'] ==
                                'firefull_flyshine'
                            ? const Color(0xFFBEECDA)
                            : const Color(0xFF0096FF);
                    return Center(
                      child: Text(
                        c['label']!,
                        style: TextStyle(
                            color: color, fontSize: 20),
                      ),
                    );
                  }).toList(),
                ),
              ),
              Align(
                alignment: Alignment.centerRight,
                child: Padding(
                  padding:
                      const EdgeInsets.only(right: 16),
                  child: CupertinoButton(
                    child: const Text('Done'),
                    onPressed: () =>
                        Navigator.of(context).pop(tempChoice),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );

    if (!mounted) return;

    // 1) Immediate local & theme update:
    setState(() => _localBannerChoice = result);
    Provider.of<ThemeNotifier>(context, listen: false)
        .setBannerChoice(result);

    // 2) Fire-and-forget server update:
    _userService
        .updateBannerChoice(uid, result)
        .catchError((err) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to save banner: $err')),
      );
    });
  }
}

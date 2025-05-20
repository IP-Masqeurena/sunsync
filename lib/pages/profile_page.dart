import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../services/user_service.dart';
import 'login_page.dart';
import 'edit_profile_page.dart';
import 'change_password_page.dart';
import 'view_detail_page.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({Key? key}) : super(key: key);

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  late final SupabaseClient _supabase;
  late final Stream<AuthState> _authStream;
  late final UserService _userService;

  @override
  void initState() {
    super.initState();
    _supabase = Supabase.instance.client;
    _authStream = _supabase.auth.onAuthStateChange;
    _userService = UserService();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      backgroundColor: Colors.grey[100],
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
                  color: Colors.black87,
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
          if (user == null) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text('Not logged in'),
                  const SizedBox(height: 24),
                  // Custom login button with gradient background
                  InkWell(
                    onTap: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(builder: (_) => const LoginPage()),
                      );
                    },
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
          }
          return StreamBuilder<List<Map<String, dynamic>>>(
            stream: _userService.detailsStream(user.id),
           builder: (context, dataSnap) {
          if (!dataSnap.hasData || dataSnap.data!.isEmpty) {
            return const Center(child: CircularProgressIndicator());
          }
          final data = dataSnap.data!.first;
          return _buildProfile(context, user.id, data);
          },
          );
        },
      ),
    );
  }

  Widget _buildProfile(BuildContext context, String uid, Map<String, dynamic> data) {
    final avatarUrl = data['avatar_url'] as String?;
    final bannerChoice = data['banner_choice'] as String?;
    final email = _supabase.auth.currentUser?.email ?? 'No email available';

    final topHeight = MediaQuery.of(context).padding.top + kToolbarHeight;
    final bannerHeight = 80 + topHeight;

    String? bannerAsset;
    switch (bannerChoice) {
      case 'nino':
        bannerAsset = 'lib/assets/banners/nino.jpg';
        break;
      case 'firefull_flyshine':
        bannerAsset = 'lib/assets/banners/firefull_flyshine.jpg';
        break;
      default:
        bannerAsset = null;
    }

    return SingleChildScrollView(
      child: Column(
        children: [
          Stack(
            alignment: Alignment.topCenter,
            children: [
             if (bannerAsset != null)
            Container(
              height: bannerHeight,
              width: double.infinity,
              decoration: BoxDecoration(
                image: DecorationImage(
                  image: AssetImage(bannerAsset),
                  fit: BoxFit.cover,
                  // Add color filter to darken the image
                  colorFilter: ColorFilter.mode(
                    Colors.black.withAlpha(150), // Adjust opacity to control darkness
                    BlendMode.darken, // Use darken blend mode
                  ),
                ),
              ),
            ),
              Padding(
                padding: EdgeInsets.only(top: topHeight -20),
                child: Column(
                  children: [
                    CircleAvatar(
                      radius: 67,
                      backgroundColor: Colors.white,
                      backgroundImage: avatarUrl != null
                          ? NetworkImage(avatarUrl)
                          : null,
                      child: avatarUrl == null
                          ? const Icon(Icons.person, size: 67, color: Colors.grey)
                          : null,
                    ),
                    const SizedBox(height: 32),
                    Text(
                      data['full_name'] ?? 'User Name',
                      style: const TextStyle(
                        fontSize: 38,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      data['is_undergrad'] == true ? 'Undergraduate' : 'Postgraduate',
                      style: TextStyle(fontSize: 16, color: Colors.grey[600]),
                    ),
                  ],
                ),
              ),
            ],
          ),

          Container(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                _buildInfoItem('Student ID', data['student_id'] ?? 'No ID'),
                const SizedBox(height: 4),
                _buildInfoItem('Mail', email),
                const SizedBox(height: 20),

               _buildSettingsItem(
                context,
                icon: Icons.person_outline,
                title: 'Profile details',
                onTap: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => ViewDetailPage(
                        data: data,
                        avatarUrl: avatarUrl,
                      ),
                    ),
                  );
                },
              ),

                _buildSettingsItem(
                  context,
                  icon: Icons.image,
                  title: 'Banner decorate',
                  onTap: () => _showBannerDecorate(context, uid, bannerChoice),
                ),

                _buildSettingsItem(
                  context,
                  icon: Icons.edit,
                  title: 'Edit Profile',
                  onTap: () => Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => EditProfilePage(uid: uid, existingData: data),
                    ),
                  ),
                ),

                _buildSettingsItem(
                  context,
                  icon: Icons.password,
                  title: 'Change Password',
                  onTap: () => Navigator.of(context)
                      .push(MaterialPageRoute(builder: (_) => const ChangePasswordPage())),
                ),

                _buildSettingsItem(
                  context,
                  icon: Icons.logout,
                  title: 'Log out',
                  onTap: () => _supabase.auth.signOut(),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoItem(String label, String value) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 12),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(label, style: TextStyle(fontSize: 16, color: Colors.grey[600])),
            Text(value, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500)),
          ],
        ),
      );

  Widget _buildSettingsItem(BuildContext context,
      {required IconData icon, required String title, required VoidCallback onTap}) =>
      InkWell(
        onTap: onTap,
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 12),
              child: Row(
                children: [
                  Icon(icon, color: Colors.black87),
                  const SizedBox(width: 16),
                  Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500)),
                  const Spacer(),
                  const Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey),
                ],
              ),
            ),
            const Divider(height: 1),
          ],
        ),
      );

  void _showDetailsSheet(BuildContext context, Map<String, dynamic> data) {
    // existing details sheet implementation
  }

  void _showBannerDecorate(BuildContext context, String uid, String? currentChoice) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) {
        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 12),
            const Text('Select Banner', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            ListTile(
              title: const Text('None'),
              leading: Radio<String?>(
                value: null,
                groupValue: currentChoice,
                onChanged: (_) {},
              ),
              onTap: () => _selectBanner(uid, null),
            ),
            ListTile(
              title: const Text('Nino'),
              leading: Radio<String?>(
                value: 'nino',
                groupValue: currentChoice,
                onChanged: (_) {},
              ),
              onTap: () => _selectBanner(uid, 'nino'),
            ),
            ListTile(
              title: const Text('Firefull Flyshine'),
              leading: Radio<String?>(
                value: 'firefull_flyshine',
                groupValue: currentChoice,
                onChanged: (_) {},
              ),
              onTap: () => _selectBanner(uid, 'firefull_flyshine'),
            ),
            const SizedBox(height: 12),
          ],
        );
      },
    );
  }

  Future<void> _selectBanner(String uid, String? choice) async {
    await _userService.updateBannerChoice(uid, choice);
    Navigator.of(context).pop();
  }
}

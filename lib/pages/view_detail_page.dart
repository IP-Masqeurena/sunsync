import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/theme_notifier.dart';

class ViewDetailPage extends StatelessWidget {
  final Map<String, dynamic> data;
  final String? avatarUrl;

  const ViewDetailPage({
    Key? key,
    required this.data,
    this.avatarUrl,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final fullName = data['full_name'] ?? 'User Name';
    final isUndergrad = data['is_undergrad'] == true;
    final subtitle = isUndergrad ? 'Undergraduate' : 'Postgraduate';
    final bannerChoice = data['banner_choice'] as String?;
    
    // Get banner asset based on choice
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

    final topPadding = MediaQuery.of(context).padding.top;
    final screenHeight = MediaQuery.of(context).size.height;

    return Scaffold(
      extendBodyBehindAppBar: true,
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          // Hero Header Section
          SliverAppBar(
            expandedHeight: screenHeight * 0.4,
            floating: false,
            pinned: false,
            stretch: true,
            backgroundColor: Colors.transparent,
            elevation: 0,
            leading: Padding(
              padding: const EdgeInsets.all(8.0),
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.3),
                  shape: BoxShape.circle,
                ),
                child: IconButton(
                  icon: const Icon(Icons.arrow_back, color: Colors.white),
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ),
            ),
            flexibleSpace: FlexibleSpaceBar(
              stretchModes: const [
                StretchMode.zoomBackground,
                // StretchMode.blurBackground,
              ],
              background: Stack(
                fit: StackFit.expand,
                children: [
                  // Banner Background
                  Container(
                    decoration: BoxDecoration(
                      gradient: bannerAsset == null
                          ? LinearGradient(
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                              colors: [
                                Theme.of(context).primaryColor.withOpacity(0.8),
                                Theme.of(context).primaryColor,
                              ],
                            )
                          : null,
                      image: bannerAsset != null
                          ? DecorationImage(
                              image: AssetImage(bannerAsset),
                              fit: BoxFit.cover,
                              colorFilter: ColorFilter.mode(
                                Colors.black.withOpacity(0.7),
                                BlendMode.darken,
                              ),
                            )
                          : null,
                    ),
                  ),
                  // Gradient Overlay
                  Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.transparent,
                          Colors.black.withOpacity(0.3),
                        ],
                      ),
                    ),
                  ),
                  // Content
                  Positioned(
                    bottom: 60,
                    left: 0,
                    right: 0,
                    child: Column(
                      children: [
                        // Avatar with glow effect
                        Container(
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: Colors.white.withOpacity(0.3),
                                blurRadius: 20,
                                spreadRadius: 5,
                              ),
                            ],
                          ),
                          child: CircleAvatar(
                            radius: 65,
                            backgroundColor: Colors.white,
                            child: CircleAvatar(
                              radius: 62,
                              backgroundColor: Theme.of(context).colorScheme.surface,
                              backgroundImage:
                                  avatarUrl != null ? NetworkImage(avatarUrl!) : null,
                              child: avatarUrl == null
                                  ? Icon(Icons.person,
                                      size: 65, color: Colors.grey[400])
                                  : null,
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),
                        // Name with shadow
                        Text(
                          fullName,
                          style: TextStyle(
                            fontSize: 32,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                            shadows: [
                              Shadow(
                                color: Colors.black.withOpacity(0.5),
                                offset: const Offset(0, 2),
                                blurRadius: 4,
                              ),
                            ],
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 8),
                        // Subtitle with badge
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: Colors.white.withOpacity(0.3),
                              width: 1,
                            ),
                          ),
                          child: Text(
                            subtitle,
                            style: const TextStyle(
                              fontSize: 16,
                              color: Colors.white,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          // Detail Cards Section
          SliverToBoxAdapter(
            child: Container(
              decoration: BoxDecoration(
                color: Theme.of(context).scaffoldBackgroundColor,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(30),
                  topRight: Radius.circular(30),
                ),
              ),
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 30, 20, 40),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Section Title
                    Row(
                      children: [
                        Container(
                          width: 4,
                          height: 24,
                          decoration: BoxDecoration(
                            color: Theme.of(context).primaryColor,
                            borderRadius: BorderRadius.circular(2),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Text(
                          'Profile Details',
                          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                                fontWeight: FontWeight.bold,
                                fontSize: 24,
                              ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
                    // Detail Cards
                    ...data.entries
                        .where((e) => e.key != 'avatar_url' && e.key != 'banner_choice')
                        .map((entry) {
                      final key = _prettyKey(entry.key);
                      final value = entry.value?.toString() ?? '-';
                      final icon = _getIconForKey(entry.key);
                      
                      return Container(
                        margin: const EdgeInsets.only(bottom: 16),
                        decoration: BoxDecoration(
                          color: Theme.of(context).cardColor,
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.05),
                              blurRadius: 10,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(20),
                          child: Row(
                            children: [
                              // Icon Container
                              Container(
                                width: 48,
                                height: 48,
                                decoration: BoxDecoration(
                                  color: Theme.of(context).primaryColor.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Icon(
                                  icon,
                                  color: Theme.of(context).brightness == Brightness.dark
                                      ? Colors.white
                                      : Theme.of(context).primaryColor,
                                  size: 24,
                                ),
                              ),
                              const SizedBox(width: 16),
                              // Content
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      key,
                                      style: const TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w500,
                                        color: Colors.grey,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      value,
                                      style: const TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    }).toList(),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  IconData _getIconForKey(String key) {
    switch (key) {
      case 'full_name':
        return Icons.person_outline;
      case 'student_id':
        return Icons.badge_outlined;
      case 'age':
        return Icons.cake_outlined;
      case 'grad_year':
        return Icons.school_outlined;
      case 'course':
        return Icons.menu_book_outlined;
      case 'job_sector':
        return Icons.business_outlined;
      case 'occupation':
        return Icons.work_outline;
      case 'year_first_job':
        return Icons.work_history_outlined;
      case 'times_switched_jobs':
        return Icons.swap_horiz_outlined;
      case 'work_overseas':
        return Icons.public_outlined;
      case 'work_mode':
        return Icons.computer_outlined;
      case 'is_undergrad':
        return Icons.school;
      case 'email':
        return Icons.email_outlined;
      default:
        return Icons.info_outline;
    }
  }

  String _prettyKey(String key) {
    switch (key) {
      case 'full_name':
        return 'Full Name';
      case 'student_id':
        return 'Student ID';
      case 'age':
        return 'Age';
      case 'grad_year':
        return 'Year of Graduation';
      case 'course':
        return 'Course';
      case 'job_sector':
        return 'Job Sector';
      case 'occupation':
        return 'Occupation';
      case 'year_first_job':
        return 'Year of First Job';
      case 'times_switched_jobs':
        return 'Times Switched Jobs';
      case 'work_overseas':
        return 'Worked Overseas';
      case 'work_mode':
        return 'Work Mode';
      case 'is_undergrad':
        return 'Undergraduate';
      default:
        return key
            .replaceAll('_', ' ')
            .split(' ')
            .map((word) => word.isNotEmpty 
                ? word[0].toUpperCase() + word.substring(1).toLowerCase() 
                : word)
            .join(' ');
    }
  }
}
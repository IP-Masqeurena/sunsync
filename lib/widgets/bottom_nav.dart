import 'package:flutter/material.dart';
import '../pages/chat.dart';
import '../pages/home_page.dart';
import '../pages/profile_page.dart';

class BottomNav extends StatefulWidget {
  const BottomNav({Key? key}) : super(key: key);
  
  @override 
  State<BottomNav> createState() => _BottomNavState();
}

class _BottomNavState extends State<BottomNav> with TickerProviderStateMixin {
  int idx = 0;
  late AnimationController _animationController;
  late List<Animation<double>> _scaleAnimations;
  
  final pages = <Widget>[
    const HomePage(key: PageStorageKey('home')),
    const ChatPage(key: PageStorageKey('chat')),
    const ProfilePage(key: PageStorageKey('profile')),
  ];

  @override
  void initState() {
    super.initState();
    
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 250),
      vsync: this,
    );
    
    _scaleAnimations = List.generate(3, (index) {
      return Tween<double>(
        begin: index == 0 ? 1.0 : 0.0,
        end: index == 0 ? 1.0 : 0.0,
      ).animate(CurvedAnimation(
        parent: _animationController,
        curve: Curves.easeInOut,
      ));
    });
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  void _onItemTapped(int index) {
    if (index == idx) return;
    
    for (int i = 0; i < _scaleAnimations.length; i++) {
      _scaleAnimations[i] = Tween<double>(
        begin: i == idx ? 1.0 : 0.0,
        end: i == index ? 1.0 : 0.0,
      ).animate(CurvedAnimation(
        parent: _animationController,
        curve: Curves.easeInOut,
      ));
    }
    
    setState(() => idx = index);
    _animationController.reset();
    _animationController.forward();
  }

  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.of(context).size;
    final iconSize = screenSize.height * 0.025;
    final fontSize = screenSize.height * 0.016;
    
    return Scaffold(
      body: IndexedStack(
        index: idx,
        children: pages,
      ),
      bottomNavigationBar: SafeArea(
        child: _buildBottomNavigationBar(iconSize, fontSize),
      ),
    );
  }

  Widget _buildBottomNavigationBar(double iconSize, double fontSize) {
    return Container(
      padding: EdgeInsets.symmetric(vertical: MediaQuery.of(context).size.height * 0.008),
      decoration: BoxDecoration(
        color: Theme.of(context).bottomNavigationBarTheme.backgroundColor ?? 
              Theme.of(context).colorScheme.background,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(20),
            blurRadius: 10,
            offset: const Offset(0, -5),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: List.generate(3, (index) => _buildNavItem(index, iconSize, fontSize)),
      ),
    );
  }

Widget _buildNavItem(int index, double iconSize, double fontSize) {
  final primary = Theme.of(context).colorScheme.primary;
  final screenWidth = MediaQuery.of(context).size.width;
  
  return Expanded(
    child: Container(
      height: screenWidth * 0.12,
      margin: EdgeInsets.symmetric(horizontal: screenWidth * 0.02),
      child: GestureDetector(
        onTap: () => _onItemTapped(index),
        behavior: HitTestBehavior.opaque,
        child: AnimatedBuilder(
          animation: _animationController,
          builder: (context, child) {
            double scale = _scaleAnimations[index].value;
            double bubbleScale = scale * 1.0;
            
            // Add clamp to ensure valid opacity values
            double textOpacity = ((scale - 0.2) / 0.8).clamp(0.0, 1.0);
            
            return Container(
              height: screenWidth * 0.12,
              margin: EdgeInsets.symmetric(vertical: screenWidth * 0.005),
              child: Stack(
                alignment: Alignment.center,
                children: [
                  Transform.scale(
                    scale: bubbleScale,
                    child: Container(
                      height: screenWidth * 0.12,
                      decoration: BoxDecoration(
                        color: Color.lerp(Colors.transparent, primary.withOpacity(0.1), scale),
                        borderRadius: BorderRadius.circular(screenWidth * 0.05),
                        boxShadow: scale > 0.3 ? [
                          BoxShadow(
                            color: Colors.blue.withOpacity(0.2 * scale),
                            blurRadius: 8 * scale,
                            offset: const Offset(0, 2),
                          ),
                        ] : null,
                      ),
                    ),
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Icon(
                        index == 0 ? Icons.home :
                        index == 1 ? Icons.bar_chart : Icons.person,
                        size: iconSize * (1 + 0.3 * scale),
                        color: Color.lerp(Colors.grey, primary, scale),
                      ),
                      SizedBox(
                        width: scale * (screenWidth * 0.15),
                        height: screenWidth * 0.05, // Restore fixed height
                        child: ClipRect(
                          child: Align(
                            alignment: Alignment.centerLeft,
                            child: scale > 0.2 ? Padding(
                              padding: EdgeInsets.only(left: screenWidth * 0.02),
                              child: Opacity(
                                opacity: textOpacity,
                                child: Text(
                                  index == 0 ? 'Home' : index == 1 ? 'Chat' : 'Profile',
                                  style: TextStyle(
                                    color: primary,
                                    fontSize: fontSize, // Use original font size
                                    height: 1.2
                                  ),
                                  textAlign: TextAlign.center,
                                  overflow: TextOverflow.clip, // Original overflow
                                ),
                              ),
                            ) : const SizedBox.shrink(),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            );
          },
        ),
      ),
    ),
  );
}
}
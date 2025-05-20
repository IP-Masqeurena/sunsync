import 'package:flutter/material.dart';

import '../pages/home_page.dart';
import '../pages/stats_page.dart';
import '../pages/profile_page.dart';


class BottomNav extends StatefulWidget {
  const BottomNav({super.key});
  @override State<BottomNav> createState() => _BNState();
}
class _BNState extends State<BottomNav> {
  int idx = 0;
  final pages = [const HomePage(), const StatsPage(), const ProfilePage()];
  @override Widget build(BuildContext c) => Scaffold(
    body: pages[idx],
    bottomNavigationBar: BottomNavigationBar(
      currentIndex: idx,
      onTap: (i)=> setState(()=> idx=i),
      items: const [
        BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
        BottomNavigationBarItem(icon: Icon(Icons.bar_chart), label: 'Stats'),
        BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Profile'),
      ],
    ),
  );
}
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:salomon_bottom_bar/salomon_bottom_bar.dart';

import 'package:whispr_app/screens/feed_screen.dart';
import 'package:whispr_app/screens/map_screen.dart';
import 'package:whispr_app/screens/post_confesion_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedIndex = 0;

  final GlobalKey<FeedScreenState> feedScreenKey = GlobalKey<FeedScreenState>();

  final List<String> _appBarTitles = [
    'Confessions',
    'Nearby Confessions',
    'Post Confession',
    'Notifications',
    'Profile',
  ];

  @override
  Widget build(BuildContext context) {
    final List<Widget> _screens = [
      FeedScreen(key: feedScreenKey),
      MapScreen(),
      PostConfessionScreen(
        onPostSuccess: () {
          setState(() {
            _selectedIndex = 0; // navigate to FeedScreen tab
          });
          feedScreenKey.currentState?.fetchConfessions();
        },
      ),
      NotificationsScreen(),
      ProfileScreen(),
    ];

    return Scaffold(
      appBar: AppBar(
        title: Text(
          _appBarTitles[_selectedIndex],
          style: GoogleFonts.inter(fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
      ),
      body: IndexedStack(index: _selectedIndex, children: _screens),
      bottomNavigationBar: SalomonBottomBar(
        currentIndex: _selectedIndex,
        onTap: (index) {
          setState(() {
            _selectedIndex = index;
          });

          if (index == 0) {
            feedScreenKey.currentState?.fetchConfessions();
          }
        },
        selectedItemColor: const Color(0xFF6C5CE7),
        unselectedItemColor: Colors.grey,
        items: [
          SalomonBottomBarItem(
            icon: const Icon(Icons.home_filled),
            title: Container(),
            selectedColor: const Color(0xFF6C5CE7),
          ),
          SalomonBottomBarItem(
            icon: const Icon(Icons.map_outlined),
            title: Container(),
            selectedColor: const Color(0xFF6C5CE7),
          ),
          SalomonBottomBarItem(
            icon: const Icon(
              Icons.add_circle,
              size: 36,
              color: Color(0xFFFF6B81),
            ),
            title: Container(),
            selectedColor: const Color(0xFFFF6B81),
          ),
          SalomonBottomBarItem(
            icon: const Icon(Icons.notifications),
            title: Container(),
            selectedColor: const Color(0xFF6C5CE7),
          ),
          SalomonBottomBarItem(
            icon: const Icon(Icons.person),
            title: Container(),
            selectedColor: const Color(0xFF6C5CE7),
          ),
        ],
      ),
    );
  }
}

// Dummy NotificationsScreen & ProfileScreen for completeness
class NotificationsScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Text(
        'No notifications yet.',
        style: GoogleFonts.inter(fontSize: 16, color: Colors.grey),
      ),
    );
  }
}

class ProfileScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Text('Profile Screen', style: GoogleFonts.inter(fontSize: 16)),
    );
  }
}

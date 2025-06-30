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

  final List<String> _appBarTitles = [
    'Confessions',
    'Nearby Confessions',
    'Post Confession',
    'Notifications',
    'Profile',
  ];

  final List<Widget> _screens = [
    FeedScreen(),
    MapScreen(),
    PostConfessionScreen(),
    NotificationsScreen(),
    ProfileScreen(),
  ];

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
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
        onTap: _onItemTapped,
        selectedItemColor: Color(0xFF6C5CE7),
        unselectedItemColor: Colors.grey,
        items: [
          SalomonBottomBarItem(
            icon: Icon(Icons.home_filled),
            title: Container(), // no title
            selectedColor: Color(0xFF6C5CE7),
          ),
          SalomonBottomBarItem(
            icon: Icon(Icons.map_outlined),
            title: Container(),
            selectedColor: Color(0xFF6C5CE7),
          ),
          SalomonBottomBarItem(
            icon: Icon(Icons.add_circle, size: 36, color: Color(0xFFFF6B81)),
            title: Container(),
            selectedColor: Color(0xFFFF6B81),
          ),
          SalomonBottomBarItem(
            icon: Icon(Icons.notifications),
            title: Container(),
            selectedColor: Color(0xFF6C5CE7),
          ),
          SalomonBottomBarItem(
            icon: Icon(Icons.person),
            title: Container(),
            selectedColor: Color(0xFF6C5CE7),
          ),
        ],
      ),
    );
  }
}

// NotificationsScreen Widget
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

// ProfileScreen Widget
class ProfileScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Text('Profile Screen', style: GoogleFonts.inter(fontSize: 16)),
    );
  }
}

// ConfessionCard Widget
class ConfessionCard extends StatelessWidget {
  final String category;
  final String text;
  final String timeAgo;
  final int upvotes;

  const ConfessionCard({
    super.key,
    required this.category,
    required this.text,
    required this.timeAgo,
    required this.upvotes,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      elevation: 2,
      margin: EdgeInsets.only(bottom: 16),
      child: Padding(
        padding: EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Color(0xFF6C5CE7),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    category,
                    style: GoogleFonts.inter(color: Colors.white, fontSize: 12),
                  ),
                ),
                Spacer(),
                Text(
                  timeAgo,
                  style: GoogleFonts.inter(color: Colors.grey, fontSize: 12),
                ),
              ],
            ),
            SizedBox(height: 8),
            Text(
              text,
              style: GoogleFonts.inter(fontSize: 14),
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
            ),
            SizedBox(height: 12),
            Row(
              children: [
                Icon(Icons.arrow_upward, size: 20, color: Colors.grey),
                SizedBox(width: 4),
                Text('$upvotes', style: GoogleFonts.inter(fontSize: 14)),
                Spacer(),
                Row(
                  children: [
                    Text('😂', style: TextStyle(fontSize: 16)),
                    SizedBox(width: 8),
                    Text('❤️', style: TextStyle(fontSize: 16)),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

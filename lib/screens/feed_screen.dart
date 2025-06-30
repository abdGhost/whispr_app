import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:whispr_app/helper/format_timestamp.dart';
import 'package:whispr_app/models/confession_model.dart';
import '../api/api_services.dart';
import '../widgets/confession_card.dart';

class FeedScreen extends StatefulWidget {
  const FeedScreen({super.key});

  @override
  State<FeedScreen> createState() => _FeedScreenState();
}

class _FeedScreenState extends State<FeedScreen> {
  int _selectedTabIndex = 0;
  final List<String> _tabs = ['All', 'Funny', 'Sad', 'Love', 'Work', 'Other'];

  late Future<List<Confession>> _confessionsFuture;

  @override
  void initState() {
    super.initState();
    _confessionsFuture = ApiServices().getAllConfession();
  }

  void _onTabSelected(int index) {
    setState(() {
      _selectedTabIndex = index;
      final selectedTab = _tabs[index];
      if (selectedTab == 'All') {
        _confessionsFuture = ApiServices().getAllConfession();
      } else {
        _confessionsFuture = ApiServices().getConfessionByCategory(
          capitalize(selectedTab),
        );
      }
    });
  }

  String capitalize(String s) => s[0].toUpperCase() + s.substring(1);

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.grey[100], // light background for feed
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Top Tabs
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 12),
            child: Row(
              children: _tabs.asMap().entries.map((entry) {
                int idx = entry.key;
                String tab = entry.value;
                final isSelected = _selectedTabIndex == idx;
                return GestureDetector(
                  onTap: () => _onTabSelected(idx),
                  child: Container(
                    margin: const EdgeInsets.only(right: 4),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? const Color(0xFF6C5CE7)
                          : Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: isSelected
                            ? const Color(0xFF6C5CE7)
                            : Colors.grey[300]!,
                      ),
                    ),
                    child: Text(
                      tab,
                      style: GoogleFonts.inter(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: isSelected ? Colors.white : Colors.black,
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
          ),

          // Feed List
          Expanded(
            child: FutureBuilder<List<Confession>>(
              future: _confessionsFuture,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                } else if (snapshot.hasError) {
                  return Center(
                    child: Text(
                      'Error: ${snapshot.error}',
                      style: GoogleFonts.inter(),
                    ),
                  );
                } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
                  return Center(
                    child: Text(
                      'No confessions found',
                      style: GoogleFonts.inter(),
                    ),
                  );
                } else {
                  final confessions = snapshot.data!;
                  return ListView.builder(
                    padding: EdgeInsets.zero, // no extra side padding
                    itemCount: confessions.length,
                    itemBuilder: (context, index) {
                      final c = confessions[index];
                      return Container(
                        margin: const EdgeInsets.symmetric(
                          vertical: 6,
                          horizontal: 0,
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 4),
                        color: Colors.white, // card background
                        child: ConfessionCard(
                          username: c.username,
                          timeAgo: formatTimestamp(c.timestamp),
                          location: c.address,
                          confession: c.text,
                          upvotes: c.upvotes,
                          comments: c.commentsCount,
                          reactionCounts:
                              c.reactions, // LinkedIn-style reactions
                        ),
                      );
                    },
                  );
                }
              },
            ),
          ),
        ],
      ),
    );
  }
}

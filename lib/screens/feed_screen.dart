import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:whispr_app/api/api_services.dart';
import 'package:whispr_app/helper/format_timestamp.dart';
import 'package:whispr_app/models/confession_model.dart';

import 'package:http/http.dart' as http;
import 'package:whispr_app/widgets/confession_card.dart';

class FeedScreen extends StatefulWidget {
  const FeedScreen({super.key});

  @override
  State<FeedScreen> createState() => _FeedScreenState();
}

class _FeedScreenState extends State<FeedScreen> {
  int selectedTabIndex = 0;
  List<String> tabs = ['All'];
  late Future<List<Confession>> confessionsFuture;
  String userId = '';

  @override
  void initState() {
    super.initState();
    _loadUserId();
    _fetchCategories();
    confessionsFuture = ApiServices().getAllConfession(userId);
  }

  Future<void> _loadUserId() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    setState(() {
      userId = prefs.getString('userId') ?? '';
    });
  }

  Future<void> _fetchCategories() async {
    try {
      final response = await http.get(
        Uri.parse(
          'https://whisper-2nhg.onrender.com/api/confession-categories',
        ),
      );
      if (response.statusCode == 200) {
        final List data = json.decode(response.body);
        setState(() {
          tabs = ['All'] + data.map((e) => e['name'].toString()).toList();
        });
      } else {
        throw Exception('Failed to load categories');
      }
    } catch (e) {
      print('Error fetching categories: $e');
    }
  }

  void _onTabSelected(int index) {
    setState(() {
      selectedTabIndex = index;
      final selectedTab = tabs[index];

      if (selectedTab == 'All') {
        confessionsFuture = ApiServices().getAllConfession(userId);
      } else {
        confessionsFuture = ApiServices().getConfessionByCategory(
          capitalize(selectedTab),
          userId,
        );
      }
    });
  }

  String capitalize(String s) => s[0].toUpperCase() + s.substring(1);

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.grey[100],
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 12),
            child: Row(
              children: tabs.asMap().entries.map((entry) {
                int idx = entry.key;
                String tab = entry.value;
                final isSelected = selectedTabIndex == idx;

                return GestureDetector(
                  onTap: () => _onTabSelected(idx),
                  child: Container(
                    margin: EdgeInsets.only(right: 4),
                    padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    decoration: BoxDecoration(
                      color: isSelected ? Color(0xFF6C5CE7) : Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: isSelected
                            ? Color(0xFF6C5CE7)
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

          // FEED List
          Expanded(
            child: FutureBuilder(
              future: confessionsFuture,
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
                      'No Confessions Found',
                      style: GoogleFonts.inter(),
                    ),
                  );
                } else {
                  final confession = snapshot.data!;

                  return ListView.builder(
                    itemBuilder: (context, index) {
                      final c = confession[index];
                      return Container(
                        margin: const EdgeInsets.symmetric(vertical: 8),
                        child: ConfessionCard(
                          username: c.username,
                          timeAgo: formatTimestamp(c.timestamp),
                          location: c.address,
                          confession: c.text,
                          upvotes: c.upvotes,
                          comments: c.commentsCount,
                          reactionCounts: c.reactions,
                          confessionId: c.id,
                          userId: userId,
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

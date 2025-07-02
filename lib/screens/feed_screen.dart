import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;

import 'package:whispr_app/api/api_services.dart';
import 'package:whispr_app/helper/format_timestamp.dart';
import 'package:whispr_app/models/confession_model.dart';
import 'package:whispr_app/widgets/confession_card.dart';

class Category {
  final String id;
  final String name;

  Category({required this.id, required this.name});

  factory Category.fromJson(Map<String, dynamic> json) {
    return Category(id: json['_id'], name: json['name']);
  }
}

class FeedScreen extends StatefulWidget {
  const FeedScreen({super.key});

  @override
  State<FeedScreen> createState() => FeedScreenState();
}

class FeedScreenState extends State<FeedScreen> {
  int selectedTabIndex = 0;
  List<Category> categories = [];
  Future<List<Confession>>? confessionsFuture;
  String userId = '';

  @override
  void initState() {
    super.initState();
    _initialize();
  }

  Future<void> _initialize() async {
    await _loadUserId();
    await _fetchCategories();
    fetchConfessions(); // initial load for 'All'
  }

  Future<void> _loadUserId() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    userId = prefs.getString('userId') ?? '';
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
          categories = [
            Category(id: 'all', name: 'All'),
            ...data.map((e) => Category.fromJson(e)).toList(),
          ];
        });
      } else {
        print('Failed to load categories');
      }
    } catch (e) {
      print('Error fetching categories: $e');
    }
  }

  /// Public method to refresh confessions externally
  void fetchConfessions({String? categoryId}) {
    setState(() {
      if (categoryId == null || categoryId == 'all') {
        confessionsFuture = ApiServices().getAllConfession(userId);
      } else {
        confessionsFuture = ApiServices().getConfessionByCategory(
          categoryId: categoryId,
          userId: userId,
        );
      }
    });
  }

  void _onTabSelected(int index) {
    setState(() {
      selectedTabIndex = index;
    });
    final selectedCategory = categories[index];
    fetchConfessions(categoryId: selectedCategory.id);
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.grey[100],
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Tabs
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 12),
            child: Row(
              children: categories.asMap().entries.map((entry) {
                int idx = entry.key;
                Category category = entry.value;
                bool isSelected = selectedTabIndex == idx;

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
                      category.name,
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
            child: confessionsFuture == null
                ? const Center(child: CircularProgressIndicator())
                : FutureBuilder<List<Confession>>(
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
                        final confessionList = snapshot.data!;
                        return ListView.builder(
                          itemCount: confessionList.length,
                          itemBuilder: (context, index) {
                            final c = confessionList[index];
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

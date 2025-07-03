import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:socket_io_client/socket_io_client.dart' as IO;

import 'package:whispr_app/api/api_services.dart';
import 'package:whispr_app/helper/format_timestamp.dart';
import 'package:whispr_app/models/confession_model.dart';
import 'package:whispr_app/screens/post_confesion_screen.dart';
import 'package:whispr_app/widgets/confession_card.dart';

class FeedScreen extends StatefulWidget {
  final List<Category> categories;

  const FeedScreen({super.key, required this.categories});

  @override
  State<FeedScreen> createState() => FeedScreenState();
}

class FeedScreenState extends State<FeedScreen> {
  int selectedTabIndex = 0;
  List<Confession> confessions = [];
  String userId = '';

  late IO.Socket socket;
  bool isLoading = true; // 🔥 loading state

  @override
  void initState() {
    super.initState();
    _initialize();
    _connectSocket();
  }

  @override
  void dispose() {
    socket.dispose();
    super.dispose();
  }

  Future<void> _initialize() async {
    print('🚀 Initializing FeedScreen...');
    await _loadUserId();
    await fetchConfessions(); // Initial load for 'All'
  }

  Future<void> _loadUserId() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    userId = prefs.getString('userId') ?? '';
    print('🔑 Loaded userId: $userId');
  }

  Future<void> fetchConfessions({String? categoryId}) async {
    setState(() {
      isLoading = true; // start loading
    });

    final selectedId = categoryId ?? widget.categories[selectedTabIndex].id;
    List<Confession> result;

    try {
      if (selectedId == 'all') {
        result = await ApiServices().getAllConfession(userId);
      } else {
        result = await ApiServices().getConfessionByCategory(
          categoryId: selectedId,
          userId: userId,
        );
      }

      setState(() {
        confessions = result;
        isLoading = false; // loading done
      });
    } catch (e) {
      print('❌ Error fetching confessions: $e');
      setState(() {
        isLoading = false;
      });
    }
  }

  void _connectSocket() {
    print('🌐 Connecting to WebSocket...');
    socket = IO.io(
      'https://whisper-2nhg.onrender.com',
      IO.OptionBuilder()
          .setTransports(['websocket'])
          .disableAutoConnect()
          .build(),
    );

    socket.connect();

    socket.onConnect((_) {
      print('✅ Connected to WebSocket');

      final initialCategoryId = widget.categories[selectedTabIndex].id;
      if (initialCategoryId != 'all') {
        socket.emit('joinConfessionCategory', {
          'categoryId': initialCategoryId,
        });
        print('👉 Joined category: $initialCategoryId');
      }
    });

    socket.on('newConfession', (data) {
      print('🆕 New Confession Received raw: $data');

      try {
        final newConfession = Confession.fromJson(data);

        final currentCategoryId = widget.categories[selectedTabIndex].id;
        if (currentCategoryId == 'all' ||
            newConfession.categoryId == currentCategoryId) {
          setState(() {
            confessions.insert(0, newConfession);
          });
        } else {}
      } catch (e) {
        print('❌ Error parsing new confession: $e');
      }
    });

    socket.onDisconnect((_) => print('❌ Socket disconnected'));
    socket.onError((err) => print('⚠️ Socket error: $err'));
  }

  void _onTabSelected(int index) async {
    final prevCategoryId = widget.categories[selectedTabIndex].id;
    final newCategoryId = widget.categories[index].id;

    print(
      '🔁 Switching tab from category $prevCategoryId to category $newCategoryId',
    );

    setState(() {
      selectedTabIndex = index;
    });

    // Leave previous room if not 'All'
    if (prevCategoryId != 'all') {
      socket.emit('leaveConfessionCategory', {'categoryId': prevCategoryId});
    }

    // Join new room if not 'All'
    if (newCategoryId != 'all') {
      socket.emit('joinConfessionCategory', {'categoryId': newCategoryId});
      print('👉 Joined category: $newCategoryId');
    }

    await fetchConfessions(categoryId: newCategoryId);
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
              children: widget.categories.asMap().entries.map((entry) {
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
            child: isLoading
                ? const Center(child: CircularProgressIndicator())
                : confessions.isEmpty
                ? Center(
                    child: Text(
                      'No Confessions Found',
                      style: GoogleFonts.inter(),
                    ),
                  )
                : ListView.builder(
                    itemCount: confessions.length,
                    itemBuilder: (context, index) {
                      final c = confessions[index];
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
                  ),
          ),
        ],
      ),
    );
  }
}

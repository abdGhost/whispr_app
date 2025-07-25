import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:socket_io_client/socket_io_client.dart' as IO;
import 'package:whispr_app/api/api_services.dart';

import 'package:whispr_app/helper/format_timestamp.dart';
import 'package:whispr_app/models/confession_model.dart';
import 'package:whispr_app/provider/socket_provider.dart';
import 'package:whispr_app/screens/post_confesion_screen.dart';
import 'package:whispr_app/theme/app_colors.dart';
import 'package:whispr_app/widgets/confession_card.dart';

class FeedScreen extends ConsumerStatefulWidget {
  final List<Category> categories;

  const FeedScreen({super.key, required this.categories});

  @override
  ConsumerState<FeedScreen> createState() => FeedScreenState();
}

class FeedScreenState extends ConsumerState<FeedScreen> {
  int selectedTabIndex = 0;
  List<Confession> confessions = [];
  String userId = '';

  bool isLoading = true;

  Set<String> newConfessionIds = {};

  @override
  void initState() {
    super.initState();
    _initialize();
  }

  @override
  void dispose() {
    final socket = ref.read(socketProvider);
    socket.off('confessionAdded'); // clean up listener
    super.dispose();
  }

  Future<void> _initialize() async {
    print('🚀 Initializing FeedScreen...');
    await _loadUserId();
    await fetchConfessions();

    final socket = ref.read(socketProvider);
    _setupSocketListeners(socket);
  }

  Future<void> _loadUserId() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    userId = prefs.getString('userId') ?? '';
    print('🔑 Loaded userId: $userId');
  }

  Future<void> fetchConfessions({String? categoryId}) async {
    setState(() {
      isLoading = true;
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
        isLoading = false;
      });
    } catch (e) {
      print('❌ Error fetching confessions: $e');
      setState(() {
        isLoading = false;
      });
    }
  }

  void _setupSocketListeners(IO.Socket socket) {
    socket.onConnect((_) {
      final initialCategoryId = widget.categories[selectedTabIndex].id;
      print(initialCategoryId);

      if (initialCategoryId != 'all') {
        socket.emit('joinConfessionCategory', {
          'categoryId': initialCategoryId,
        });
      } else {
        print('🟢 Connected to ALL tab, no join needed');
      }
    });

    socket.on('confessionAdded', (data) {
      print('Confession Data---------------');
      _handleNewConfession(data, source: 'confessionAdded');
    });

    socket.on('newConfession', (data) {
      print('🔥 Received newConfession event: $data');
      _handleNewConfession(data, source: 'newConfession');
    });

    socket.on('confessionReactionUpdated', (data) {
      print('Inside Confession----------------');
      print(data);

      if (data['userId'] == userId) {
        print('Skipping own confessionReactionUpdated to avoid duplicate');
        return;
      }

      _updateConfessionReaction(data);
    });

    socket.on('broadcastConfessionReactionUpdated', (data) {
      print('Inside here broadcast----------------');
      print(data);

      final currentCategoryId = widget.categories[selectedTabIndex].id;

      if (currentCategoryId != 'all') {
        print(
          'Skipping broadcastConfessionReactionUpdated because inside category tab: $currentCategoryId',
        );
        return;
      }

      _updateConfessionReaction(data);
    });

    // Working on this Socket
    socket.on('confessionCommentAdded', (data) {
      print('Confession Comment Added--------------- $data');
      print('Hererererrererererererre');
      final confessionId = data['confessionId'];
      final action = data['action'];

      if (action == 'ADDED') {
        final index = confessions.indexWhere((c) => c.id == confessionId);
        if (index != -1) {
          setState(() {
            confessions[index].commentsCount += 1;
            confessions = List.from(confessions);
          });
        }
      }
    });
  }

  void _updateConfessionReaction(dynamic data) {
    final confessionId = data['confessionId'];
    final emoji = data['emoji'];
    final oldEmoji = data['oldEmoji'];
    final action = data['action'];

    final index = confessions.indexWhere((c) => c.id == confessionId);
    if (index != -1) {
      setState(() {
        final confession = confessions[index];

        if (action == 'UPDATED') {
          // Remove old emoji count
          if (oldEmoji != null && oldEmoji.isNotEmpty) {
            confession.reactions.update(
              oldEmoji,
              (value) => (value - 1).clamp(0, double.infinity).toInt(),
              ifAbsent: () => 0,
            );
          }

          // Add new emoji count
          if (emoji != null && emoji.isNotEmpty) {
            confession.reactions.update(
              emoji,
              (value) => value + 1,
              ifAbsent: () => 1,
            );
          }
        } else if (action == 'ADDED') {
          // Simply increment emoji count
          if (emoji != null && emoji.isNotEmpty) {
            confession.reactions.update(
              emoji,
              (value) => value + 1,
              ifAbsent: () => 1,
            );
          }
        } else if (action == 'REMOVED') {
          // Decrement emoji count
          if (emoji != null && emoji.isNotEmpty) {
            confession.reactions.update(
              emoji,
              (value) => (value - 1).clamp(0, double.infinity).toInt(),
              ifAbsent: () => 0,
            );
          }
        }

        // ✅ Replace with new map to trigger rebuild
        confession.reactions = Map<String, int>.from(confession.reactions);
      });
    }
  }

  void _handleNewConfession(dynamic data, {required String source}) {
    try {
      final newConfession = Confession.fromJson(data);
      final currentCategoryId = widget.categories[selectedTabIndex].id;

      if (source == 'newConfession' && currentCategoryId != 'all') {
        return;
      }

      if (currentCategoryId == 'all' ||
          newConfession.categoryId == currentCategoryId) {
        setState(() {
          confessions.insert(0, newConfession);
          newConfessionIds.add(newConfession.id);
        });

        Future.delayed(Duration(seconds: 3), () {
          if (mounted) {
            setState(() {
              newConfessionIds.remove(newConfession.id);
            });
          }
        });
      }
    } catch (e) {
      print('❌ Error parsing new confession: $e');
    }
  }

  void _onTabSelected(int index) async {
    final socket = ref.read(socketProvider);

    final prevCategoryId = widget.categories[selectedTabIndex].id;
    final newCategoryId = widget.categories[index].id;

    setState(() => selectedTabIndex = index);

    if (prevCategoryId != 'all') {
      socket.emit('leaveConfessionCategory', {'categoryId': prevCategoryId});
    }

    if (newCategoryId != 'all') {
      socket.emit('joinConfessionCategory', {'categoryId': newCategoryId});
    }

    await fetchConfessions(categoryId: newCategoryId);
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppColors.backgroundGrey,
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
                      color: isSelected ? AppColors.primaryColor : Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: isSelected
                            ? AppColors.primaryColor
                            : AppColors.tabBorderGrey,
                      ),
                    ),
                    child: Text(
                      category.name,
                      style: GoogleFonts.inter(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: isSelected ? AppColors.white : AppColors.black,
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
                          isReact: c.isReact,
                          categoryId: c.categoryId,
                          isNew: newConfessionIds.contains(
                            c.id,
                          ), // ✅ pass isNew
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

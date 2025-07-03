import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

import 'package:whispr_app/widgets/show_comments_modal.dart';

class ConfessionCard extends StatefulWidget {
  final String confessionId;
  final String userId;
  final String username;
  final String timeAgo;
  final String location;
  final String confession;
  final int upvotes;
  final int comments;
  final Map<String, int>? reactionCounts;
  final bool isReact;

  const ConfessionCard({
    super.key,
    required this.confessionId,
    required this.userId,
    required this.username,
    required this.timeAgo,
    required this.location,
    required this.confession,
    required this.upvotes,
    required this.comments,
    this.reactionCounts,
    this.isReact = false,
  });

  @override
  State<ConfessionCard> createState() => _ConfessionCardState();
}

class _ConfessionCardState extends State<ConfessionCard> {
  OverlayEntry? _overlayEntry;

  String? userReaction;
  Map<String, int> currentReactions = {};
  int commentsCount = 0; // New state variable for comments count

  @override
  void initState() {
    super.initState();
    currentReactions = Map<String, int>.from(widget.reactionCounts ?? {});
    commentsCount = widget.comments; // Initialize comments count

    if (widget.isReact) {
      currentReactions.forEach((emoji, count) {
        if (count > 0 && userReaction == null) {
          userReaction = emoji;
        }
      });
    }

    print(
      '🔰 initState: userReaction=$userReaction currentReactions=$currentReactions commentsCount=$commentsCount',
    );
  }

  Future<void> _submitReaction(String emoji) async {
    final url = Uri.parse(
      'https://whisper-2nhg.onrender.com/api/comment/react',
    );

    final body = {
      'commentId': widget.confessionId,
      'userId': widget.userId,
      'emoji': emoji,
    };

    print('📡 Submitting reaction to $url with body: $body');

    try {
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(body),
      );

      print('🔗 Response status: ${response.statusCode}');
      print('🔗 Response body: ${response.body}');

      if (response.statusCode == 200 || response.statusCode == 201) {
        setState(() {
          if (emoji == '') {
            // Removing reaction
            if (userReaction != null &&
                currentReactions.containsKey(userReaction!)) {
              currentReactions[userReaction!] =
                  currentReactions[userReaction!]! - 1;
              if (currentReactions[userReaction!] == 0) {
                currentReactions.remove(userReaction!);
              }
            }
            userReaction = null;
          } else {
            // Adding or changing reaction
            if (userReaction != null &&
                currentReactions.containsKey(userReaction!)) {
              currentReactions[userReaction!] =
                  currentReactions[userReaction!]! - 1;
              if (currentReactions[userReaction!] == 0) {
                currentReactions.remove(userReaction!);
              }
            }
            currentReactions.update(emoji, (v) => v + 1, ifAbsent: () => 1);
            userReaction = emoji;
          }
        });

        print('✅ Reaction updated successfully. userReaction=$userReaction');
      } else {
        print('❌ Failed to submit reaction: ${response.body}');
      }
    } catch (e) {
      print('❌ Error submitting reaction: $e');
    }
  }

  void _reactConfession(String emoji) async {
    _removeOverlay();

    if (userReaction == emoji) {
      await _submitReaction('');
    } else {
      await _submitReaction(emoji);
    }
  }

  void _likeConfession() async {
    print('👍 Like button tapped');

    if (userReaction == '👍') {
      await _submitReaction('');
    } else {
      await _submitReaction('👍');
    }
  }

  void _showReactionOverlay(BuildContext context) {
    final overlay = Overlay.of(context);
    RenderBox box = context.findRenderObject() as RenderBox;
    Offset position = box.localToGlobal(Offset.zero);

    _overlayEntry = OverlayEntry(
      builder: (context) => Positioned(
        top: position.dy + box.size.height - 90,
        left: position.dx + 16,
        right: 16,
        child: Material(
          color: Colors.transparent,
          child: Center(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(30),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black26,
                    blurRadius: 6,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: ['👍', '👏', '🤝', '❤️', '💡', '😂'].map((emoji) {
                  return GestureDetector(
                    onTap: () => _reactConfession(emoji),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 6),
                      child: Text(
                        emoji,
                        style: TextStyle(
                          fontSize: 24,
                          color: userReaction == emoji
                              ? Colors.blue
                              : Colors.black,
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
          ),
        ),
      ),
    );

    overlay.insert(_overlayEntry!);

    Future.delayed(const Duration(seconds: 3), () {
      _removeOverlay();
    });
  }

  void _removeOverlay() {
    _overlayEntry?.remove();
    _overlayEntry = null;
  }

  void _incrementCommentsCount() {
    setState(() {
      commentsCount += 1;
    });
  }

  @override
  Widget build(BuildContext context) {
    int totalReactions = currentReactions.isNotEmpty
        ? currentReactions.values.reduce((a, b) => a + b)
        : 0;

    List<String> reactionEmojis = currentReactions.entries
        .where((entry) => entry.value > 0)
        .map((entry) => entry.key)
        .toList();

    if (userReaction != null && !reactionEmojis.contains(userReaction)) {
      reactionEmojis.add(userReaction!);
    }

    bool showOnlyLike =
        (reactionEmojis.isEmpty && widget.upvotes > 0) ||
        (reactionEmojis.length == 1 && reactionEmojis.contains('👍'));

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.symmetric(vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(0),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 22,
                  backgroundImage: NetworkImage(
                    'https://i.pravatar.cc/150?u=${widget.username}',
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.username,
                        style: GoogleFonts.inter(fontWeight: FontWeight.w600),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '${widget.timeAgo} • ${widget.location}',
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ),
                const Icon(Icons.more_vert, color: Colors.grey),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Text(
              widget.confession,
              style: GoogleFonts.inter(fontSize: 14, color: Colors.black87),
            ),
          ),
          if (totalReactions > 0 || widget.upvotes > 0)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: [
                  if (!showOnlyLike && reactionEmojis.isNotEmpty)
                    Wrap(
                      spacing: -8,
                      children: reactionEmojis.map((emoji) {
                        bool isUserReacted = (userReaction == emoji);
                        return Container(
                          padding: const EdgeInsets.all(2),
                          decoration: const BoxDecoration(
                            color: Colors.white,
                            shape: BoxShape.circle,
                          ),
                          child: Text(
                            emoji,
                            style: TextStyle(
                              fontSize: 16,
                              color: isUserReacted ? Colors.blue : Colors.black,
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  if (showOnlyLike)
                    Icon(Icons.thumb_up_alt, size: 16, color: Colors.blue),
                  const SizedBox(width: 8),
                  Text(
                    '${widget.upvotes > 0 ? widget.upvotes : totalReactions}',
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      color: Colors.grey[800],
                    ),
                  ),
                  const Spacer(),
                  Text(
                    '$commentsCount comments', // use state variable
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
            ),
          const Divider(thickness: 0.4),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                GestureDetector(
                  onTap: _likeConfession,
                  onLongPress: () => _showReactionOverlay(context),
                  child: Row(
                    children: [
                      Icon(
                        userReaction == '👍'
                            ? Icons.thumb_up_alt
                            : Icons.thumb_up_alt_outlined,
                        size: 20,
                        color: userReaction == '👍'
                            ? Colors.blue
                            : Colors.grey[800],
                      ),
                      const SizedBox(width: 4),
                      Text(
                        'Like',
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          color: userReaction == '👍'
                              ? Colors.blue
                              : Colors.grey[800],
                        ),
                      ),
                    ],
                  ),
                ),
                InkWell(
                  onTap: () {
                    showCommentsModal(
                      context,
                      widget.confessionId,
                      onNewComment: _incrementCommentsCount, // Pass callback
                    );
                  },
                  child: _buildActionIcon(Icons.chat_bubble_outline, 'Comment'),
                ),
                _buildActionIcon(Icons.share_outlined, 'Share'),
                _buildActionIcon(Icons.send_outlined, 'Send'),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionIcon(IconData icon, String label) {
    return Row(
      children: [
        Icon(icon, size: 20, color: Colors.grey[800]),
        const SizedBox(width: 4),
        Text(
          label,
          style: GoogleFonts.inter(fontSize: 12, color: Colors.grey[800]),
        ),
      ],
    );
  }
}

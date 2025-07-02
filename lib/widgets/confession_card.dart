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
  });

  @override
  State<ConfessionCard> createState() => _ConfessionCardState();
}

class _ConfessionCardState extends State<ConfessionCard> {
  OverlayEntry? _overlayEntry;

  bool isLiked = false;
  String? userReaction; // stores user's selected emoji
  Map<String, int> currentReactions = {};

  @override
  void initState() {
    super.initState();
    currentReactions = Map<String, int>.from(widget.reactionCounts ?? {});
  }

  @override
  void dispose() {
    _submitReaction();
    super.dispose();
  }

  Future<void> _submitReaction() async {
    String? emoji;
    if (isLiked) emoji = '👍';
    if (userReaction != null) emoji = userReaction;

    if (emoji != null) {
      final url = Uri.parse(
        'https://whisper-2nhg.onrender.com/api/confessions/react',
      );
      final body = {
        'confessionId': widget.confessionId,
        'userId': widget.userId,
        'emoji': emoji,
      };
      try {
        final response = await http.post(
          url,
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode(body),
        );
        if (response.statusCode == 200) {
          print('Reaction submitted successfully');
        } else {
          print('Failed to submit reaction: ${response.body}');
        }
      } catch (e) {
        print('Error submitting reaction: $e');
      }
    }
  }

  void _likeConfession() async {
    _removeOverlay();

    setState(() {
      if (isLiked) {
        // Unlike
        String emoji = '👍';
        if (currentReactions.containsKey(emoji)) {
          currentReactions[emoji] = currentReactions[emoji]! - 1;
          if (currentReactions[emoji] == 0) currentReactions.remove(emoji);
        }
        isLiked = false;
      } else {
        // If already reacted, remove reaction
        if (userReaction != null) {
          if (currentReactions.containsKey(userReaction!)) {
            currentReactions[userReaction!] =
                currentReactions[userReaction!]! - 1;
            if (currentReactions[userReaction!] == 0)
              currentReactions.remove(userReaction!);
          }
          userReaction = null;
        }
        // Like
        String emoji = '👍';
        currentReactions.update(emoji, (value) => value + 1, ifAbsent: () => 1);
        isLiked = true;
      }
    });

    await _submitReaction();
  }

  void _reactConfession(String emoji) async {
    _removeOverlay();

    setState(() {
      if (userReaction == emoji) {
        // Un-react
        if (currentReactions.containsKey(emoji)) {
          currentReactions[emoji] = currentReactions[emoji]! - 1;
          if (currentReactions[emoji] == 0) currentReactions.remove(emoji);
        }
        userReaction = null;
      } else {
        // If already liked, unlike first
        if (isLiked) {
          String likeEmoji = '👍';
          if (currentReactions.containsKey(likeEmoji)) {
            currentReactions[likeEmoji] = currentReactions[likeEmoji]! - 1;
            if (currentReactions[likeEmoji] == 0)
              currentReactions.remove(likeEmoji);
          }
          isLiked = false;
        }
        // If had other reaction, remove it
        if (userReaction != null && userReaction != emoji) {
          if (currentReactions.containsKey(userReaction!)) {
            currentReactions[userReaction!] =
                currentReactions[userReaction!]! - 1;
            if (currentReactions[userReaction!] == 0)
              currentReactions.remove(userReaction!);
          }
        }
        // Add new reaction
        currentReactions.update(emoji, (value) => value + 1, ifAbsent: () => 1);
        userReaction = emoji;
      }
    });

    await _submitReaction();
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
                      child: Text(emoji, style: const TextStyle(fontSize: 24)),
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

    // Auto dismiss after 3 seconds
    Future.delayed(const Duration(seconds: 3), () {
      _removeOverlay();
    });
  }

  void _removeOverlay() {
    _overlayEntry?.remove();
    _overlayEntry = null;
  }

  void _openCommentModal() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) {
        return FractionallySizedBox(
          heightFactor: 0.9,
          child: Column(
            children: [
              const SizedBox(height: 12),
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey[400],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 12),
              Text(
                'Comments',
                style: GoogleFonts.inter(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
              Expanded(
                child: Center(
                  child: Text(
                    'Comments list goes here',
                    style: GoogleFonts.inter(),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    int totalReactions = currentReactions.isNotEmpty
        ? currentReactions.values.reduce((a, b) => a + b)
        : 0;
    List<String> reactionEmojis = currentReactions.keys.toList();

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
          // User info row
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

          // Confession text
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Text(
              widget.confession,
              style: GoogleFonts.inter(fontSize: 14, color: Colors.black87),
            ),
          ),

          // Reaction + Comment row
          if (currentReactions.isNotEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: [
                  Wrap(
                    spacing: -8,
                    children: reactionEmojis.map((emoji) {
                      return Container(
                        padding: const EdgeInsets.all(2),
                        decoration: const BoxDecoration(
                          color: Colors.white,
                          shape: BoxShape.circle,
                        ),
                        child: Text(
                          emoji,
                          style: const TextStyle(fontSize: 16),
                        ),
                      );
                    }).toList(),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    '$totalReactions',
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      color: Colors.grey[800],
                    ),
                  ),
                  const Spacer(),
                  Text(
                    '${widget.comments} comments',
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
            ),

          const Divider(thickness: 0.4),

          // Action bar
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
                        isLiked
                            ? Icons.thumb_up_alt
                            : Icons.thumb_up_alt_outlined,
                        size: 20,
                        color: isLiked ? Colors.blue : Colors.grey[800],
                      ),
                      const SizedBox(width: 4),
                      Text(
                        'Like',
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          color: isLiked ? Colors.blue : Colors.grey[800],
                        ),
                      ),
                    ],
                  ),
                ),
                GestureDetector(
                  onTap: () {
                    showCommentsModal(context);
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

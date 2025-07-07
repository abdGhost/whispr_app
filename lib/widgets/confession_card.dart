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

  final bool isNew;

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
    this.isNew = false,
  });

  @override
  State<ConfessionCard> createState() => _ConfessionCardState();
}

class _ConfessionCardState extends State<ConfessionCard> {
  OverlayEntry? _overlayEntry;

  String? userReaction;
  Map<String, int> currentReactions = {};
  int commentsCount = 0;

  @override
  void initState() {
    super.initState();
    currentReactions = Map<String, int>.from(widget.reactionCounts ?? {});
    commentsCount = widget.comments;

    if (widget.isReact) {
      currentReactions.forEach((emoji, count) {
        if (count > 0 && userReaction == null) {
          userReaction = emoji;
        }
      });
    }
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

    try {
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(body),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        setState(() {
          if (userReaction != null &&
              currentReactions.containsKey(userReaction!)) {
            currentReactions[userReaction!] =
                currentReactions[userReaction!]! - 1;
            if (currentReactions[userReaction!] == 0) {
              currentReactions.remove(userReaction!);
            }
          }

          if (emoji == '') {
            userReaction = null;
          } else {
            currentReactions.update(emoji, (v) => v + 1, ifAbsent: () => 1);
            userReaction = emoji;
          }
        });
      }
    } catch (e) {
      print('❌ Error submitting reaction: $e');
    }
  }

  void _reactConfession(String emoji) async {
    _removeOverlay();
    await _submitReaction(emoji);
  }

  void _likeConfession() async {
    if (userReaction == null) {
      await _submitReaction('👍');
    } else {
      await _submitReaction('');
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
    List<String> reactionEmojis = currentReactions.entries
        .where((entry) => entry.value > 0)
        .map((entry) => entry.key)
        .toList();

    if (userReaction != null && !reactionEmojis.contains(userReaction)) {
      reactionEmojis.add(userReaction!);
    }

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.symmetric(vertical: 4),
      decoration: BoxDecoration(
        color: widget.isNew
            ? Color(0xFF6C5CE7).withAlpha((255 * 0.5).toInt())
            : Colors.white,
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
          // Confession text
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Text(
              widget.confession,
              style: GoogleFonts.inter(fontSize: 14, color: Colors.black87),
            ),
          ),
          // Reactions and comments row
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                if (reactionEmojis.isNotEmpty)
                  Wrap(
                    spacing: 12,
                    children: reactionEmojis.map((emoji) {
                      int count = currentReactions[emoji] ?? 0;
                      return Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(emoji, style: const TextStyle(fontSize: 16)),
                          const SizedBox(width: 4),
                          Text(
                            '$count',
                            style: GoogleFonts.inter(
                              fontSize: 12,
                              color: Colors.grey[800],
                            ),
                          ),
                        ],
                      );
                    }).toList(),
                  )
                else
                  Text(
                    'No reactions yet',
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      color: Colors.grey[800],
                    ),
                  ),
                const Spacer(),
                Text(
                  '$commentsCount comments',
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
                InkWell(
                  onTap: _likeConfession,
                  onLongPress: () => _showReactionOverlay(context),
                  child: Row(
                    children: [
                      Icon(
                        userReaction != null
                            ? Icons.thumb_up_alt
                            : Icons.thumb_up_alt_outlined,
                        size: 20,
                        color: userReaction != null
                            ? Colors.blue
                            : Colors.grey[800],
                      ),
                      const SizedBox(width: 4),
                      Text(
                        'Like',
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          color: userReaction != null
                              ? Colors.blue
                              : Colors.grey[800],
                        ),
                      ),
                    ],
                  ),
                ),
                _buildActionIcon(Icons.chat_bubble_outline, 'Comment', () {
                  showCommentsModal(
                    context,
                    widget.confessionId,
                    onNewComment: _incrementCommentsCount,
                  );
                }),
                _buildActionIcon(Icons.share_outlined, 'Share', () {}),
                _buildActionIcon(Icons.send_outlined, 'Repost', () {}),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionIcon(
    IconData icon,
    String label,
    VoidCallback onTap, {
    VoidCallback? onLongPress,
    Color iconColor = const Color(0xFF424242),
    Color textColor = const Color(0xFF424242),
  }) {
    return InkWell(
      onTap: onTap,
      onLongPress: onLongPress,
      child: Row(
        children: [
          Icon(icon, size: 20, color: iconColor),
          const SizedBox(width: 4),
          Text(label, style: GoogleFonts.inter(fontSize: 12, color: textColor)),
        ],
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class ConfessionCard extends StatelessWidget {
  final String username;
  final String timeAgo;
  final String location;
  final String confession;
  final int upvotes;
  final int comments;
  final Map<String, int>? reactionCounts;

  const ConfessionCard({
    super.key,
    required this.username,
    required this.timeAgo,
    required this.location,
    required this.confession,
    required this.upvotes,
    required this.comments,
    this.reactionCounts,
  });

  @override
  Widget build(BuildContext context) {
    int totalReactions = 0;
    List<String> reactionEmojis = [];
    if (reactionCounts != null && reactionCounts!.isNotEmpty) {
      totalReactions = reactionCounts!.values.fold(0, (a, b) => a + b);
      reactionEmojis = reactionCounts!.keys.toList();
    }

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.symmetric(vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
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
                    'https://i.pravatar.cc/150?u=$username',
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        username,
                        style: GoogleFonts.inter(fontWeight: FontWeight.w600),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '$timeAgo • $location',
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
              confession,
              style: GoogleFonts.inter(fontSize: 14, color: Colors.black87),
            ),
          ),

          // Reaction + Comment row
          if (reactionCounts != null && reactionCounts!.isNotEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
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
                    '$comments comments',
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
            ),

          const Divider(thickness: 0.4, height: 20),

          // Action bar (Like, Comment, Share, Send)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _buildActionIcon(Icons.thumb_up_alt_outlined, 'Like'),
                _buildActionIcon(Icons.chat_bubble_outline, 'Comment'),
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
    return Column(
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
